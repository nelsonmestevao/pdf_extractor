defmodule PdfExtractor.PdfPlumber do
  @moduledoc false

  @spec extract_text(
          file_path :: String.t(),
          page_number :: integer() | list(integer()),
          areas :: map()
        ) :: list(String.t())
  def extract_text(file_path, page_number \\ [], areas \\ %{})

  def extract_text(file_path, page_number, areas) when is_integer(page_number) do
    extract_text(file_path, List.wrap(page_number), areas)
  end

  def extract_text(file_path, page_numbers, areas) when is_list(page_numbers) and is_map(areas) do
    """
    import pdfplumber
    import logging

    logging.getLogger("pdfminer").setLevel(logging.ERROR)

    def extract_from_page(page, area=None):
        if area:
            return page.within_bbox(area).extract_text()
        else:
            return page.extract_text()

    def main(file_path, page_numbers, areas):
        results = []
        with pdfplumber.open(file_path) as pdf:
            total_pages = len(pdf.pages)
            if page_numbers == []:
              page_numbers = list(range(total_pages))
            for page_number in page_numbers:
              if page_number >= 0 and page_number < total_pages:
                results.append(extract_from_page(pdf.pages[page_number], areas.get(page_number)))
            return results

    main(file_path.decode('utf-8'), page_numbers, areas)
    """
    |> Pythonx.eval(%{
      "file_path" => file_path,
      "page_numbers" => page_numbers,
      "areas" => areas
    })
    |> elem(0)
    |> Pythonx.decode()
    |> to_map(page_numbers)
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
end
