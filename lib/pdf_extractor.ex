defmodule PdfExtractor do
  defdelegate extract_text(file_path, page_numbers \\ [], areas \\ %{}),
    to: PdfExtractor.PdfPlumber
end
