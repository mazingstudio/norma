defmodule NormaParseTest do
  @moduledoc """
  Characterization of the D5 parse path: `URI.new/1` + a single `//`-prefix
  authority-hint branch (no `safe_parse`/`has_valid_host?` mutual recursion).

  Asserts that currently-passing scheme-less and host:port inputs remain
  byte-identical under `Norma.normalize/2` / `normalize_if_valid/2`.
  """
  use ExUnit.Case, async: true

  describe "URI.new-based parse (scheme-less / host:port)" do
    test "bare host defaults to http" do
      assert Norma.normalize("example.com") == "http://example.com"
      assert Norma.normalize_if_valid("example.com") == {:ok, "http://example.com"}
    end

    test "host with path, no scheme" do
      assert Norma.normalize("mazing.studio/test") == "http://mazing.studio/test"
    end

    test "host:port with no scheme is not swallowed as a scheme" do
      # URI.new("mazing.studio:80") alone would set scheme="mazing.studio", host=nil.
      # The //-prefix branch recovers host/port.
      assert Norma.normalize("mazing.studio:80") == "http://mazing.studio"
      assert Norma.normalize("mazing.studio:21") == "ftp://mazing.studio"
      assert Norma.normalize("mazing.studio:1337") == "http://mazing.studio:1337"
      assert Norma.normalize("mazing.studio:1337/test") == "http://mazing.studio:1337/test"
      assert Norma.normalize("example.com:3000") == "http://example.com:3000"
      assert Norma.normalize("example.com:443") == "https://example.com"
    end

    test "scheme-relative // inputs keep working" do
      assert Norma.normalize("//example.com") == "http://example.com"

      assert Norma.normalize("//www.mazing.studio:1337/test#test") ==
               "http://www.mazing.studio:1337/test#test"

      assert Norma.normalize("//example.com:443") == "https://example.com"
      assert Norma.normalize("//example.com:80") == "http://example.com"
    end

    test "explicit schemes are unchanged by the authority-hint branch" do
      assert Norma.normalize("https://mazing.studio") == "https://mazing.studio"
      assert Norma.normalize("http://example.com:3000/dir") == "http://example.com:3000/dir"
      assert Norma.normalize("ftp://example.com") == "ftp://example.com"
    end
  end

  describe "non-URL rejection still short-circuits before parse" do
    test "strings without a dot are rejected" do
      assert Norma.normalize_if_valid("example") == {:error, "Not an URL."}
      assert Norma.normalize("example") == "example"
    end

    test "mailto and javascript are left unchanged by normalize/2" do
      assert Norma.normalize("mailto:joe@example.com") == "mailto:joe@example.com"
      assert Norma.normalize("javascript:alert('hey')") == "javascript:alert('hey')"
    end
  end

  describe "parse path does not recurse" do
    # Private functions can't be unit-tested directly; we pin the public
    # surface and document that a single //-retry replaces mutual recursion.
    # A hang here would fail the suite (ExUnit default timeout).
    test "host-less rebuild does not loop on odd scheme-like input that still passes valid_url?" do
      # Contains a dot so valid_url?/1 is true; first parse has host nil.
      assert is_binary(Norma.normalize("a.b:9999"))
      assert Norma.normalize_if_valid("a.b:9999") == {:ok, "http://a.b:9999"}
    end
  end

  describe "URI.new rejection fallback (raw non-ASCII query)" do
    # URI.new/1 rejects unescaped non-ASCII; URI.parse/1 accepted it.
    # Fallback keeps 1.x golden output (percent-encoded via form_query).
    test "raw n-tilde in query still normalizes" do
      input = "http://example.com?dogs_allowed=" <> <<0xC3, 0xB1>> <> "o"
      assert Norma.normalize(input) == "http://example.com?dogs_allowed=%C3%B1o"
    end

    test "raw e-acute in query still normalizes" do
      input = "http://example.com?q=caf" <> <<0xC3, 0xA9>>
      assert Norma.normalize(input) == "http://example.com?q=caf%C3%A9"
    end
  end
end
