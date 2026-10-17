# PdfExtractor

[![Release](https://img.shields.io/hexpm/v/pdf_extractor.svg)](https://hex.pm/packages/pdf_extractor)
[![Documentation](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/pdf_extractor)
[![Downloads](https://img.shields.io/hexpm/dt/pdf_extractor.svg)](https://hex.pm/packages/pdf_extractor)
[![License](https://img.shields.io/hexpm/l/pdf_extractor.svg)](https://hex.pm/packages/pdf_extractor)
[![Last Commit](https://img.shields.io/github/last-commit/nelsonmestevao/pdf_extractor.svg)](https://github.com/nelsonmestevao/pdf_extractor)


A powerful and easy-to-use Elixir library for extracting text and metadata from PDF files.

PdfExtractor leverages Python's `pdfplumber` library through seamless integration to provide
robust PDF text extraction capabilities. It supports both file-based and binary-based operations,
making it suitable for various use cases from local file processing to web-based PDF handling.

## Features

- 🔍 Extract text from single or multiple PDF pages
- 📍 Area-based extraction using bounding boxes
- 📐 Extract words together with their position on the page
- 📋 Extract tables as rows of cells
- 🔐 Open encrypted PDFs with a password
- 🌐 Work with PDF data directly from memory (e.g., HTTP downloads)
- 📊 Get PDF metadata like title, author, creation date
- 🐍 Leverages Python's powerful `pdfplumber` library
- 🚀 Simple and intuitive API
- ✅ Comprehensive test coverage
- 📚 Full documentation

## Installation

Add `pdf_extractor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pdf_extractor, "~> 0.9.0"}
  ]
end
```

Then start it in your application start function:

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
        PdfExtractor,
        ...
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

## Usage

Extract text from specific regions using bounding boxes `{x0, y0, x1, y1}`:

```elixir
pages = %{
  0 => {0, 0, 300, 200},    # Top-left area of page 0
  1 => [
        {200, 300, 600, 500}, # Bottom-right area of page 1
        {0, 0, 200, 250}, # Top-left area of page 1
       ]
}
PdfExtractor.extract_text("path/to/document.pdf", pages)
```

### Return Format

The function returns a map where keys are page numbers and values are the extracted text:

```elixir
%{
  0 => "Text from page 0...",
  1 => ["Text from page 1 (first area)...", "Text from page 1 (second area)..."],
  2 => "Text from page 2..."
}
```

### Keeping the Layout

Pass `layout: true` to pad the text with spaces and blank lines so it keeps its position on the page.
Columns of statements and tables stay aligned instead of being flattened into single lines:

```elixir
PdfExtractor.extract_text("path/to/document.pdf", 0, layout: true)
```

### Encrypted Files

Every function takes a `:password` option for encrypted PDFs. Without it, or with a wrong one,
the function returns `{:error, exception}`:

```elixir
PdfExtractor.extract_text("path/to/document.pdf", [], password: "secret")
```

### Tables

Use `extract_tables/3` to get the tables of each page as rows of cells. By default the cell borders
come from the lines drawn on the page; use the `:text` strategy for tables drawn without lines:

```elixir
PdfExtractor.extract_tables("path/to/document.pdf", 0)
# {:ok, %{0 => [[["Item", "Quantity", "Price"], ["Work", "1", "1 500,00 €"]]]}}

PdfExtractor.extract_tables("path/to/document.pdf", 0,
  vertical_strategy: :text,
  horizontal_strategy: :text
)
```

### Words With Positions

Use `extract_words/3` to get every word with its bounding box in PDF points, measured from the top left
corner of the page. It takes the same pages and areas as `extract_text/3`:

```elixir
PdfExtractor.extract_words("path/to/document.pdf", 0)
# {:ok,
#  %{
#    0 => [
#      %{text: "Text", left: 48.0, right: 67.99875, top: 26.64224999999999, bottom: 36.39224999999999},
#      %{text: "Example", left: 70.734375, right: 110.757, top: 26.64224999999999, bottom: 36.39224999999999},
#      ...
#    ]
#  }}
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built on top of the excellent [pdfplumber](https://github.com/jsvine/pdfplumber) Python library
- Uses [pythonx](https://github.com/livebook-dev/pythonx) for seamless Python integration
