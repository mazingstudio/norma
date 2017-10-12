defmodule Norma do
  alias Norma.{Normalizer}

  @doc """
  Normalize URL according to the options given.
  Defaults scheme to `http`.

  ## Options
  - `remove_fragment`
  - `force_root_path`
  - `remove_www`

  Check the README for the full examples.

  ## Examples

      iex> Norma.normalize("//www.mazing.studio", %{remove_www: true})
      "http://mazing.studio"

  """
  def normalize(url, options \\ %{}) do
    url
    |> URI.parse
    |> Normalizer.normalize(options)
  end
end
