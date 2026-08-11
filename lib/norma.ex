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
  - `add_root_path`
  - `add_trailing_slash`
  - `remove_www`
  - `remove_scheme`
  - `restore_old_query_behavior` — rebuild the query the 1.x way (keys sorted,
    duplicate keys collapsed to the last value) instead of preserving input
    order and duplicates

  Host case is always folded to lowercase via RFC 3986 normalization
  (`:uri_string.normalize/1`). The 1.x `downcase_host` option was removed in 2.0.

  Check the README for the full examples.

  ## Examples

      iex> Norma.normalize("//www.mazing.studio", %{remove_www: true})
      {:ok, "http://mazing.studio"}

  """
  @spec normalize_if_valid(String.t(), map()) :: {:ok, String.t()} | {:error, String.t()}
  def normalize_if_valid(url, options \\ %{}) do
    if valid_url?(url) do
      case safe_parse(url) do
        {:ok, uri} ->
          {:ok, Normalizer.normalize(uri, options)}

        {:error, _} ->
          {:error, "Not an URL."}
      end
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

  # Parse via `URI.new/1` (Elixir 1.13+): `{:ok, uri} | {:error, part}`.
  # No raise → no rescue → no re-parse loop between helpers.
  #
  # Scheme-less / host-less inputs such as "mazing.studio:80" parse with
  # `host: nil` under RFC 3986 (scheme swallows the host). The old code
  # fixed that by mutual recursion between `safe_parse` and
  # `has_valid_host?`. Here the same `//`-prefix authority hint is applied
  # **once** as an explicit branch.
  #
  # `URI.new/1` rejects some inputs `URI.parse/1` accepted (raw non-ASCII in
  # the query). Those fall back to a single non-recursive `URI.parse/1` so
  # existing golden outputs stay byte-identical.
  defp safe_parse(url) when is_binary(url) do
    case parse_uri(url) do
      %URI{host: nil} = uri ->
        parse_with_authority_hint(uri)

      %URI{} = uri ->
        {:ok, uri}
    end
  end

  defp parse_uri(url) when is_binary(url) do
    case URI.new(url) do
      {:ok, uri} -> uri
      {:error, _} -> URI.parse(url)
    end
  end

  # Single non-recursive retry: prepend "//" so the authority parses as host.
  defp parse_with_authority_hint(%URI{} = uri) do
    {:ok, parse_uri("//" <> URI.to_string(uri))}
  end

  # Helps discard strings that are not URLs, like mailto and javascript links.
  #
  # This sure looks dumb, but a valid host will normally have at least a dot.
  @non_url_schemes ["mailto:", "javascript:"]

  defp valid_url?(url) do
    not String.starts_with?(url, @non_url_schemes) and String.contains?(url, ".")
  end
end
