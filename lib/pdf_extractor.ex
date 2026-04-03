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

  All extraction functions accept the same options:

  - `:timeout` - timeout in milliseconds for the GenServer call (default: `#{@default_timeout}`)

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

  """
  def extract_text(file_path, pages \\ [], opts \\ []) do
    %{timeout: timeout} = validate_opts!(opts)
    GenServer.call(__MODULE__, {:extract_text, [file_path, pages]}, timeout)
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
    %{timeout: timeout} = validate_opts!(opts)
    GenServer.call(__MODULE__, {:extract_text_from_binary, [binary, pages]}, timeout)
  end

  @doc """
  Extracts metadata from a PDF file info trailers. Typically includes "CreationDate", "ModDate", "Producer", et cetera.

  ## Examples

      iex> PdfExtractor.extract_metadata("priv/fixtures/frankenstein-mary-shelley.pdf")
      {:ok, %{"CreationDate" => "D:20260403141150", "Creator" => "PDFium", "Producer" => "PDFium"}}

  """
  def extract_metadata(file_path, opts \\ []) do
    %{timeout: timeout} = validate_opts!(opts)
    GenServer.call(__MODULE__, {:extract_metadata, [file_path]}, timeout)
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
    %{timeout: timeout} = validate_opts!(opts)
    GenServer.call(__MODULE__, {:extract_metadata_from_binary, [binary]}, timeout)
  end

  defp validate_opts!(opts) do
    opts
    |> Keyword.validate!(timeout: @default_timeout)
    |> Map.new()
  end

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
    exception in Pythonx.Error -> {:reply, {:error, exception}, state}
  end
end
