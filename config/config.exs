import Config

config :pythonx, :uv_init,
  pyproject_toml: """
  [project]
  name = "pdf_extractor"
  version = "0.0.0"
  requires-python = "==3.11.*"
  dependencies = [
    "pdfplumber==0.11.6"
  ]
  """
