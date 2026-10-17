defmodule PdfExtractor do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("\n\n")
             |> tl()
             |> tl()
             |> Enum.join("\n\n")
  use GenServer

  @external_resource "README.md"

  @default_timeout 5_000
  @table_strategies [:lines, :lines_strict, :text]
  @table_defaults [vertical_strategy: :lines, horizontal_strategy: :lines]

  # Client

  def start_link(opts \\ []) do
    opts = Keyword.validate!(opts, name: __MODULE__)
    GenServer.start_link(__MODULE__, [], name: opts[:name])
  end

  @doc ~S"""
  Extracts text from PDF pages.

  It supports extracting from single pages, multiple pages, and specific areas within pages.

  ## Page Numbers

  - **Integer**: Extract from single page (e.g., `0` for first page)
  - **List**: Extract from multiple pages (e.g., `[0, 1, 2]`)
  - **Empty list** `[]`: Extract from all pages (default)

  ## Areas Format

  Areas are specified as a map where keys are page numbers and values are bounding boxes:

  - **Single area**: `%{0 => {x0, y0, x1, y1}}`
  - **Multiple areas**: `%{0 => [{x0, y0, x1, y1}, {x2, y2, x3, y3}]}`
  - **Mixed**: `%{0 => {x0, y0, x1, y1}, 1 => [{x2, y2, x3, y3}, {x4, y4, x5, y5}]}`

  ## Options

  All extraction functions accept these options:

  - `:timeout` - timeout in milliseconds for the GenServer call (default: `#{@default_timeout}`)
  - `:name` - name or PID of the server to call (default: `PdfExtractor`)
  - `:password` - the password of an encrypted PDF. Without it, or with a wrong one, extraction
    returns an error (default: `nil`)

  `extract_text/3` and `extract_text_from_binary/3` also accept:

  - `:layout` - when `true`, keeps the position of the text on the page by padding it with spaces
    and blank lines, so columns stay aligned. Useful for statements and tables that the default
    extraction flattens into single lines (default: `false`)

  ## Examples

    Extract text from all pages.

      iex> PdfExtractor.extract_text("priv/fixtures/fatura.pdf")
      {:ok,
       %{
         0 =>
           "Text Example Bill FATURA\n# 2025010002\nData: Jun 21, 2025\nProjeto de lei para:\nSaldo devedor: 1 525,59 €\nElixir Company\nItem Quantidade Avaliar Quantia\nTrabalho 1 1 500,00 € 1 500,00 €\nMais trabalho 1 25,59 € 25,59 €\nSubtotal: 1 525,59 €\nImposto (0%): 0,00 €\nTotal: 1 525,59 €",
         1 =>
           "✂\nReceipt Payment part Account / Payable to\nCH4431999123000889012\n✂\nMax Muster & Söhne\nAccount / Payable to\nCH4431999123000889012 Musterstrasse 123\nMax Muster & Söhne 8000 Seldwyla\nMusterstrasse 123\n8000 Seldwyla\nReference\n210000000003139471430009017\nReference\n210000000003139471430009017\nAdditional information\nBestellung vom 15.10.2020\nPayable by (name/address)\nSimon Muster\nPayable by (name/address)\nMusterstrasse 1\nCurrency Amount\nSimon Muster\n8000 Seldwyla\nCHF 1 949.75 Musterstrasse 1\n8000 Seldwyla\nCurrency Amount\nCHF 1 949.75\nAcceptance point"
       }}

    Extract text from only some pages.

      iex> PdfExtractor.extract_text("priv/fixtures/fatura.pdf", [0])
      {:ok,
       %{
         0 =>
           "Text Example Bill FATURA\n# 2025010002\nData: Jun 21, 2025\nProjeto de lei para:\nSaldo devedor: 1 525,59 €\nElixir Company\nItem Quantidade Avaliar Quantia\nTrabalho 1 1 500,00 € 1 500,00 €\nMais trabalho 1 25,59 € 25,59 €\nSubtotal: 1 525,59 €\nImposto (0%): 0,00 €\nTotal: 1 525,59 €"
       }}

    Extract only the titles in the book.

      iex> PdfExtractor.extract_text("priv/fixtures/frankenstein-mary-shelley.pdf", %{
      ...>   1 => {0, 0, 612, 190},
      ...>   2 => {0, 0, 612, 190},
      ...>   8 => {0, 0, 612, 190},
      ...>   12 => {0, 0, 612, 190},
      ...>   13 => {0, 0, 612, 190}
      ...> })
      {:ok,
       %{
         1 => "Frankenstein",
         2 => "Introduction",
         8 => "Preface",
         12 => "Frankenstein",
         13 => "Letter I"
       }}

    Extract multiple areas from a single page.

      iex> PdfExtractor.extract_text("priv/fixtures/frankenstein-mary-shelley.pdf", %{
      ...>   13 => [{0, 200, 600, 300}, {0, 400, 612, 440}]
      ...> })
      {:ok,
       %{
         13 => [
           "To Mrs. Saville, England.\nSt. Petersburgh, Dec. 11th, 17 —.",
           "I am already far north of London; and as I walk in the streets of\nPetersburgh, I feel a cold northern breeze play upon my cheeks, which"
         ]
       }}

    Extract with a custom timeout for large files.

      iex> PdfExtractor.extract_text("priv/fixtures/frankenstein-mary-shelley.pdf", 11,
      ...>   timeout: 30_000
      ...> )
      {:ok,
       %{
         11 =>
           "“Did I request thee, Maker, from my clay\nTo mould me Man, did I solicit thee\nFrom darkness to promote me?”\nP L , X, 743 – 45\nARADISE OST"
       }}

    Open an encrypted file with its password.

      iex> PdfExtractor.extract_text("priv/fixtures/fatura-encrypted.pdf", %{0 => {0, 0, 300, 200}},
      ...>   password: "secret"
      ...> )
      {:ok, %{0 => "Text Example Bill\nProjeto de lei para:\nElixir Company"}}

    Keep the layout of the page so the columns of a table stay aligned.

      iex> PdfExtractor.extract_text("priv/fixtures/fatura.pdf", %{0 => {0, 220, 595, 250}})
      {:ok, %{0 => "Trabalho 1 1 500,00 € 1 500,00 €\nMais trabalho 1 25,59 € 25,59 €"}}

      iex> PdfExtractor.extract_text("priv/fixtures/fatura.pdf", %{0 => {0, 220, 595, 250}},
      ...>   layout: true
      ...> )
      {:ok,
       %{
         0 =>
           "      Trabalho                                     1          1 500,00 € 1 500,00 €\n      Mais trabalho                                1            25,59 €   25,59 € "
       }}

  """
  def extract_text(file_path, pages \\ [], opts \\ []) do
    %{timeout: timeout, name: name, layout: layout, password: password} =
      validate_opts!(opts, layout: false)

    GenServer.call(
      name,
      {:extract_text, [file_path, pages, %{layout: layout, password: password}]},
      timeout
    )
  end

  @doc ~S"""
  Extracts text from PDF binary data. See `extract_text/2` for details on how to specify pages, areas, and options.

  This function allows you to extract text from PDF data that's already in memory,
  such as data downloaded from a URL or received via an API. This avoids the need
  to write the PDF to the filesystem.

  ## Examples

    Extract text from all pages.

      iex> content = File.read!("priv/fixtures/fatura.pdf")
      ...> PdfExtractor.extract_text_from_binary(content)
      {:ok,
       %{
         0 =>
           "Text Example Bill FATURA\n# 2025010002\nData: Jun 21, 2025\nProjeto de lei para:\nSaldo devedor: 1 525,59 €\nElixir Company\nItem Quantidade Avaliar Quantia\nTrabalho 1 1 500,00 € 1 500,00 €\nMais trabalho 1 25,59 € 25,59 €\nSubtotal: 1 525,59 €\nImposto (0%): 0,00 €\nTotal: 1 525,59 €",
         1 =>
           "✂\nReceipt Payment part Account / Payable to\nCH4431999123000889012\n✂\nMax Muster & Söhne\nAccount / Payable to\nCH4431999123000889012 Musterstrasse 123\nMax Muster & Söhne 8000 Seldwyla\nMusterstrasse 123\n8000 Seldwyla\nReference\n210000000003139471430009017\nReference\n210000000003139471430009017\nAdditional information\nBestellung vom 15.10.2020\nPayable by (name/address)\nSimon Muster\nPayable by (name/address)\nMusterstrasse 1\nCurrency Amount\nSimon Muster\n8000 Seldwyla\nCHF 1 949.75 Musterstrasse 1\n8000 Seldwyla\nCurrency Amount\nCHF 1 949.75\nAcceptance point"
       }}

    Extract text from only some pages.

      iex> content = File.read!("priv/fixtures/fatura.pdf")
      ...> PdfExtractor.extract_text_from_binary(content, [0])
      {:ok,
       %{
         0 =>
           "Text Example Bill FATURA\n# 2025010002\nData: Jun 21, 2025\nProjeto de lei para:\nSaldo devedor: 1 525,59 €\nElixir Company\nItem Quantidade Avaliar Quantia\nTrabalho 1 1 500,00 € 1 500,00 €\nMais trabalho 1 25,59 € 25,59 €\nSubtotal: 1 525,59 €\nImposto (0%): 0,00 €\nTotal: 1 525,59 €"
       }}

    Extract only the titles in the book.

      iex> content = File.read!("priv/fixtures/frankenstein-mary-shelley.pdf")
      ...>
      ...> PdfExtractor.extract_text_from_binary(content, %{
      ...>   1 => {0, 0, 612, 190},
      ...>   2 => {0, 0, 612, 190},
      ...>   8 => {0, 0, 612, 190},
      ...>   12 => {0, 0, 612, 190},
      ...>   13 => {0, 0, 612, 190}
      ...> })
      {:ok,
       %{
         1 => "Frankenstein",
         2 => "Introduction",
         8 => "Preface",
         12 => "Frankenstein",
         13 => "Letter I"
       }}

    Extract multiple areas from a single page.

      iex> content = File.read!("priv/fixtures/frankenstein-mary-shelley.pdf")
      ...>
      ...> PdfExtractor.extract_text_from_binary(content, %{
      ...>   13 => [{0, 200, 600, 300}, {0, 400, 612, 440}]
      ...> })
      {:ok,
       %{
         13 => [
           "To Mrs. Saville, England.\nSt. Petersburgh, Dec. 11th, 17 —.",
           "I am already far north of London; and as I walk in the streets of\nPetersburgh, I feel a cold northern breeze play upon my cheeks, which"
         ]
       }}

  """
  def extract_text_from_binary(binary, pages \\ [], opts \\ []) do
    %{timeout: timeout, name: name, layout: layout, password: password} =
      validate_opts!(opts, layout: false)

    GenServer.call(
      name,
      {:extract_text_from_binary, [binary, pages, %{layout: layout, password: password}]},
      timeout
    )
  end

  @doc """
  Extracts words from PDF pages together with their position on the page.

  Each word is a map with its `:text` and the edges of its bounding box, `:left`, `:right`, `:top` and
  `:bottom`, in PDF points measured from the top left corner of the page. Words come in the order
  `pdfplumber` reads them, which is the same order `extract_text/3` uses to build its text.

  See `extract_text/3` for details on how to specify pages, areas, and options.

  ## Options

  Besides `:timeout`, `:name` and `:password`, this function accepts:

  - `:font` - when `true`, adds the `:font_name` and `:font_size` of each word. The subset tag that
    PDFs prepend to the names of embedded fonts, such as `ABCDEF+`, is removed. A word written in
    more than one font is split where the font changes (default: `false`)

  ## Examples

    Extract the words of a single page.

      iex> {:ok, %{0 => words}} = PdfExtractor.extract_words("priv/fixtures/fatura.pdf", 0)
      ...> Enum.take(words, 3)
      [
        %{
          text: "Text",
          left: 48.0,
          right: 67.99875,
          top: 26.64224999999999,
          bottom: 36.39224999999999
        },
        %{
          text: "Example",
          left: 70.734375,
          right: 110.757,
          top: 26.64224999999999,
          bottom: 36.39224999999999
        },
        %{
          text: "Bill",
          left: 113.49609375,
          right: 128.63240625,
          top: 26.64224999999999,
          bottom: 36.39224999999999
        }
      ]

    Extract only the words inside an area.

      iex> PdfExtractor.extract_words("priv/fixtures/frankenstein-mary-shelley.pdf", %{
      ...>   1 => {0, 0, 612, 190}
      ...> })
      {:ok,
       %{
         1 => [
           %{
             text: "Frankenstein",
             left: 76.99218429199217,
             right: 177.95707306012164,
             top: 102.2249957406251,
             bottom: 132.22499449062502
           }
         ]
       }}

    Get the font of each word to tell headings from body text.

      iex> PdfExtractor.extract_words(
      ...>   "priv/fixtures/frankenstein-mary-shelley.pdf",
      ...>   %{
      ...>     1 => {0, 0, 612, 190}
      ...>   }, font: true)
      {:ok,
       %{
         1 => [
           %{
             text: "Frankenstein",
             left: 76.99218429199217,
             right: 177.95707306012164,
             top: 102.2249957406251,
             bottom: 132.22499449062502,
             font_name: "LeagueGothic-Regular",
             font_size: 29.999998749999918
           }
         ]
       }}

  """
  def extract_words(file_path, pages \\ [], opts \\ []) do
    %{timeout: timeout, name: name, password: password, font: font} =
      validate_opts!(opts, font: false)

    GenServer.call(
      name,
      {:extract_words, [file_path, pages, %{password: password, font: font}]},
      timeout
    )
  end

  @doc """
  Extracts words from PDF binary data. See `extract_words/3` for the shape of each word and `extract_text/3`
  for details on how to specify pages, areas, and options.

  ## Examples

    Extract only the words inside an area.

      iex> content = File.read!("priv/fixtures/frankenstein-mary-shelley.pdf")
      ...> PdfExtractor.extract_words_from_binary(content, %{1 => {0, 0, 612, 190}})
      {:ok,
       %{
         1 => [
           %{
             text: "Frankenstein",
             left: 76.99218429199217,
             right: 177.95707306012164,
             top: 102.2249957406251,
             bottom: 132.22499449062502
           }
         ]
       }}

  """
  def extract_words_from_binary(binary, pages \\ [], opts \\ []) do
    %{timeout: timeout, name: name, password: password, font: font} =
      validate_opts!(opts, font: false)

    GenServer.call(
      name,
      {:extract_words_from_binary, [binary, pages, %{password: password, font: font}]},
      timeout
    )
  end

  @doc """
  Extracts tables from PDF pages together with their position on the page.

  Each page maps to the list of tables found on it. A table is a map with its `:rows`, each one a
  list of cells read left to right, and the edges of its bounding box, `:left`, `:right`, `:top` and
  `:bottom`, in PDF points measured from the top left corner of the page. A cell is `nil` when the
  table has a cell there but no text could be assigned to it. The bounding box can be used as an area
  with the other functions, for example to read the text right below a table.

  See `extract_text/3` for details on how to specify pages, areas, and options.

  ## Options

  Besides `:timeout`, `:name` and `:password`, this function accepts how the edges of the tables
  are found:

  - `:vertical_strategy` - how to find the columns (default: `:lines`)
  - `:horizontal_strategy` - how to find the rows (default: `:lines`)

  Each strategy is one of:

  - `:lines` - use the lines drawn on the page, including the sides of rectangles, as cell borders
  - `:lines_strict` - like `:lines` but ignore the sides of rectangles
  - `:text` - infer the borders from the alignment of the words, for tables drawn without lines

  ## Examples

    Extract the tables of every page.

      iex> PdfExtractor.extract_tables("priv/fixtures/fatura.pdf")
      {:ok,
       %{
         0 => [
           %{
             rows: [["Item", "Quantidade", "Avaliar", "Quantia"]],
             left: 29.25,
             top: 190.5,
             right: 582.75,
             bottom: 211.5
           }
         ],
         1 => []
       }}

    Extract only the tables inside an area.

      iex> PdfExtractor.extract_tables("priv/fixtures/fatura.pdf", %{0 => {0, 180, 595, 260}})
      {:ok,
       %{
         0 => [
           %{
             rows: [["Item", "Quantidade", "Avaliar", "Quantia"]],
             left: 29.25,
             top: 190.5,
             right: 582.75,
             bottom: 211.5
           }
         ]
       }}

    Find the columns from the alignment of the words instead of the drawn lines.

      iex> PdfExtractor.extract_tables("priv/fixtures/fatura.pdf", 0,
      ...>   vertical_strategy: :text,
      ...>   horizontal_strategy: :lines
      ...> )
      {:ok,
       %{
         0 => [
           %{
             rows: [
               [nil, nil, "devedor:", "", "1 52", "5,59 €"],
               [nil, nil, "", "", "", ""],
               ["I", "tem Quantidad", "e", "Avaliar", "", "Quantia"]
             ],
             left: 44.25,
             top: 126.75,
             right: 568.0695,
             bottom: 211.5
           }
         ]
       }}

  """
  def extract_tables(file_path, pages \\ [], opts \\ []) do
    %{timeout: timeout, name: name} = opts = validate_opts!(opts, @table_defaults)
    options = Map.take(opts, [:vertical_strategy, :horizontal_strategy, :password])
    GenServer.call(name, {:extract_tables, [file_path, pages, options]}, timeout)
  end

  @doc """
  Extracts tables from PDF binary data. See `extract_tables/3` for the shape of each table and its
  options, and `extract_text/3` for details on how to specify pages and areas.

  ## Examples

      iex> content = File.read!("priv/fixtures/fatura.pdf")
      ...> PdfExtractor.extract_tables_from_binary(content, 0)
      {:ok,
       %{
         0 => [
           %{
             rows: [["Item", "Quantidade", "Avaliar", "Quantia"]],
             left: 29.25,
             top: 190.5,
             right: 582.75,
             bottom: 211.5
           }
         ]
       }}

  """
  def extract_tables_from_binary(binary, pages \\ [], opts \\ []) do
    %{timeout: timeout, name: name} = opts = validate_opts!(opts, @table_defaults)
    options = Map.take(opts, [:vertical_strategy, :horizontal_strategy, :password])
    GenServer.call(name, {:extract_tables_from_binary, [binary, pages, options]}, timeout)
  end

  @doc """
  Extracts the size and rotation of PDF pages.

  Each page maps to its `:width` and `:height` in PDF points and its `:rotation` in degrees, one of
  `0`, `90`, `180` or `270`. The sizes are the frame used by the areas of the other functions, so read
  them before choosing a bounding box. When all pages are requested, the size of the map is the
  number of pages of the document.

  Pages are an integer or a list of page numbers as in `extract_text/3`. Areas do not apply here.
  Accepts the `:timeout`, `:name` and `:password` options.

  ## Examples

    Get the size of every page.

      iex> PdfExtractor.extract_page_info("priv/fixtures/fatura.pdf")
      {:ok,
       %{
         0 => %{width: 612.0, height: 792.0, rotation: 0},
         1 => %{width: 595.2756, height: 841.8898, rotation: 0}
       }}

    Count the pages of a document.

      iex> {:ok, pages} =
      ...>   PdfExtractor.extract_page_info("priv/fixtures/frankenstein-mary-shelley.pdf")
      ...>
      ...> map_size(pages)
      17

  """
  def extract_page_info(file_path, pages \\ [], opts \\ []) do
    %{timeout: timeout, name: name, password: password} = validate_opts!(opts)
    GenServer.call(name, {:extract_page_info, [file_path, pages, %{password: password}]}, timeout)
  end

  @doc """
  Extracts the size and rotation of pages from PDF binary data. See `extract_page_info/3` for details.

  ## Examples

      iex> content = File.read!("priv/fixtures/fatura.pdf")
      ...> PdfExtractor.extract_page_info_from_binary(content, 1)
      {:ok, %{1 => %{width: 595.2756, height: 841.8898, rotation: 0}}}

  """
  def extract_page_info_from_binary(binary, pages \\ [], opts \\ []) do
    %{timeout: timeout, name: name, password: password} = validate_opts!(opts)

    GenServer.call(
      name,
      {:extract_page_info_from_binary, [binary, pages, %{password: password}]},
      timeout
    )
  end

  @doc """
  Extracts metadata from a PDF file info trailers. Typically includes "CreationDate", "ModDate", "Producer", et cetera.

  ## Examples

      iex> PdfExtractor.extract_metadata("priv/fixtures/frankenstein-mary-shelley.pdf")
      {:ok, %{"CreationDate" => "D:20260403141150", "Creator" => "PDFium", "Producer" => "PDFium"}}

  """
  def extract_metadata(file_path, opts \\ []) do
    %{timeout: timeout, name: name, password: password} = validate_opts!(opts)
    GenServer.call(name, {:extract_metadata, [file_path, %{password: password}]}, timeout)
  end

  @doc """
  Extracts metadata from PDF binary data. Similar to `extract_metadata/1` but works with PDF data in memory instead of
  files.

  ## Examples

      iex> content = File.read!("priv/fixtures/frankenstein-mary-shelley.pdf")
      ...> PdfExtractor.extract_metadata_from_binary(content)
      {:ok, %{"CreationDate" => "D:20260403141150", "Creator" => "PDFium", "Producer" => "PDFium"}}

  """
  def extract_metadata_from_binary(binary, opts \\ []) do
    %{timeout: timeout, name: name, password: password} = validate_opts!(opts)

    GenServer.call(
      name,
      {:extract_metadata_from_binary, [binary, %{password: password}]},
      timeout
    )
  end

  defp validate_opts!(opts, extra_defaults \\ []) do
    opts =
      Keyword.validate!(
        opts,
        [timeout: @default_timeout, name: __MODULE__, password: nil] ++ extra_defaults
      )

    Enum.each(opts, &validate_opt!/1)
    Map.new(opts)
  end

  defp validate_opt!({:password, password}) when is_binary(password) or is_nil(password), do: :ok

  defp validate_opt!({:password, password}) do
    raise ArgumentError, "expected :password to be a string or nil, got: #{inspect(password)}"
  end

  defp validate_opt!({:font, font}) when is_boolean(font), do: :ok

  defp validate_opt!({:font, font}) do
    raise ArgumentError, "expected :font to be a boolean, got: #{inspect(font)}"
  end

  defp validate_opt!({:layout, layout}) when is_boolean(layout), do: :ok

  defp validate_opt!({:layout, layout}) do
    raise ArgumentError, "expected :layout to be a boolean, got: #{inspect(layout)}"
  end

  defp validate_opt!({key, strategy})
       when key in [:vertical_strategy, :horizontal_strategy] and strategy in @table_strategies, do: :ok

  defp validate_opt!({key, strategy}) when key in [:vertical_strategy, :horizontal_strategy] do
    raise ArgumentError,
          "expected #{inspect(key)} to be one of #{inspect(@table_strategies)}, got: #{inspect(strategy)}"
  end

  defp validate_opt!(_other), do: :ok

  # Server

  @doc false
  @impl true
  def init([] = state) do
    try do
      :ok = PdfExtractor.PdfPlumber.start()
    rescue
      e in RuntimeError ->
        if e.message =~ ~r/Python interpreter has already been initialized/ do
          :ok
        else
          reraise e, __STACKTRACE__
        end
    end

    {:ok, state}
  end

  @doc false
  @impl true
  def handle_call({function, args}, _from, state) when is_atom(function) and is_list(args) do
    {:reply, {:ok, apply(PdfExtractor.PdfPlumber, function, args)}, state}
  rescue
    exception -> {:reply, {:error, exception}, state}
  end
end
