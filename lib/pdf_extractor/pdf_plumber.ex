defmodule PdfExtractor.PdfPlumber do
  @moduledoc false

  @python_extract_code """
  import pdfplumber
  import logging

  logging.getLogger("pdfminer").setLevel(logging.ERROR)

  def extract_text(page):
      return page.extract_text()

  def extract_words(page):
      return [
          (word["text"], float(word["x0"]), float(word["x1"]), float(word["top"]), float(word["bottom"]))
          for word in page.extract_words()
      ]

  def extract_from_page(page, areas, extract):
      if areas is None:
          return extract(page)
      elif isinstance(areas, list):
          return [extract(page.within_bbox(area)) for area in areas]
      else:
          return extract(page.within_bbox(areas))

  def main(content, page_numbers, areas, extract):
      results = {}
      with pdfplumber.open(content) as pdf:
          total_pages = len(pdf.pages)
          if page_numbers == []:
              page_numbers = list(range(total_pages))
          for page_number in page_numbers:
              if page_number >= 0 and page_number < total_pages:
                  results[page_number] = extract_from_page(pdf.pages[page_number], areas.get(page_number), extract)
      return results
  """

  @python_extract_metadata_code """
  import pdfplumber
  import logging

  logging.getLogger("pdfminer").setLevel(logging.ERROR)

  def main(content):
      with pdfplumber.open(content) as pdf:
        return pdf.metadata
  """

  def start do
    Pythonx.uv_init(
      """
      [project]
      name = "pdf_extractor"
      version = "#{to_string(version())}"
      requires-python = "==3.14.*"
      dependencies = [
        "pdfplumber==0.11.10"
      ]
      """,
      uv_version: "0.12.24"
    )
  end

  @type area :: {non_neg_integer(), non_neg_integer(), non_neg_integer(), non_neg_integer()}
  @type page :: non_neg_integer()
  @type pages :: page() | list(page()) | %{page() => area() | [area()] | nil}
  @type word :: %{text: String.t(), left: float(), right: float(), top: float(), bottom: float()}

  @spec extract_text(file_path :: String.t(), pages()) ::
          %{page() => String.t() | list(String.t())}
  def extract_text(file_path, pages) do
    {page_numbers, areas} = normalize_pages(pages)

    extract(
      "file_path.decode('utf-8')",
      %{"file_path" => file_path},
      page_numbers,
      areas,
      "extract_text"
    )
  end

  @doc """
    This version avoids the need to put the pdf on a filesystem.
    This allows this to work
    url = "https://erlang.org/download/armstrong_thesis_2003.pdf"
    url |> :httpc.request() |> elem(1) |> elem(2) |> :binary.list_to_bin() |> PdfExtractor.extract_text_from_binary()
  """
  @spec extract_text_from_binary(binary(), pages()) ::
          %{page() => String.t() | list(String.t())}
  def extract_text_from_binary(binary, pages) do
    {page_numbers, areas} = normalize_pages(pages)

    extract(
      "BytesIO(binary)",
      %{"binary" => binary},
      page_numbers,
      areas,
      "extract_text",
      "from io import BytesIO\n"
    )
  end

  @spec extract_words(file_path :: String.t(), pages()) ::
          %{page() => list(word()) | list(list(word()))}
  def extract_words(file_path, pages) do
    {page_numbers, areas} = normalize_pages(pages)

    "file_path.decode('utf-8')"
    |> extract(%{"file_path" => file_path}, page_numbers, areas, "extract_words")
    |> decode_words()
  end

  @spec extract_words_from_binary(binary(), pages()) ::
          %{page() => list(word()) | list(list(word()))}
  def extract_words_from_binary(binary, pages) do
    {page_numbers, areas} = normalize_pages(pages)

    "BytesIO(binary)"
    |> extract(
      %{"binary" => binary},
      page_numbers,
      areas,
      "extract_words",
      "from io import BytesIO\n"
    )
    |> decode_words()
  end

  defp normalize_pages(page_number) when is_integer(page_number), do: {[page_number], %{}}
  defp normalize_pages(pages) when is_list(pages), do: {pages, %{}}
  defp normalize_pages(pages) when is_map(pages), do: {Map.keys(pages), pages}

  defp extract(content_expr, bindings, page_numbers, areas, extractor, preamble \\ "") do
    """
    #{preamble}#{@python_extract_code}

    main(#{content_expr}, page_numbers, areas, #{extractor})
    """
    |> Pythonx.eval(Map.merge(bindings, %{"page_numbers" => page_numbers, "areas" => areas}))
    |> elem(0)
    |> Pythonx.decode()
  end

  # Words arrive as `{text, left, right, top, bottom}` tuples, either in a flat list for
  # a whole page or in a list of lists when several areas were requested.
  defp decode_words(by_page) do
    Map.new(by_page, fn {page_number, words} -> {page_number, decode_word(words)} end)
  end

  defp decode_word({text, left, right, top, bottom}) do
    %{text: text, left: left, right: right, top: top, bottom: bottom}
  end

  defp decode_word(words) when is_list(words), do: Enum.map(words, &decode_word/1)

  def extract_metadata(file_path) do
    """
    #{@python_extract_metadata_code}

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

    #{@python_extract_metadata_code}

    main(BytesIO(binary))
    """
    |> Pythonx.eval(%{
      "binary" => binary
    })
    |> elem(0)
    |> Pythonx.decode()
  end

  defp version do
    Application.spec(:pdf_extractor, :vsn)
  end
end
