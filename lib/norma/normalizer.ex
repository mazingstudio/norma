defmodule Norma.Normalizer do

  def normalize(url = %URI{scheme: nil}, options) do
    url
    |> infer_protocol
    |> normalize(options)
  end

  def normalize(url = %URI{fragment: fragment}, options = %{remove_fragment: true})
    when fragment != nil do
    url
    |> remove_fragment
    |> normalize(options |> Map.drop([:remove_fragment]))
  end

  def normalize(url = %URI{path: path}, options = %{force_root_path: true})
  when path != "/" do
    url
    |> add_root_path
    |> normalize(options |> Map.drop([:force_root_path]))
  end

  def normalize(url, options = %{remove_www: true}) do
    url
    |> remove_www
    |> normalize(options |> Map.drop([:remove_www]))
  end

  def normalize(url, %{}), do: url |> form_url

  defp infer_protocol(url = %URI{port: port}),
    do: url |> Map.put(:scheme, port_handler(port))

  def remove_fragment(url), do: url |> Map.put(:fragment, nil)

  def add_root_path(url), do: url |> Map.put(:path, "/")

  def remove_www(url = %URI{host: host}),
    do: url |> Map.put(:host, parse_host(host))

  defp port_handler (port) do
    case port do
      443  -> "https"
      80   -> "http"
      8080 -> "http"
      21   -> "ftp"
      _    -> "http"
    end
  end

  defp parse_host(host), do: host |> String.trim_leading("www.")

  defp form_url(%URI{host: host,
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

  def safe_concat(left, right) do
    left  = left  || ""
    right = right || ""
    left <> right
  end
end
