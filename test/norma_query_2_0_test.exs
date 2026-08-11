defmodule NormaQuery20Test do
  use ExUnit.Case, async: true

  alias Norma.Utils

  describe "query pairs: input order + duplicates (2.0 default)" do
    test "preserves query key order through Norma.normalize/1" do
      assert Norma.normalize("http://example.com?m=1&c=2&a=3") ==
               "http://example.com?m=1&c=2&a=3"

      assert Norma.normalize("http://example.com?b=2&a=1") == "http://example.com?b=2&a=1"
    end

    test "preserves duplicate keys (multi-value params)" do
      assert Norma.normalize("http://example.com?z=1&a=2&z=3&b=4") ==
               "http://example.com?z=1&a=2&z=3&b=4"

      assert Norma.normalize("http://example.com?tag=a&tag=b&tag=c") ==
               "http://example.com?tag=a&tag=b&tag=c"
    end

    test "still percent-encodes query values via encode_query" do
      assert Norma.normalize("http://example.com?b=foo's+bar&a=joe+smith") ==
               "http://example.com?b=foo%27s+bar&a=joe+smith"
    end

    test "empty and nil query stay empty/nil-shaped" do
      assert form("http://example.com?") == "http://example.com?"
      assert form("http://example.com") == "http://example.com"
    end

    test "fragment stays after query; order of pairs intact" do
      assert Norma.normalize("http://example.com?b=2&a=1#top") ==
               "http://example.com?b=2&a=1#top"
    end
  end

  describe "restore_old_query_behavior: true (1.x sort + dedupe)" do
    test "sorts keys and collapses duplicates (last wins)" do
      uri = URI.parse("http://example.com?z=1&a=2&z=3&b=4")

      assert Utils.form_url(uri, %{restore_old_query_behavior: true}) ==
               "http://example.com?a=2&b=4&z=3"
    end

    test "alphabetizes multi-key queries like 1.x" do
      uri = URI.parse("http://example.com?m=1&c=2&a=3")

      assert Utils.form_url(uri, %{restore_old_query_behavior: true}) ==
               "http://example.com?a=3&c=2&m=1"
    end

    test "duplicate tags collapse to last value" do
      uri = URI.parse("http://example.com?tag=a&tag=b&tag=c")

      assert Utils.form_url(uri, %{restore_old_query_behavior: true}) ==
               "http://example.com?tag=c"
    end
  end

  describe "RFC normalize does not reorder or dedupe query pairs" do
    test ":uri_string.normalize keeps pair order and duplicates on a raw string" do
      with_dups = "http://example.com?z=1&a=2&z=3&b=4"
      ordered = "http://example.com?m=1&c=2&a=3"

      # Normalize may insert "/" for empty path; query tail must be intact.
      assert query_of(normalize_string!(with_dups)) == "z=1&a=2&z=3&b=4"
      assert query_of(normalize_string!(ordered)) == "m=1&c=2&a=3"
    end

    test "form_url/1 keeps order and dups after the final :uri_string.normalize step" do
      assert form("http://example.com?z=1&a=2&z=3&b=4") ==
               "http://example.com?z=1&a=2&z=3&b=4"

      assert form("http://example.com?m=1&c=2&a=3") == "http://example.com?m=1&c=2&a=3"

      assert form("http://EXAMPLE.com?tag=a&tag=b&m=1") ==
               "http://example.com?tag=a&tag=b&m=1"
    end

    test "host fold / percent normalize do not disturb query pairs" do
      assert form("HTTP://EXAMPLE.COM/%7Euser?b=2&a=1&b=3") ==
               "http://example.com/~user?b=2&a=1&b=3"
    end
  end

  defp form(url) when is_binary(url), do: url |> URI.parse() |> Utils.form_url()

  defp normalize_string!(url) do
    case :uri_string.normalize(url) do
      {:error, _, _} = err -> flunk("unexpected normalize error: #{inspect(err)}")
      n when is_binary(n) -> n
      n when is_list(n) -> List.to_string(n)
    end
  end

  defp query_of(url) do
    case URI.new(url) do
      {:ok, %URI{query: q}} -> q
      other -> flunk("URI.new failed: #{inspect(other)}")
    end
  end
end
