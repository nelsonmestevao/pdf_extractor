defmodule PdfExtractor do
  defdelegate text(file_path, page_numbers \\ [], areas \\ %{}),
    to: PdfExtractor.PdfPlumber,
    as: :extract_text
end
