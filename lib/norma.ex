defmodule Norma do
  @moduledoc """
  URL normalization.

  `Norma` parses a URL string and rewrites it into a canonical form,
  defaulting the scheme to `http` and applying the transformations
  requested through the options map.

  Two entry points are provided:

  - `normalize_if_valid/2` — returns `{:ok, url}` or `{:error, reason}`.
  - `normalize/2` — returns the normalized URL, or the input unchanged
    when it isn't a URL.

  See `normalize_if_valid/2` for the list of supported options.
  """

  alias Norma.{Normalizer}

  @doc """
  Normalize URL according to the options given.
  Defaults scheme to `http`.

  ## Options
  - `remove_fragment`
  - `force_root_path`
  - `add_trailing_slash`
  - `remove_www`
  - `downcase_host`
  - `restore_old_query_behavior` — rebuild the query the 1.x way (keys sorted,
    duplicate keys collapsed to the last value) instead of preserving input
    order and duplicates

  Check the README for the full examples.

  ## Examples

      iex> Norma.normalize("//www.mazing.studio", %{remove_www: true})
      {:ok, "http://mazing.studio"}

  """
  @spec normalize_if_valid(String.t(), map()) :: {:ok, String.t()} | {:error, String.t()}
  def normalize_if_valid(url, options \\ %{}) do
    if valid_url?(url) do
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
  @spec normalize(String.t(), map()) :: String.t()
  def normalize(url, options \\ %{}) do
    case normalize_if_valid(url, options) do
      {:ok, normalized_url} -> normalized_url
      {:error, _} -> url
    end
  end

  #####################
  # Private functions #
  #####################

  # Solve an issue related to the regex provided by the URI spec
  # (see https://tools.ietf.org/html/rfc3986#appendix-B).
  #
  # If trying to parse from string to %URI{} something like "mazing.studio:80",
  # the result will be:
  #   %URI{scheme: "mazing.studio", path: "21", host: nil}
  #   _(Other keys skipped for brevity, but their value is `nil`.)_
  #
  # But "//mazing.studio:80", will be parsed correctly:
  #   %URI{host: "mazing.studio", authority: "mazing.studio:80", port: 80}
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

  # Helps discard strings that are not URLs, like mailto and javascript links.
  #
  # This sure looks dumb, but a valid host will normally have at least a dot.
  @non_url_schemes ["mailto:", "javascript:"]

  defp valid_url?(url) do
    not String.starts_with?(url, @non_url_schemes) and String.contains?(url, ".")
  end
end
