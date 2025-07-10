defmodule PdfExtractor do
  defdelegate start(type \\ :normal, args \\ []),
    to: PdfExtractor.PdfPlumber

  defdelegate extract_text(file_path, page_numbers \\ [], areas \\ %{}),
    to: PdfExtractor.PdfPlumber

  defdelegate extract_text_from_url(file_path, page_numbers \\ [], areas \\ %{}),
    to: PdfExtractor.PdfPlumber
end
