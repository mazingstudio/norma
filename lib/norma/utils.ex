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

  def form_url(%URI{host: host,
                     path: path,
                     scheme: scheme,
                     query: query,
                     fragment: fragment}) do
    scheme                   # "http"
    |> safe_concat("://")    # "http://"
    |> safe_concat(host)     # "http://google.com"
    |> safe_concat(path)     # "http://google.com/test"
    |> safe_concat(fragment) # "http://google.com/test#cats"
    |> safe_concat(query)    # "http://google.com/test#cats?dogs_allowed=ño"
  end

  defp safe_concat(left, right) do
    left  = left  || ""
    right = right || ""
    left <> right
  end
end
