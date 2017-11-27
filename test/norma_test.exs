defmodule NormaTest do
  use ExUnit.Case

  @with_scheme "https://mazing.studio"
  @without_scheme "mazing.studio"
  @without_scheme_but_path "mazing.studio/test"
  @without_scheme_but_port "mazing.studio:21"
  @without_scheme_but_port_alt "mazing.studio:1337"
  @without_scheme_but_port_and_path "mazing.studio:1337/test"
  @with_path "https://mazing.studio/test"
  @with_fragment "https://mazing.studio#test"
  @with_www "https://www.mazing.studio"
  @full_example "//www.mazing.studio:1337/test#test"

  test "scheme defaults to `http` when not provided (nor a port)" do
    assert Norma.normalize!(@without_scheme) == "http://mazing.studio"
    assert Norma.normalize!(@without_scheme_but_path) == "http://mazing.studio/test"
    assert Norma.normalize!(@without_scheme_but_port_alt) == "http://mazing.studio:1337"
    assert Norma.normalize!(@without_scheme_but_port_and_path) == "http://mazing.studio:1337/test"
  end

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
                                      remove_www: true}) == "http://mazing.studio:1337/"

end
