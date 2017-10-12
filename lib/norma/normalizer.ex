defmodule Norma.Normalizer do
  alias Norma.{Utils}

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

  def normalize(url, %{}), do: url |> Utils.form_url

  defp infer_protocol(url = %URI{port: port}),
    do: url |> Map.put(:scheme, Utils.port_handler(port))

  defp remove_fragment(url), do: url |> Map.put(:fragment, nil)

  defp add_root_path(url), do: url |> Map.put(:path, "/")

  defp remove_www(url = %URI{host: host}),
    do: url |> Map.put(:host, parse_host(host))

  defp parse_host(host), do: host |> String.trim_leading("www.")
end
