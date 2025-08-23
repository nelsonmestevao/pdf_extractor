defmodule PdfExtractor.PdfPlumber do
  @moduledoc false

  def start do
    Pythonx.uv_init("""
    [project]
    name = "pdf_extractor"
    version = "#{to_string(version())}"
    requires-python = "==3.12.*"
    dependencies = [
      "pdfplumber==0.11.7"
    ]
    """)
  end

  @type area :: {non_neg_integer(), non_neg_integer(), non_neg_integer(), non_neg_integer()}
  @type page :: non_neg_integer()

  @spec extract_text(
          file_path :: String.t(),
          pages :: page() | list(page()) | %{page() => area() | [area()] | nil}
        ) :: %{page() => String.t() | list(String.t())}
  def extract_text(file_path, page_number) when is_integer(page_number) do
    extract_text(file_path, List.wrap(page_number))
  end

  def extract_text(file_path, pages) when is_list(pages) do
    """
    #{python_extract_code()}

    main(file_path.decode('utf-8'), page_numbers, areas)
    """
    |> Pythonx.eval(%{
      "file_path" => file_path,
      "page_numbers" => pages,
      "areas" => %{}
    })
    |> elem(0)
    |> Pythonx.decode()
    |> to_map(pages)
  end

  def extract_text(file_path, pages) when is_map(pages) do
    """
    #{python_extract_code()}

    main(file_path.decode('utf-8'), page_numbers, areas)
    """
    |> Pythonx.eval(%{
      "file_path" => file_path,
      "page_numbers" => Map.keys(pages),
      "areas" => pages
    })
    |> elem(0)
    |> Pythonx.decode()
    |> to_map(Map.keys(pages))
  end

  @doc """
    This version avoids the need to put the pdf on a filesystem.
    This allows this to work
    url = "https://erlang.org/download/armstrong_thesis_2003.pdf"
    url |> :httpc.request() |> elem(1) |> elem(2) |> :binary.list_to_bin() |> PdfExtractor.extract_text_from_binary()
  """
  def extract_text_from_binary(binary, page_number) when is_integer(page_number) do
    extract_text_from_binary(binary, List.wrap(page_number))
  end

  def extract_text_from_binary(binary, pages) when is_list(pages) do
    """
    from io import BytesIO

    #{python_extract_code()}

    main(BytesIO(binary), page_numbers, areas)
    """
    |> Pythonx.eval(%{
      "binary" => binary,
      "page_numbers" => pages,
      "areas" => %{}
    })
    |> elem(0)
    |> Pythonx.decode()
    |> to_map(pages)
  end

  def extract_text_from_binary(binary, pages) when is_map(pages) do
    """
    from io import BytesIO

    #{python_extract_code()}

    main(BytesIO(binary), page_numbers, areas)
    """
    |> Pythonx.eval(%{
      "binary" => binary,
      "page_numbers" => Map.keys(pages),
      "areas" => pages
    })
    |> elem(0)
    |> Pythonx.decode()
    |> to_map(Map.keys(pages))
  end

  defp python_extract_code do
    """
    import pdfplumber
    import logging

    logging.getLogger("pdfminer").setLevel(logging.ERROR)

    def extract_from_page(page, areas=None):
        if areas is None:
            return page.extract_text()
        elif isinstance(areas, list):
            return [page.within_bbox(area).extract_text() for area in areas]
        else:
            return page.within_bbox(areas).extract_text()

    def main(content, page_numbers, areas):
        results = []
        with pdfplumber.open(content) as pdf:
            total_pages = len(pdf.pages)
            if page_numbers == []:
              page_numbers = list(range(total_pages))
            for page_number in page_numbers:
              if page_number >= 0 and page_number < total_pages:
                results.append(extract_from_page(pdf.pages[page_number], areas.get(page_number)))
            return results
    """
  end

  def extract_metadata(file_path) do
    """
    #{python_extract_metadata_code()}

    main(file_path.decode('utf-8'))
    """
    |> Pythonx.eval(%{
      "file_path" => file_path
    })
    |> elem(0)
    |> Pythonx.decode()
  end

  def extract_metadata_from_binary(binary) do
    """
    from io import BytesIO

    #{python_extract_metadata_code()}

    main(BytesIO(binary))
    """
    |> Pythonx.eval(%{
      "binary" => binary
    })
    |> elem(0)
    |> Pythonx.decode()
  end

  defp python_extract_metadata_code do
    """
    import pdfplumber
    import logging

    logging.getLogger("pdfminer").setLevel(logging.ERROR)

    def main(content):
        with pdfplumber.open(content) as pdf:
          return pdf.metadata
    """
  end

  defp to_map(texts, []) when is_list(texts) do
    texts
    |> Enum.with_index(&{&2, &1})
    |> Map.new()
  end

  defp to_map(texts, page_numbers) when is_list(texts) do
    page_numbers
    |> Enum.zip(texts)
    |> Map.new()
  end

  defp version do
    Application.spec(:pdf_extractor, :vsn)
  end
end
