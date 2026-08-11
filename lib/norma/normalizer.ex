defmodule Norma.Normalizer do
  @moduledoc """
  Applies option-driven normalization steps to a parsed `%URI{}`.

  Called by `Norma` after validation and `URI.parse/1`. Options match the
  public `Norma.normalize/2` API (`remove_fragment`, `force_root_path`,
  `add_root_path`, `add_trailing_slash`, `remove_www`, `downcase_host`,
  `remove_scheme`).
  """

  alias Norma.Utils

  @type option_key ::
          :remove_fragment
          | :force_root_path
          | :add_root_path
          | :add_trailing_slash
          | :remove_www
          | :downcase_host
          | :remove_scheme

  @type options :: %{optional(option_key()) => boolean()}

  @doc """
  Normalizes the given `url`, accepts the following options:

    - `remove_fragment`
    - `force_root_path`
    - `add_root_path`
    - `add_trailing_slash`
    - `remove_www`
    - `downcase_host`
  """
  @spec normalize(URI.t(), options()) :: String.t()
  def normalize(url, options \\ %{}), do: reduce_normalize(url, options)

  #####################
  # Private functions #
  #####################

  # `reduce_normalize/2` reduces the given URL and options until these conditions are met:
  #  1. `options == %{}`
  #  2. `url.scheme != nil`

  # Leaves the scheme blank.
  defp reduce_normalize(url, options = %{remove_scheme: true}) do
    url
    |> add_blank_scheme
    |> reduce_normalize(options |> Map.drop([:remove_scheme]))
  end

  # Handles a missing scheme. Defaults to `http` or infers it from the port.
  defp reduce_normalize(url = %URI{scheme: nil}, options) do
    url
    |> infer_scheme
    |> reduce_normalize(options)
  end

  # Removes URL fragments.
  defp reduce_normalize(url = %URI{fragment: fragment}, options = %{remove_fragment: true})
       when fragment != nil do
    url
    |> remove_fragment
    |> reduce_normalize(options |> Map.drop([:remove_fragment]))
  end

  # Forces path to "/" and wipes query + fragment (issue #7 / 2.0 D4).
  defp reduce_normalize(url, options = %{force_root_path: true}) do
    url
    |> force_root_path()
    |> reduce_normalize(options |> Map.drop([:force_root_path]))
  end

  # Additive: set path to "/" only when path is nil or empty (issue #7 / 2.0 D4).
  defp reduce_normalize(url = %URI{path: path}, options = %{add_root_path: true})
       when path in [nil, ""] do
    url
    |> add_root_path()
    |> reduce_normalize(options |> Map.drop([:add_root_path]))
  end

  defp reduce_normalize(url, options = %{add_root_path: true}) do
    reduce_normalize(url, options |> Map.drop([:add_root_path]))
  end

  # Adds a trailing slash to the path unless it's already "/" or the final
  # segment looks like a file (contains a ".").
  defp reduce_normalize(url = %URI{path: path}, options = %{add_trailing_slash: true})
       when path != "/" do
    url
    |> add_trailing_slash()
    |> reduce_normalize(options |> Map.drop([:add_trailing_slash]))
  end

  # Removes "www." from the host.
  defp reduce_normalize(url, options = %{remove_www: true}) do
    url
    |> remove_www
    |> reduce_normalize(options |> Map.drop([:remove_www]))
  end

  # Downcases host.
  defp reduce_normalize(url, options = %{downcase_host: true}) do
    url
    |> downcase_host()
    |> reduce_normalize(options |> Map.drop([:downcase_host]))
  end

  # If the URL elements are valid now, forms a string. Remaining options
  # (e.g. `restore_old_query_behavior`) are consumed by `form_url/2`.
  defp reduce_normalize(url, options), do: Utils.form_url(url, options)

  defp add_blank_scheme(url), do: %{url | scheme: ""}

  defp infer_scheme(url = %URI{port: port}),
    do: %{url | scheme: Utils.port_handler(port)}

  defp remove_fragment(url), do: %{url | fragment: nil}

  defp force_root_path(url), do: %{url | path: "/", query: nil, fragment: nil}

  defp add_root_path(url), do: %{url | path: "/"}

  defp add_trailing_slash(url = %URI{path: path}) do
    cond do
      is_nil(path) ->
        %{url | path: "/"}

      String.ends_with?(path, "/") ->
        url

      final_segment_has_dot?(path) ->
        url

      true ->
        %{url | path: path <> "/"}
    end
  end

  # Skip trailing slash only when the *final* path segment contains a dot
  # (file-like). Intermediate dotted segments (e.g. /v1.2/docs) do not block.
  defp final_segment_has_dot?(path) do
    path
    |> String.split("/", trim: true)
    |> List.last()
    |> case do
      nil -> false
      segment -> String.contains?(segment, ".")
    end
  end

  # If a scheme is not provided, `URI.parse` puts
  # the host info in `:path`.
  defp remove_www(url = %URI{host: host, path: path})
       when is_nil(host) and path != nil do
    %{url | host: parse_host(path), path: nil}
  end

  defp remove_www(url = %URI{host: host}),
    do: %{url | host: parse_host(host)}

  defp parse_host(host), do: host |> String.trim_leading("www.")

  defp downcase_host(url) do
    %{url | host: String.downcase(url.host)}
  end
end
