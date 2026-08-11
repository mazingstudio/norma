defmodule Norma.Utils do
  @moduledoc false

  def port_handler(443), do: "https"
  def port_handler(80), do: "http"
  def port_handler(8080), do: "http"
  def port_handler(21), do: "ftp"
  def port_handler(_port), do: "http"

  @doc """
  Renders a `%URI{}` back into a string.

  Delegates to `URI.to_string/1` after Norma-specific adjustments:

    * the query string is rebuilt from `URI.query_decoder/1` pairs and
      `URI.encode_query/1`, preserving **input order** and **duplicate keys**;
    * pass `%{restore_old_query_behavior: true}` as the second argument to
      restore the 1.x map round-trip (`URI.decode_query/1` → `URI.encode_query/1`),
      which sorts keys and collapses duplicates (last value wins);
    * userinfo is discarded.

  A blank scheme (set by the `remove_scheme` option) is rendered without the
  leading `//` that `URI.to_string/1` emits for a scheme-less URI.

  When a scheme is present, the assembled string is passed through
  `:uri_string.normalize/1` (RFC 3986) with no opt-out: dot-segment removal,
  host case folding, percent-encoding normalization, and scheme-aware
  default-port removal. If normalize returns `{:error, _, _}`, the
  pre-normalization string is returned unchanged.

  One deliberate deviation from RFC 3986 §6.2.3: when the input had no path,
  the `/` that normalization adds is stripped back off, so `example.com`
  renders as `http://example.com` rather than `http://example.com/`. This keeps
  the `add_trailing_slash`, `add_root_path` and `force_root_path` options
  meaningful.

  Default ports (80/443/21) are omitted by `URI.to_string/1` and
  `:uri_string.normalize/1` according to scheme. Non-default ports including
  8080 are preserved.
  """
  def form_url(url, opts \\ %{})

  def form_url(%URI{scheme: ""} = url, opts) when is_map(opts) do
    # `remove_scheme` blanked the scheme; do not run RFC normalize (needs a
    # scheme for default-port rules). Drop only ports that are defaults for
    # some scheme so `https://h` does not become `h:443` after the blank.
    %{
      url
      | scheme: nil,
        authority: nil,
        userinfo: nil,
        port: port_when_schemeless(url.port),
        query: form_query(url.query, opts)
    }
    |> URI.to_string()
    |> remove_authority_marker()
  end

  def form_url(%URI{} = url, opts) when is_map(opts) do
    rendered =
      %{
        url
        | authority: nil,
          userinfo: nil,
          query: form_query(url.query, opts)
      }
      |> URI.to_string()

    # RFC normalize is the final transform (D6); it must not reorder/dedupe query.
    rendered
    |> rfc_normalize()
    |> restore_empty_path(url.path)
  end

  #####################
  # Private functions #
  #####################

  defp form_query(nil, _opts), do: nil

  # 1.x compatibility: map round-trip sorts keys and collapses duplicate keys.
  defp form_query(query, %{restore_old_query_behavior: true}) do
    query |> URI.decode_query() |> URI.encode_query()
  end

  # Default (2.0): preserve pair order and multi-value keys.
  defp form_query(query, _opts) do
    query
    |> URI.query_decoder()
    |> Enum.to_list()
    |> URI.encode_query()
  end

  # Ports that are the default for at least one scheme `port_handler/1` knows
  # about. Used only on the blank-scheme path where `:uri_string` cannot apply
  # scheme-aware omission. 8080 is intentionally NOT listed — it must survive.
  defp port_when_schemeless(port) when port in [80, 443, 21], do: nil
  defp port_when_schemeless(port), do: port

  defp remove_authority_marker("//" <> rest), do: rest
  defp remove_authority_marker(url), do: url

  # RFC 3986 §6.2.3 says an empty path on a hierarchical URI normalizes to "/",
  # and `:uri_string.normalize/1` does exactly that. Norma deliberately deviates:
  # if the caller's URI had no path, the added slash is stripped back off, so
  # `add_trailing_slash`, `add_root_path` and `force_root_path` stay meaningful
  # instead of being pre-empted by normalization.
  defp restore_empty_path(normalized, path) when path in [nil, ""] do
    case URI.new(normalized) do
      {:ok, %URI{path: "/"} = uri} -> URI.to_string(%{uri | path: nil})
      _ -> normalized
    end
  end

  defp restore_empty_path(normalized, _path), do: normalized

  defp rfc_normalize(url) do
    case :uri_string.normalize(url) do
      {:error, _, _} ->
        url

      normalized when is_binary(normalized) ->
        normalized

      normalized when is_list(normalized) ->
        List.to_string(normalized)
    end
  end
end
