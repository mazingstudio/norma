defmodule Norma do
  alias Norma.{Normalizer}

  @doc """
  Normalize URL according to the options given.
  Defaults scheme to `http`.

  ## Options
  - `remove_fragment`
  - `force_root_path`
  - `remove_www`
  - `downcase_host`

  Check the README for the full examples.

  ## Examples

      iex> Norma.normalize("//www.mazing.studio", %{remove_www: true})
      {:ok, "http://mazing.studio"}

  """
  def normalize_if_valid(url, options \\ %{}) do
    if is_url?(url) do
      normalized_url =
        url
        |> safe_parse
        |> Normalizer.normalize(options)

      {:ok, normalized_url}
    else
      {:error, "Not an URL."}
    end
  end

  @doc """
  Similar to `normalize_if_valid/2`, but will return the given string unchanged
  if it's not an URL.

  ## Examples

      iex> Norma.normalize!("//www.mazing.studio", %{remove_www: true})
      "http://mazing.studio"
  """
  def normalize(url, options \\ %{}) do
    case normalize_if_valid(url, options) do
      {:ok, normalized_url} -> normalized_url
      {:error, _} -> url
    end
  end

  @doc """
  Solve an issue related to the regex provided by the URI spec
  (see https://tools.ietf.org/html/rfc3986#appendix-B).

  If trying to parse from string to %URI{} something like "mazing.studio:80",
  the result will be:
    %URI{scheme: "mazing.studio", path: "21", host: nil}
    _(Other keys skipped for brevity, but their value is `nil`.)_

  But "//mazing.studio:80", will be parsed correctly:
    %URI{host: "mazing.studio", authority: "mazing.studio:80", port: 80}
  """
  defp safe_parse(url) do
    url
    |> URI.parse()
    |> has_valid_host?
  end

  defp has_valid_host?(url = %URI{host: nil}) do
    url = url |> URI.to_string()

    ("//" <> url)
    |> safe_parse
  end

  defp has_valid_host?(url = %URI{host: host})
       when host != nil,
       do: url

  @doc """
  Helps discard strings that are not URLs, like mailto and javascript links.

  This sure looks dumb, but a valid host will normally have at least a dot.
  """
  defp is_url?(url) do
    cond do
      String.starts_with?(url, "mailto:") -> false
      String.starts_with?(url, "javascript:") -> false
      true -> String.contains?(url, ".")
    end
  end
end
