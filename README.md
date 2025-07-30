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
    {:pdf_extractor, "~> 0.4.1"}
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

Extract text from specific regions using bounding boxes `[x0, y0, x1, y1]`:

```elixir
pages = [0, 1, 2] # zero based index
areas = %{
  0 => {0, 0, 300, 200},    # Top-left area of page 0
  1 => [
        {200, 300, 600, 500}, # Bottom-right area of page 1
        {0, 0, 200, 250}, # Top-left area of page 1
       ]
}
PdfExtractor.extract_text("path/to/document.pdf", pages, areas)
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

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built on top of the excellent [pdfplumber](https://github.com/jsvine/pdfplumber) Python library
- Uses [pythonx](https://github.com/livebook-dev/pythonx) for seamless Python integration

