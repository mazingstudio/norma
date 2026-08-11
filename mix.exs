defmodule Norma.Mixfile do
  use Mix.Project

  @version "1.9.0"

  def project do
    [
      app: :norma,
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Norma",
      source_url: "https://github.com/mazingstudio/norma",
      docs: [
        main: "Norma",
        extras: ["CHANGELOG.md"]
      ]
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
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false}
    ]
  end
end
