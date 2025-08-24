# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/nelsonmestevao/pdf_extractor/compare/v0.5.0...HEAD
[0.5.0]: https://github.com/nelsonmestevao/pdf_extractor/compare/v0.4.1...v0.5.0
[0.4.1]: https://github.com/nelsonmestevao/pdf_extractor/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/nelsonmestevao/pdf_extractor/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/nelsonmestevao/pdf_extractor/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/nelsonmestevao/pdf_extractor/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/nelsonmestevao/pdf_extractor/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/nelsonmestevao/pdf_extractor/releases/tag/v0.1.0
