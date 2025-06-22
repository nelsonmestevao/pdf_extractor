# PdfExtractor

[![Release](https://img.shields.io/hexpm/v/pdf_extractor.svg)](https://hex.pm/packages/pdf_extractor)
[![Documentation](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/pdf_extractor)
[![Downloads](https://img.shields.io/hexpm/dt/pdf_extractor.svg)](https://hex.pm/packages/pdf_extractor)
[![License](https://img.shields.io/hexpm/l/pdf_extractor.svg)](https://hex.pm/packages/pdf_extractor)
[![Last Commit](https://img.shields.io/github/last-commit/nelsonmestevao/pdf_extractor.svg)](https://github.com/nelsonmestevao/pdf_extractor)


A lightweight Elixir library for extracting text from PDF files using Python's `pdfplumber`. Supports single and 
multi-page extraction with optional area filtering.

## Features

- 🔍 Extract text from single or multiple PDF pages
- 📍 Area-based extraction using bounding boxes
- 🐍 Leverages Python's powerful `pdfplumber` library
- 🚀 Simple and intuitive API
- ✅ Comprehensive test coverage
- 📚 Full documentation

## Installation

Add `pdf_extractor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pdf_extractor, "~> 0.1.0"}
  ]
end
```

## Usage

Extract text from specific regions using bounding boxes `[x0, y0, x1, y1]`:

```elixir
pages = [0, 1] # zero based index
areas = %{
  0 => [0, 0, 300, 200],    # Top-left area of page 0
  1 => [200, 300, 600, 500] # Bottom-right area of page 1
}
PdfExtractor.PdfPlumber.extract_text("path/to/document.pdf", pages, areas)
```

### Return Format

The function returns a map where keys are page numbers and values are the extracted text:

```elixir
%{
  0 => "Text from page 0...",
  1 => "Text from page 1...",
  2 => "Text from page 2..."
}
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built on top of the excellent [pdfplumber](https://github.com/jsvine/pdfplumber) Python library
- Uses [pythonx](https://github.com/livebook-dev/pythonx) for seamless Python integration

