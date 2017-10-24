defmodule NormalizeUrlTest do
  use ExUnit.Case

  test "adds a protocol by default" do
    assert(Norma.normalize("example.com")          == "http://example.com")
    assert(Norma.normalize("example.com/dir")      == "http://example.com/dir")
    assert(Norma.normalize("example.com:3000")     == "http://example.com:3000")
    assert(Norma.normalize("example.com:3000/dir") == "http://example.com:3000/dir")
  end

  test "keeps the http protocol" do
    assert(Norma.normalize("http://google.com") == "http://google.com")
  end

  test "keeps the https protocol" do
    assert(Norma.normalize("https://google.com") == "https://google.com")
  end

  test "keeps the mailto protocol" do
    assert(Norma.normalize("mailto:joe@example.com") == "mailto:joe@example.com")
  end

  test "keeps the javascript protocol" do
    assert(Norma.normalize("javascript:alert('hey')") == "javascript:alert('hey')")
  end

  test "handles ftp protocols" do
    assert(Norma.normalize("ftp://google.com") == "ftp://google.com")
  end

  test "handles ftp protocols with fragments" do
    assert(Norma.normalize("ftp://google.com#blah") == "ftp://google.com")
  end

  test "handles a url that starts with ftp" do
    assert(Norma.normalize("ftp.com") == "http://ftp.com")
  end

  test "strips a relative protocol and replaces with http" do
    assert(Norma.normalize("//google.com") == "http://google.com")
  end

  test "adds the correct protocol if 8080 is specified" do
    assert(Norma.normalize("//google.com:8080") == "https://google.com")
  end

  test "adds the correct protocol if 80 is specified" do
    assert(Norma.normalize("//google.com:80") == "http://google.com")
  end

  test "sorts query params" do
    assert(Norma.normalize("google.com?b=foo&a=bar&123=hi") == "http://google.com?123=hi&a=bar&b=foo")
  end

  test "encodes back query params" do
    assert(Norma.normalize("google.com?b=foo's+bar&a=joe+smith") == "http://google.com?a=joe+smith&b=foo%27s+bar")
  end

  test "strips url fragment" do
    assert(Norma.normalize("johnotander.com#about") == "http://johnotander.com")
  end

  test "strips www" do
    assert(Norma.normalize("www.johnotander.com") == "http://johnotander.com")
  end

  test "does not strip a relative protocol with option normalize_protocol: false" do
    assert(Norma.normalize("//google.com", [normalize_protocol: false]) == "//google.com")
  end

  test "does not strip www with option strip_www: false" do
    assert(Norma.normalize("www.google.com", [strip_www: false]) == "http://www.google.com")
  end

  test "does not strip a url fragment with option strip_fragment: false" do
    assert(Norma.normalize("www.google.com#about.html", [strip_fragment: false]) == "http://google.com#about.html")
  end

  test "adds root path if enabled and needed" do
    assert(Norma.normalize("http://google.com", [add_root_path: true]) == "http://google.com/")
  end

  test "handles URLs with port" do
    assert Norma.normalize("http://example.com:3000")      == "http://example.com:3000"
    assert Norma.normalize("https://example.com:3000")     == "https://example.com:3000"
    assert Norma.normalize("https://example.com:3000/dir") == "https://example.com:3000/dir"
    assert Norma.normalize("example.com:3000")             == "http://example.com:3000"
    assert Norma.normalize("example.com:3000/dir")         == "http://example.com:3000/dir"
  end

  # Temporary patch, proper downcasing should only affect the host, not change the path, the protocol should always be downcase
  describe "downcasing" do
    test "does not downcase by default" do
      assert(Norma.normalize("http://example.com/Path/With/Upcase") == "http://example.com/Path/With/Upcase")
    end

    test "downcase if explicitly activated" do
      assert(Norma.normalize("http://example.com/Path/With/Upcase", [downcase: true]) == "http://example.com/path/with/upcase")
    end
  end
end
