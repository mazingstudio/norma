defmodule NormaRfcTest do
  use ExUnit.Case, async: true

  alias Norma.Utils

  describe "form_url/1 RFC 3986 via :uri_string.normalize" do
    test "removes dot segments in the path" do
      assert form("http://example.com/a/./b/../c") == "http://example.com/a/c"
      assert form("http://example.com/a/b/c/./../../g") == "http://example.com/a/g"
      assert form("http://example.com/mid/content=5/../6") == "http://example.com/mid/6"
    end

    test "folds host case (and scheme case)" do
      assert form("http://EXAMPLE.com/path") == "http://example.com/path"
      assert form("HTTP://EXAMPLE.COM/DIR") == "http://example.com/DIR"
    end

    test "normalizes percent-encoding (%7E -> ~, hex digits uppercased for reserved)" do
      assert form("http://example.com/%7Euser") == "http://example.com/~user"
      assert form("http://example.com/%7euser") == "http://example.com/~user"
      assert form("http://example.com/foo%2fbar") == "http://example.com/foo%2Fbar"
    end

    test "omits scheme-default ports and keeps non-default ports" do
      assert form("http://example.com:80/path") == "http://example.com/path"
      assert form("https://example.com:443/path") == "https://example.com/path"
      assert form("ftp://example.com:21/path") == "ftp://example.com/path"

      # Non-default for the scheme — must survive (including 8080)
      assert form("http://example.com:443/path") == "http://example.com:443/path"
      assert form("https://example.com:80/path") == "https://example.com:80/path"
      assert form("http://example.com:8080/path") == "http://example.com:8080/path"
      assert form("http://example.com:21/path") == "http://example.com:21/path"
      assert form("http://example.com:3000/path") == "http://example.com:3000/path"
    end

    test "8080 survives end-to-end through Norma.normalize/1" do
      assert Norma.normalize("http://example.com:8080") == "http://example.com:8080"
      assert Norma.normalize("//example.com:8080") == "http://example.com:8080"
      assert Norma.normalize("example.com:8080") == "http://example.com:8080"
    end

    test "dot segments and host fold through Norma.normalize/1" do
      assert Norma.normalize("http://EXAMPLE.com/a/./b/../c") == "http://example.com/a/c"
      assert Norma.normalize("HTTP://EXAMPLE.COM/%7Euser") == "http://example.com/~user"
    end

    test "falls back to the pre-normalization string when :uri_string.normalize errors" do
      # URI.to_string accepts a host with a space; :uri_string.normalize does not.
      uri = %URI{
        scheme: "http",
        host: "exa mple.com",
        path: "/ok",
        port: 80,
        authority: nil,
        userinfo: nil,
        query: nil,
        fragment: nil
      }

      pre = URI.to_string(%{uri | authority: nil, userinfo: nil})
      assert match?({:error, _, _}, :uri_string.normalize(pre))
      assert Utils.form_url(uri) == pre
    end

    test "discards userinfo before normalize" do
      uri = URI.parse("http://user:pass@example.com:8080/path")
      assert Utils.form_url(uri) == "http://example.com:8080/path"
    end

    # D7 = option B: RFC 3986 §6.2.3 would normalize an empty path to "/",
    # but Norma strips it back so the path-shaping options stay meaningful.
    test "empty path stays empty (deliberate deviation from RFC 3986 6.2.3)" do
      assert form("http://example.com") == "http://example.com"
      assert form("https://example.com") == "https://example.com"
      assert form("http://example.com?a=1") == "http://example.com?a=1"
      assert form("http://example.com#frag") == "http://example.com#frag"
      assert Norma.normalize("example.com") == "http://example.com"
    end

    test "an explicit root path is still preserved" do
      assert form("http://example.com/") == "http://example.com/"
      assert Norma.normalize("example.com", %{add_trailing_slash: true}) == "http://example.com/"
      assert Norma.normalize("example.com/a/b", %{force_root_path: true}) == "http://example.com/"
    end
  end

  defp form(url) when is_binary(url), do: url |> URI.parse() |> Utils.form_url()
end
