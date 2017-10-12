defmodule Norma do
  alias Norma.{Normalizer}
  @moduledoc """
  Documentation for Norma.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Norma.hello
      :world

  """

  def normalize(url, options \\ %{}) do
    url
    |> URI.parse
    |> Normalizer.normalize(options)
  end
end
