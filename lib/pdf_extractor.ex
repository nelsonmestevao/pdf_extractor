defmodule PdfExtractor do
  @moduledoc File.read!("README.md") |> String.split("\n\n") |> tl() |> tl() |> Enum.join("\n\n")

  @doc """
  Starts the PdfExtractor application and initializes the Python environment.
  """
  defdelegate start(type \\ :normal, args \\ []),
    to: PdfExtractor.PdfPlumber

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

  ## Examples

    Extract text from all pages.

      iex> PdfExtractor.extract_text("priv/fixtures/fatura.pdf")
      %{
        0 => "Text Example Bill FATURA\n# 2025010002\nData: Jun 21, 2025\nProjeto de lei para:\nSaldo devedor: 1 525,59 €\nElixir Company\nItem Quantidade Avaliar Quantia\nTrabalho 1 1 500,00 € 1 500,00 €\nMais trabalho 1 25,59 € 25,59 €\nSubtotal: 1 525,59 €\nImposto (0%): 0,00 €\nTotal: 1 525,59 €", 
        1 => "✂\nReceipt Payment part Account / Payable to\nCH4431999123000889012\n✂\nMax Muster & Söhne\nAccount / Payable to\nCH4431999123000889012 Musterstrasse 123\nMax Muster & Söhne 8000 Seldwyla\nMusterstrasse 123\n8000 Seldwyla\nReference\n210000000003139471430009017\nReference\n210000000003139471430009017\nAdditional information\nBestellung vom 15.10.2020\nPayable by (name/address)\nSimon Muster\nPayable by (name/address)\nMusterstrasse 1\nCurrency Amount\nSimon Muster\n8000 Seldwyla\nCHF 1 949.75 Musterstrasse 1\n8000 Seldwyla\nCurrency Amount\nCHF 1 949.75\nAcceptance point"
      }

    Extract only the titles in the book chapters.

      iex> PdfExtractor.extract_text("priv/fixtures/book.pdf", [2, 8, 10], %{
      ...>   2 => {0, 0, 612, 190},
      ...>   8 => {0, 0, 612, 190},
      ...>   10 => {0, 0, 612, 190}
      ...> })
      %{
        2 => "Introdução – Nota do tradutor",
        8 => "I. Sobre aproveitar o tempo", 
       10 => "II. Sobre a falta de foco na Leitura"
      }

    Extract multiple areas from a single page.

      iex> PdfExtractor.extract_text("priv/fixtures/book.pdf", 1, %{
      ...>   1 => [{0, 100, 612, 140}, {0, 400, 612, 440}]
      ...> })
      %{1 => ["CARTAS DE UM ESTOICO, Volume I", "Montecristo Editora Ltda.\ne-mail: editora@montecristoeditora.com.br"]}
  """
  defdelegate extract_text(file_path, page_numbers \\ [], areas \\ %{}),
    to: PdfExtractor.PdfPlumber

  @doc ~S"""
  Extracts text from PDF binary data. See `extract_text/3` for details on how to specify pages and areas.

  This function allows you to extract text from PDF data that's already in memory,
  such as data downloaded from a URL or received via an API. This avoids the need
  to write the PDF to the filesystem.

  ## Examples

    Extract text from all pages.

      iex> content = File.read!("priv/fixtures/fatura.pdf")
      iex> PdfExtractor.extract_text_from_binary(content)
      %{
        0 => "Text Example Bill FATURA\n# 2025010002\nData: Jun 21, 2025\nProjeto de lei para:\nSaldo devedor: 1 525,59 €\nElixir Company\nItem Quantidade Avaliar Quantia\nTrabalho 1 1 500,00 € 1 500,00 €\nMais trabalho 1 25,59 € 25,59 €\nSubtotal: 1 525,59 €\nImposto (0%): 0,00 €\nTotal: 1 525,59 €", 
        1 => "✂\nReceipt Payment part Account / Payable to\nCH4431999123000889012\n✂\nMax Muster & Söhne\nAccount / Payable to\nCH4431999123000889012 Musterstrasse 123\nMax Muster & Söhne 8000 Seldwyla\nMusterstrasse 123\n8000 Seldwyla\nReference\n210000000003139471430009017\nReference\n210000000003139471430009017\nAdditional information\nBestellung vom 15.10.2020\nPayable by (name/address)\nSimon Muster\nPayable by (name/address)\nMusterstrasse 1\nCurrency Amount\nSimon Muster\n8000 Seldwyla\nCHF 1 949.75 Musterstrasse 1\n8000 Seldwyla\nCurrency Amount\nCHF 1 949.75\nAcceptance point"
      }

    Extract only the titles in the book chapters.

      iex> content = File.read!("priv/fixtures/book.pdf")
      iex> PdfExtractor.extract_text_from_binary(content, [2, 8, 10], %{
      ...>   2 => {0, 0, 612, 190},
      ...>   8 => {0, 0, 612, 190},
      ...>   10 => {0, 0, 612, 190}
      ...> })
      %{
        2 => "Introdução – Nota do tradutor",
        8 => "I. Sobre aproveitar o tempo", 
       10 => "II. Sobre a falta de foco na Leitura"
      }

    Extract multiple areas from a single page.

      iex> content = File.read!("priv/fixtures/book.pdf")
      iex> PdfExtractor.extract_text_from_binary(content, 1, %{
      ...>   1 => [{0, 100, 612, 140}, {0, 400, 612, 440}]
      ...> })
      %{
        1 => ["CARTAS DE UM ESTOICO, Volume I", "Montecristo Editora Ltda.\ne-mail: editora@montecristoeditora.com.br"]
       }

  """
  defdelegate extract_text_from_binary(binary, page_numbers \\ [], areas \\ %{}),
    to: PdfExtractor.PdfPlumber

  @doc """
  Extracts metadata from a PDF file info trailers. Typically includes "CreationDate", "ModDate", "Producer", et cetera.

  ## Examples

      iex> PdfExtractor.extract_metadata("priv/fixtures/book.pdf")
      %{
          "CreationDate" => "D:20250718212328Z",
          "Creator" => "Stirling-PDF v0.44.2",
          "ModDate" => "D:20250718212328Z",
          "Producer" => "Stirling-PDF v0.44.2"
      }

  """
  defdelegate extract_metadata(file_path),
    to: PdfExtractor.PdfPlumber

  @doc """
  Extracts metadata from PDF binary data. Similar to `extract_metadata/1` but works with PDF data in memory instead of
  files.

  ## Examples

      iex> content = File.read!("priv/fixtures/book.pdf")
      iex> PdfExtractor.extract_metadata_from_binary(content)
      %{
          "CreationDate" => "D:20250718212328Z",
          "Creator" => "Stirling-PDF v0.44.2",
          "ModDate" => "D:20250718212328Z",
          "Producer" => "Stirling-PDF v0.44.2"
      }

  """
  defdelegate extract_metadata_from_binary(binary),
    to: PdfExtractor.PdfPlumber
end
