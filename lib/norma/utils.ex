defmodule Norma.Utils do
  def port_handler (port) do
    case port do
      443  -> "https"
      80   -> "http"
      8080 -> "http"
      21   -> "ftp"
      _    -> "http"
    end
  end

  @doc """
  At first, I tried to do this with just the standard library
  ```
  "mazing.studio"
  |> URI.parse
  |> Map.put(:scheme, "http")
  |> URI.to_string

  > "http:mazing.studio"
  ```
  but the result wasn't what I expected.

  Help would be appreciated here to solve it better.
  """
  def form_url(%URI{host: host,
                     path: path,
                     scheme: scheme,
                     query: query,
                     fragment: fragment}) do
    form_scheme(scheme)                   # "http://"
    |> safe_concat(host)                  # "http://google.com"
    |> safe_concat(path)                  # "http://google.com/test"
    |> Kernel.<>(form_fragment(fragment)) # "http://google.com/test#cats"
    |> Kernel.<>(form_query(query))       # "http://google.com/test#cats?dogs_allowed=ño"
  end

  defp form_scheme(""), do: ""
  defp form_scheme(scheme), do: scheme <> "://"

  defp form_fragment(nil), do: ""
  defp form_fragment(fragment), do: "#" <> fragment

  defp form_query(nil), do: ""
  defp form_query(query), do: "?" <> query

  defp safe_concat(left, right) do
    left  = left  || ""
    right = right || ""
    left <> right
  end
end
