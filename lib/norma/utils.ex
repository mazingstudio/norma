defmodule Norma.Utils do
  @moduledoc false

  # Ports that are never rendered back into the normalized URL.
  @masked_ports [443, 80, 8080, 21]

  def port_handler(443), do: "https"
  def port_handler(80), do: "http"
  def port_handler(8080), do: "http"
  def port_handler(21), do: "ftp"
  def port_handler(_port), do: "http"

  @doc """
  Renders a `%URI{}` back into a string.

  Delegates to `URI.to_string/1` after Norma-specific adjustments:

    * masked ports (443, 80, 8080, 21) are dropped, so `google.com:8080`
      normalizes to `http://google.com`;
    * the query string is round-tripped through `URI.decode_query/1` and
      `URI.encode_query/1` so it comes out percent-encoded and key-sorted;
    * userinfo is discarded.

  A blank scheme (set by the `remove_scheme` option) is rendered without the
  leading `//` that `URI.to_string/1` emits for a scheme-less URI.
  """
  def form_url(%URI{scheme: scheme} = url) do
    %{
      url
      | scheme: nil,
        authority: nil,
        userinfo: nil,
        port: form_port(url.port),
        query: form_query(url.query)
    }
    |> URI.to_string()
    |> remove_authority_marker()
    |> prepend_scheme(scheme)
  end

  #####################
  # Private functions #
  #####################

  defp form_port(port) when port in @masked_ports, do: nil
  defp form_port(port), do: port

  defp form_query(nil), do: nil
  defp form_query(query), do: query |> URI.decode_query() |> URI.encode_query()

  defp remove_authority_marker("//" <> rest), do: rest
  defp remove_authority_marker(url), do: url

  defp prepend_scheme(url, nil), do: url
  defp prepend_scheme(url, ""), do: url
  defp prepend_scheme(url, scheme), do: scheme <> "://" <> url
end
