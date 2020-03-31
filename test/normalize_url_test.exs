defmodule NormalizeUrlTest do
  use ExUnit.Case

  test "adds a protocol by default" do
    assert(Norma.normalize("example.com") == "http://example.com")
    assert(Norma.normalize("example.com/dir") == "http://example.com/dir")
    assert(Norma.normalize("example.com:3000") == "http://example.com:3000")
    assert(Norma.normalize("example.com:3000/dir") == "http://example.com:3000/dir")
  end

  test "keeps the http protocol" do
    assert(Norma.normalize("http://example.com") == "http://example.com")
  end

  test "keeps the https protocol" do
    assert(Norma.normalize("https://example.com") == "https://example.com")
  end

  test "keeps the mailto protocol" do
    assert(Norma.normalize("mailto:joe@example.com") == "mailto:joe@example.com")
  end

  test "keeps the javascript protocol" do
    assert(Norma.normalize("javascript:alert('hey')") == "javascript:alert('hey')")
  end

  test "handles ftp protocols" do
    assert(Norma.normalize("ftp://example.com") == "ftp://example.com")
  end

  @tag :skip
  test "handles ftp protocols with fragments" do
    assert(Norma.normalize("ftp://example.com#blah") == "ftp://example.com")
  end

  test "handles a url that starts with ftp" do
    assert(Norma.normalize("ftp.com") == "http://ftp.com")
  end

  test "strips a relative protocol and replaces with http" do
    assert(Norma.normalize("//example.com") == "http://example.com")
  end

  test "adds the correct protocol if 443 is specified" do
    assert(Norma.normalize("//example.com:443") == "https://example.com")
  end

  test "adds the correct protocol if 80 is specified" do
    assert(Norma.normalize("//example.com:80") == "http://example.com")
  end

  test "adds the correct protocol if 8080 is specified" do
    assert(Norma.normalize("//example.com:8080") == "http://example.com")
  end

  test "sorts query params" do
    assert(
      Norma.normalize("example.com?b=foo&a=bar&123=hi") == "http://example.com?123=hi&a=bar&b=foo"
    )
  end

  test "encodes back query params" do
    assert(
      Norma.normalize("example.com?b=foo's+bar&a=joe+smith") ==
        "http://example.com?a=joe+smith&b=foo%27s+bar"
    )
  end

  test "keeps www by default" do
    assert(Norma.normalize("www.example.com") == "http://www.example.com")
  end

  test "keeps www with option remove_www: false" do
    assert(Norma.normalize("www.example.com", %{remove_www: false}) == "http://www.example.com")
  end

  test "removes www with option remove_www: true" do
    assert(Norma.normalize("www.example.com", %{remove_www: true}) == "http://example.com")
  end

  @tag :skip
  test "does not strip a relative protocol with option normalize_protocol: false" do
    assert(Norma.normalize("//example.com", %{normalize_protocol: false}) == "//example.com")
  end

  test "does not remove fragment with option remove_fragment: false" do
    assert(
      Norma.normalize("example.com#about", %{remove_fragment: false}) ==
        "http://example.com#about"
    )
  end

  test "removes fragment with option remove_fragment: true" do
    assert(
      Norma.normalize("example.com#about", %{remove_fragment: true}) ==
        "http://example.com"
    )
  end

  test "keeps fragment by default" do
    assert(
      Norma.normalize("example.com#about") ==
        "http://example.com#about"
    )
  end

  test "adds root path if enabled and needed" do
    assert(
      Norma.normalize("http://example.com", %{force_root_path: true}) == "http://example.com/"
    )
  end

  test "handles URLs with port" do
    assert Norma.normalize("http://example.com:3000") == "http://example.com:3000"
    assert Norma.normalize("https://example.com:3000") == "https://example.com:3000"
    assert Norma.normalize("https://example.com:3000/dir") == "https://example.com:3000/dir"
    assert Norma.normalize("example.com:3000") == "http://example.com:3000"
    assert Norma.normalize("example.com:3000/dir") == "http://example.com:3000/dir"
  end

  # Temporary patch, proper downcasing should only affect the host, not change the path, the protocol should always be downcase
  describe "downcasing" do
    test "does not downcase by default" do
      assert(
        Norma.normalize("HTTP://EXAMPLE.COM/Path/With/Upcase") ==
          "http://EXAMPLE.COM/Path/With/Upcase"
      )
    end

    @tag :skip
    test "downcase if explicitly activated" do
      assert(
        Norma.normalize("HTTP://EXAMPLE.COM/Path/With/Upcase", %{downcase: true}) ==
          "http://example.com/path/with/upcase"
      )
    end
  end
end
