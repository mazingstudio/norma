defmodule Norma.Normalizer do
  alias Norma.{Utils}

  @moduledoc """
  `normalize/2` reduces the given URL and options until these conditions
  are met:
    1. `options == %{}`
    2. `url.scheme != nil`
  """

  @doc """
  Leave the scheme blank.
  """
  def normalize(url, options = %{remove_scheme: true}) do
    url
    |> add_blank_scheme
    |> normalize(options |> Map.drop([:remove_scheme]))
  end

  @doc """
  Handles a missing scheme. Defaults to `http` or infers it from the port.
  """
  def normalize(url = %URI{scheme: nil}, options) do
    url
    |> infer_scheme
    |> normalize(options)
  end

  @doc """
  Removes URL fragments.
  """
  def normalize(url = %URI{fragment: fragment}, options = %{remove_fragment: true})
      when fragment != nil do
    url
    |> remove_fragment
    |> normalize(options |> Map.drop([:remove_fragment]))
  end

  @doc """
  Forces path to be "/".
  """
  def normalize(url = %URI{path: path}, options = %{force_root_path: true})
      when path != "/" do
    url
    |> force_root_path
    |> normalize(options |> Map.drop([:force_root_path]))
  end

  @doc """
  Adds a trailing slash to the path unless it's already "/" or has an extension
  """
  def normalize(url = %URI{path: path}, options = %{add_trailing_slash: true})
      when path != "/" do
    url
    |> add_trailing_slash()
    |> normalize(options |> Map.drop([:add_trailing_slash]))
  end

  @doc """
  Removes "www." from the host.
  """
  def normalize(url, options = %{remove_www: true}) do
    url
    |> remove_www
    |> normalize(options |> Map.drop([:remove_www]))
  end

  @doc """
  Downcases host.
  """
  def normalize(url, options = %{downcase_host: true}) do
    url
    |> downcase_host()
    |> normalize(options |> Map.drop([:downcase_host]))
  end

  @doc """
  If the URL elements are valid now, forms a string.
  """
  def normalize(url, %{}), do: url |> Utils.form_url()

  defp add_blank_scheme(url), do: url |> Map.put(:scheme, "")

  defp infer_scheme(url = %URI{port: port}),
    do: url |> Map.put(:scheme, Utils.port_handler(port))

  defp remove_fragment(url), do: url |> Map.put(:fragment, nil)

  defp force_root_path(url), do: url |> Map.put(:path, "/")

  defp add_trailing_slash(url = %URI{path: path}) do
    if path && String.contains?(path, ".") do
      url
    else
      url |> Map.put(:path, "#{path}/")
    end
  end

  # If a scheme is not provided, `URI.parse` puts
  # the host info in `:path`.
  defp remove_www(url = %URI{host: host, path: path})
       when is_nil(host) and path != nil do
    url
    |> Map.put(:host, parse_host(path))
    |> Map.put(:path, nil)
  end

  defp remove_www(url = %URI{host: host}),
    do: url |> Map.put(:host, parse_host(host))

  defp parse_host(host), do: host |> String.trim_leading("www.")

  defp downcase_host(url) do
    Map.put(url, :host, String.downcase(url.host))
  end
end
