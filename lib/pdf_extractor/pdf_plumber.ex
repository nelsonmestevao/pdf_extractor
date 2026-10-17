defmodule PdfExtractor.PdfPlumber do
  @moduledoc false

  # Shared by every Python snippet. Pythonx hands binaries to Python as bytes,
  # so the password is decoded before reaching pdfplumber, which expects a str.
  @python_prelude """
  import pdfplumber
  import logging

  logging.getLogger("pdfminer").setLevel(logging.ERROR)

  def open_pdf(content, options):
      password = options.get("password")
      if password is not None:
          password = password.decode("utf-8")
      return pdfplumber.open(content, password=password)

  """

  @python_extract_code """
  def extract_text(page, options):
      return page.extract_text(layout=options["layout"])

  def extract_words(page, options):
      return [
          (word["text"], float(word["x0"]), float(word["x1"]), float(word["top"]), float(word["bottom"]))
          for word in page.extract_words()
      ]

  def extract_tables(page, options):
      settings = {
          "vertical_strategy": options["vertical_strategy"],
          "horizontal_strategy": options["horizontal_strategy"],
      }
      return [
          (table.extract(), float(table.bbox[0]), float(table.bbox[1]), float(table.bbox[2]), float(table.bbox[3]))
          for table in page.find_tables(settings)
      ]

  def extract_page_info(page, options):
      return (float(page.width), float(page.height), page.rotation)

  def extract_from_page(page, areas, extract, options):
      if areas is None:
          return extract(page, options)
      elif isinstance(areas, list):
          return [extract(page.within_bbox(area), options) for area in areas]
      else:
          return extract(page.within_bbox(areas), options)

  def main(content, page_numbers, areas, extract, options):
      results = {}
      with open_pdf(content, options) as pdf:
          total_pages = len(pdf.pages)
          if page_numbers == []:
              page_numbers = list(range(total_pages))
          for page_number in page_numbers:
              if page_number >= 0 and page_number < total_pages:
                  page = pdf.pages[page_number]
                  results[page_number] = extract_from_page(page, areas.get(page_number), extract, options)
      return results
  """

  @python_extract_metadata_code """
  def main(content, options):
      with open_pdf(content, options) as pdf:
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
  @type options :: %{password: String.t() | nil}
  @type page_info :: %{width: float(), height: float(), rotation: 0 | 90 | 180 | 270}
  @type text_options :: %{layout: boolean(), password: String.t() | nil}
  @type table_strategy :: :lines | :lines_strict | :text
  @type table_options :: %{
          vertical_strategy: table_strategy(),
          horizontal_strategy: table_strategy(),
          password: String.t() | nil
        }
  @type table :: %{
          rows: list(list(String.t() | nil)),
          left: float(),
          right: float(),
          top: float(),
          bottom: float()
        }

  @spec extract_text(file_path :: String.t(), pages(), text_options()) ::
          %{page() => String.t() | list(String.t())}
  def extract_text(file_path, pages, options) do
    {page_numbers, areas} = normalize_pages(pages)

    extract(
      "file_path.decode('utf-8')",
      %{"file_path" => file_path},
      page_numbers,
      areas,
      "extract_text",
      options
    )
  end

  @doc """
    This version avoids the need to put the pdf on a filesystem.
    This allows this to work
    url = "https://erlang.org/download/armstrong_thesis_2003.pdf"
    url |> :httpc.request() |> elem(1) |> elem(2) |> :binary.list_to_bin() |> PdfExtractor.extract_text_from_binary()
  """
  @spec extract_text_from_binary(binary(), pages(), text_options()) ::
          %{page() => String.t() | list(String.t())}
  def extract_text_from_binary(binary, pages, options) do
    {page_numbers, areas} = normalize_pages(pages)

    extract(
      "BytesIO(binary)",
      %{"binary" => binary},
      page_numbers,
      areas,
      "extract_text",
      options,
      "from io import BytesIO\n"
    )
  end

  @spec extract_words(file_path :: String.t(), pages(), options()) ::
          %{page() => list(word()) | list(list(word()))}
  def extract_words(file_path, pages, options) do
    {page_numbers, areas} = normalize_pages(pages)

    "file_path.decode('utf-8')"
    |> extract(%{"file_path" => file_path}, page_numbers, areas, "extract_words", options)
    |> decode_pages(&decode_word/1)
  end

  @spec extract_words_from_binary(binary(), pages(), options()) ::
          %{page() => list(word()) | list(list(word()))}
  def extract_words_from_binary(binary, pages, options) do
    {page_numbers, areas} = normalize_pages(pages)

    "BytesIO(binary)"
    |> extract(
      %{"binary" => binary},
      page_numbers,
      areas,
      "extract_words",
      options,
      "from io import BytesIO\n"
    )
    |> decode_pages(&decode_word/1)
  end

  @spec extract_tables(file_path :: String.t(), pages(), table_options()) ::
          %{page() => list(table()) | list(list(table()))}
  def extract_tables(file_path, pages, options) do
    {page_numbers, areas} = normalize_pages(pages)

    "file_path.decode('utf-8')"
    |> extract(%{"file_path" => file_path}, page_numbers, areas, "extract_tables", options)
    |> decode_pages(&decode_table/1)
  end

  @spec extract_tables_from_binary(binary(), pages(), table_options()) ::
          %{page() => list(table()) | list(list(table()))}
  def extract_tables_from_binary(binary, pages, options) do
    {page_numbers, areas} = normalize_pages(pages)

    "BytesIO(binary)"
    |> extract(
      %{"binary" => binary},
      page_numbers,
      areas,
      "extract_tables",
      options,
      "from io import BytesIO\n"
    )
    |> decode_pages(&decode_table/1)
  end

  @spec extract_page_info(file_path :: String.t(), page() | list(page()), options()) ::
          %{page() => page_info()}
  def extract_page_info(file_path, pages, options) when is_integer(pages) or is_list(pages) do
    {page_numbers, areas} = normalize_pages(pages)

    "file_path.decode('utf-8')"
    |> extract(%{"file_path" => file_path}, page_numbers, areas, "extract_page_info", options)
    |> decode_pages(&decode_page_info/1)
  end

  @spec extract_page_info_from_binary(binary(), page() | list(page()), options()) ::
          %{page() => page_info()}
  def extract_page_info_from_binary(binary, pages, options) when is_integer(pages) or is_list(pages) do
    {page_numbers, areas} = normalize_pages(pages)

    "BytesIO(binary)"
    |> extract(
      %{"binary" => binary},
      page_numbers,
      areas,
      "extract_page_info",
      options,
      "from io import BytesIO\n"
    )
    |> decode_pages(&decode_page_info/1)
  end

  defp normalize_pages(page_number) when is_integer(page_number), do: {[page_number], %{}}
  defp normalize_pages(pages) when is_list(pages), do: {pages, %{}}
  defp normalize_pages(pages) when is_map(pages), do: {Map.keys(pages), pages}

  # `options` must use atom keys: Pythonx turns atoms into Python strings but
  # binaries into bytes, so string keys would not be readable as `options["key"]`.
  defp extract(content_expr, bindings, page_numbers, areas, extractor, options, preamble \\ "") do
    globals =
      Map.merge(bindings, %{
        "page_numbers" => page_numbers,
        "areas" => areas,
        "options" => options
      })

    """
    #{preamble}#{@python_prelude}#{@python_extract_code}

    main(#{content_expr}, page_numbers, areas, #{extractor}, options)
    """
    |> Pythonx.eval(globals)
    |> elem(0)
    |> Pythonx.decode()
  end

  # Python returns structured values as tuples. A page value is one tuple, a list of
  # tuples, or a list of lists of tuples when several areas were requested.
  defp decode_pages(by_page, decode_one) do
    Map.new(by_page, fn {page_number, value} -> {page_number, decode_value(value, decode_one)} end)
  end

  defp decode_value(values, decode_one) when is_list(values) do
    Enum.map(values, &decode_value(&1, decode_one))
  end

  defp decode_value(value, decode_one), do: decode_one.(value)

  defp decode_word({text, left, right, top, bottom}) do
    %{text: text, left: left, right: right, top: top, bottom: bottom}
  end

  defp decode_table({rows, left, top, right, bottom}) do
    %{rows: rows, left: left, right: right, top: top, bottom: bottom}
  end

  defp decode_page_info({width, height, rotation}) do
    %{width: width, height: height, rotation: rotation}
  end

  @spec extract_metadata(file_path :: String.t(), options()) :: %{String.t() => term()}
  def extract_metadata(file_path, options) do
    """
    #{@python_prelude}#{@python_extract_metadata_code}

    main(file_path.decode('utf-8'), options)
    """
    |> Pythonx.eval(%{"file_path" => file_path, "options" => options})
    |> elem(0)
    |> Pythonx.decode()
  end

  @spec extract_metadata_from_binary(binary(), options()) :: %{String.t() => term()}
  def extract_metadata_from_binary(binary, options) do
    """
    from io import BytesIO

    #{@python_prelude}#{@python_extract_metadata_code}

    main(BytesIO(binary), options)
    """
    |> Pythonx.eval(%{"binary" => binary, "options" => options})
    |> elem(0)
    |> Pythonx.decode()
  end

  defp version do
    Application.spec(:pdf_extractor, :vsn)
  end
end
