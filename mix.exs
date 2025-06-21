defmodule PdfExtractor.MixProject do
  use Mix.Project

  def project do
    [
      app: :pdf_extractor,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:pythonx, "~> 0.4.0"}
    ]
  end
end
