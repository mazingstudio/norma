defmodule NormaTest do
  use ExUnit.Case
  @with_scheme "https://mazing.studio"
  @without_scheme "mazing.studio"
  @without_scheme_but_port "//mazing.studio:21"
  @with_path "https://mazing.studio/test"
  @with_fragment "https://mazing.studio#test"
  @with_www "https://www.mazing.studio"
  @full_example "//www.mazing.studio:1337/test#test"

  test "scheme defaults to `http` when not provided (nor a port)",
    do: assert Norma.normalize!(@without_scheme) == "http://mazing.studio"

  test "scheme gets infered from port",
    do: assert Norma.normalize!(@without_scheme_but_port) == "ftp://mazing.studio"

  test "force root path",
    do: assert Norma.normalize!(@with_path,
                               %{force_root_path: true}) == "https://mazing.studio/"

  test "remove fragment",
    do: assert Norma.normalize!(@with_fragment,
                               %{remove_fragment: true}) == "https://mazing.studio"

  test "remove www",
    do: assert Norma.normalize!(@with_www,
                               %{remove_www: true}) == "https://mazing.studio"

  test "remove scheme",
    do: assert Norma.normalize!(@with_scheme,
                               %{remove_scheme: true}) == "mazing.studio"

  test "full normalization",
    do: assert Norma.normalize!(@full_example,
                               %{force_root_path: true,
                                 remove_fragment: true,
                                      remove_www: true}) == "http://mazing.studio/"

end
