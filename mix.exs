defmodule Norma.Mixfile do
  use Mix.Project

  def project do
    [
      app: :norma,
      version: "1.7.4",
      elixir: "~> 1.3",
      start_permanent: Mix.env == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Norma",
      source_url: "https://github.com/mazingstudio/norma"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    "Normalize / sanitize URLs to the format you need."
  end

  defp package do
    [
      maintainers: ["Zura Guerra", "Mazing Studio"],
      licenses: ["MIT"],
      links: %{
        "Github" => "https://github.com/mazingstudio/norma"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
