defmodule ReadmeTest do
  use ExUnit.Case, async: true

  test "version in readme matches mix.exs" do
    assert File.read!(Path.join(__DIR__, "../README.md")) =~
             ~s'{:#{Mix.Project.config()[:app]}, "~> #{Mix.Project.config()[:version]}"}'
  end
end
