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
      {:ok, "http://mazing.studio"}

  """
  def normalize(url, options \\ %{}) do
    if is_url?(url) do
      normalized_url = url
        |> URI.parse
        |> Normalizer.normalize(options)
      {:ok, normalized_url}
    else
      {:error, "Not an URL."}
    end
  end

  @doc """
  Similar to `normalize/2`, but will return the given string unchanged
  if it's not an URL.

  ## Examples

      iex> Norma.normalize!("//www.mazing.studio", %{remove_www: true})
      "http://mazing.studio"
  """
  def normalize!(url, options \\ %{}) do
    case normalize(url, options) do
      {:ok, normalized_url} -> normalized_url
      {:error, _} -> url
    end
  end

  defp is_url?(url), do: url |> String.contains?(".")
end
