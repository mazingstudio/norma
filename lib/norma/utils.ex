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

    * the query string is round-tripped through `URI.decode_query/1` and
      `URI.encode_query/1` so it comes out percent-encoded and key-sorted;
    * userinfo is discarded.

  A blank scheme (set by the `remove_scheme` option) is rendered without the
  leading `//` that `URI.to_string/1` emits for a scheme-less URI.

  When a scheme is present, the assembled string is passed through
  `:uri_string.normalize/1` (RFC 3986) with no opt-out: dot-segment removal,
  host case folding, percent-encoding normalization, and scheme-aware
  default-port removal. If normalize returns `{:error, _, _}`, the
  pre-normalization string is returned unchanged.

  Default ports (80/443/21) are omitted by `URI.to_string/1` and
  `:uri_string.normalize/1` according to scheme. Non-default ports including
  8080 are preserved.
  """
  def form_url(%URI{scheme: ""} = url) do
    # `remove_scheme` blanked the scheme; do not run RFC normalize (needs a
    # scheme for default-port rules). Drop only ports that are defaults for
    # some scheme so `https://h` does not become `h:443` after the blank.
    %{
      url
      | scheme: nil,
        authority: nil,
        userinfo: nil,
        port: port_when_schemeless(url.port),
        query: form_query(url.query)
    }
    |> URI.to_string()
    |> remove_authority_marker()
  end

  def form_url(%URI{} = url) do
    rendered =
      %{
        url
        | authority: nil,
          userinfo: nil,
          query: form_query(url.query)
      }
      |> URI.to_string()

    rfc_normalize(rendered)
  end

  #####################
  # Private functions #
  #####################

  defp form_query(nil), do: nil
  defp form_query(query), do: query |> URI.decode_query() |> URI.encode_query()

  # Ports that are the default for at least one scheme `port_handler/1` knows
  # about. Used only on the blank-scheme path where `:uri_string` cannot apply
  # scheme-aware omission. 8080 is intentionally NOT listed — it must survive.
  defp port_when_schemeless(port) when port in [80, 443, 21], do: nil
  defp port_when_schemeless(port), do: port

  defp remove_authority_marker("//" <> rest), do: rest
  defp remove_authority_marker(url), do: url

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
