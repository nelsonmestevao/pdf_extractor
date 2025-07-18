defmodule PdfExtractor do
  defdelegate start(type \\ :normal, args \\ []),
    to: PdfExtractor.PdfPlumber

  defdelegate extract_text(file_path, page_numbers \\ [], areas \\ %{}),
    to: PdfExtractor.PdfPlumber

  defdelegate extract_metadata(file_path),
    to: PdfExtractor.PdfPlumber

  defdelegate extract_text_from_binary(binary, page_numbers \\ [], areas \\ %{}),
    to: PdfExtractor.PdfPlumber

  defdelegate extract_metadata_from_binary(binary),
    to: PdfExtractor.PdfPlumber
end
