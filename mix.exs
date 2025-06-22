defmodule PdfExtractor.MixProject do
  use Mix.Project

  @app :pdf_extractor
  @name "PdfExtractor"
  @version "0.2.0"
  @source_url "https://github.com/nelsonmestevao/pdf_extractor"

  def project do
    [
      name: @name,
      app: @app,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:pythonx, "~> 0.4.0"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    A lightweight Elixir library for extracting text from PDF files using Python's pdfplumber.
    Supports single and multi-page extraction with optional area filtering.
    """
  end

  defp package do
    [
      name: @app,
      files: ~w(config lib mix.exs README* LICENSE* CHANGELOG*),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      },
      maintainers: ["Nelson Estevão <nelsonmestevao@proton.me>"]
    ]
  end

  defp docs do
    [
      main: "readme",
      name: @name,
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end
end
