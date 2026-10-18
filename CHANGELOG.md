# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Read the text of characters a PDF gives only as ActualText, such as glyphs mapped to no text of their own, which came out as `\u0000` or not at all

## [0.10.0] - 2026-10-17

- **Breaking:** `extract_tables/3` and `extract_tables_from_binary/3` return each table as a map with its `rows` and the `left`, `right`, `top` and `bottom` edges of its bounding box, instead of only the rows
- Add `extract_page_info/3` and `extract_page_info_from_binary/3` to get the number of pages and the size and rotation of each one
- Add `font: true` option to `extract_words/3` and `extract_words_from_binary/3` to get the font name and size of each word
- Add `render_pages/3` and `render_pages_from_binary/3` to render pages or areas to PNG images

## [0.9.0] - 2026-10-17

- Add `extract_words/3` and `extract_words_from_binary/3` to get every word with its bounding box on the page
- Add `layout: true` option to `extract_text/3` and `extract_text_from_binary/3` to keep the position of the text on the page
- Add `extract_tables/3` and `extract_tables_from_binary/3` with `vertical_strategy` and `horizontal_strategy` options
- Add `password` option to every function to open encrypted PDFs

## [0.8.0] - 2026-10-16

- Upgrade Python to v3.14 and pin uv to v0.12.24 so recent CPython builds are available
- Upgrade pdfplumber to v0.11.10 (bundles pdfminer.six 20260107)
- Upgrade pythonx to v0.4.10
- Upgrade dev tooling: credo v1.7.19, dialyxir v1.4.8, ex_doc v0.40.4, styler v1.12.2

## [0.7.0] - 2026-09-27

- Fix out-of-range page numbers shifting the extracted text onto the wrong pages
- Return `{:error, exception}` for invalid arguments instead of crashing the server

## [0.6.0] - 2026-04-03

- Add configurable `timeout` option to all extraction functions (default: 5000ms)
- Add `name` option to target a specific server process

## [0.5.1] - 2026-04-03

- Upgrade pdfplumber to v0.11.9
- Upgrade pythonx to v0.4.9

## [0.5.0] - 2025-08-23

- Simplify arguments to avoid repetition
- Upgrade Python to v3.12 and pdfplumber to v0.11.7
- Lower Elixir requirement to v1.15

## [0.4.1] - 2025-07-30

- Fix `PdfExtractor.start_link/1` call to link the process correctly to the supervisor tree

## [0.4.0] - 2025-07-21

### Changed
- Made PdfExtractor a single process to avoid issues with the Python GIL

## [0.3.0] - 2025-07-20

### Added
- **Multiple Areas Support**: Extract text from multiple bounding box areas on the same page
- **Metadata Extraction**: New `extract_metadata/1` and `extract_metadata_from_binary/1` functions
- **Binary PDF Processing**: Extract text and metadata directly from PDF binary data
- **Enhanced Documentation**: Comprehensive doctests and improved API documentation
- **Improved Test Coverage**: Added extensive test suite for new functionality

### Changed
- Enhanced area-based extraction to support lists of areas per page
- Improved error handling and edge case management
- Updated type specifications for better developer experience

### Fixed
- Better handling of invalid page numbers and area coordinates
- Improved Python environment initialization

## [0.2.1] - 2025-06-27

### Fixed
- Added automatic Python dependencies download and installation
- Improved application startup process

## [0.2.0] - 2025-06-22

### Added
- Project badges and improved README documentation
- Enhanced configuration and documentation setup

### Changed

- Improved function naming and API consistency
- Better documentation structure

## [0.1.0] - 2025-06-21

### Added
- Initial release of PdfExtractor
- Support for extracting text from PDF files using Python's pdfplumber
- Single page text extraction
- Multi-page text extraction
- Basic area-based text extraction with bounding boxes
- Initial test suite
- Basic documentation and examples

### Dependencies
- pythonx ~> 0.4.0 for Python integration
- Requires Python with pdfplumber package installed

[Unreleased]: https://github.com/nelsonmestevao/pdf_extractor/compare/v0.10.0...HEAD
[0.10.0]: https://github.com/nelsonmestevao/pdf_extractor/compare/v0.9.0...v0.10.0
[0.9.0]: https://github.com/nelsonmestevao/pdf_extractor/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/nelsonmestevao/pdf_extractor/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/nelsonmestevao/pdf_extractor/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/nelsonmestevao/pdf_extractor/compare/v0.5.1...v0.6.0
[0.5.1]: https://github.com/nelsonmestevao/pdf_extractor/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/nelsonmestevao/pdf_extractor/compare/v0.4.1...v0.5.0
[0.4.1]: https://github.com/nelsonmestevao/pdf_extractor/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/nelsonmestevao/pdf_extractor/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/nelsonmestevao/pdf_extractor/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/nelsonmestevao/pdf_extractor/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/nelsonmestevao/pdf_extractor/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/nelsonmestevao/pdf_extractor/releases/tag/v0.1.0
