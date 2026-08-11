defmodule Norma.Normalizer2_0Test do
  use ExUnit.Case, async: true

  # D3 + D4 characterization for the 2.0 normalizer semantics.
  # Does not touch the 1.x suite (norma_test.exs) or golden suite.

  describe "D3 add_trailing_slash — final segment only" do
    test "adds slash to undotted directory paths" do
      assert Norma.normalize("http://example.com/docs", %{add_trailing_slash: true}) ==
               "http://example.com/docs/"
    end

    test "adds slash when an intermediate segment is dotted (versioned path)" do
      assert Norma.normalize("http://example.com/v1.2/docs", %{add_trailing_slash: true}) ==
               "http://example.com/v1.2/docs/"
    end

    test "adds slash when a dotted API prefix is not the final segment" do
      assert Norma.normalize("http://example.com/api.v2/users", %{add_trailing_slash: true}) ==
               "http://example.com/api.v2/users/"
    end

    test "skips when the final segment contains a dot (file-like)" do
      assert Norma.normalize("http://example.com/sitemap.xml", %{add_trailing_slash: true}) ==
               "http://example.com/sitemap.xml"

      assert Norma.normalize("http://example.com/v1.2/readme.md", %{add_trailing_slash: true}) ==
               "http://example.com/v1.2/readme.md"
    end

    test "does not double an existing trailing slash" do
      assert Norma.normalize("http://example.com/docs/", %{add_trailing_slash: true}) ==
               "http://example.com/docs/"
    end

    test "bare host becomes root slash" do
      assert Norma.normalize("http://example.com", %{add_trailing_slash: true}) ==
               "http://example.com/"
    end
  end

  describe "D4 force_root_path — wipe path, query, and fragment" do
    test "replaces path with / and drops query and fragment" do
      assert Norma.normalize("example.com/some/dir?page=2#faqs", %{force_root_path: true}) ==
               "http://example.com/"
    end

    test "wipes query even when path is already /" do
      assert Norma.normalize("http://example.com/?page=2", %{force_root_path: true}) ==
               "http://example.com/"
    end

    test "wipes fragment even when path is already /" do
      assert Norma.normalize("http://example.com/#faqs", %{force_root_path: true}) ==
               "http://example.com/"
    end

    test "path-only force still sets root" do
      assert Norma.normalize("https://mazing.studio/test", %{force_root_path: true}) ==
               "https://mazing.studio/"
    end
  end

  describe "D4 add_root_path — additive empty-path only" do
    test "sets path to / when path is empty" do
      assert Norma.normalize("http://example.com", %{add_root_path: true}) ==
               "http://example.com/"
    end

    test "leaves non-empty paths untouched" do
      assert Norma.normalize("http://example.com/some/dir", %{add_root_path: true}) ==
               "http://example.com/some/dir"
    end

    test "does not wipe query or fragment" do
      assert Norma.normalize("http://example.com?page=2#faqs", %{add_root_path: true}) ==
               "http://example.com/?page=2#faqs"
    end

    test "does not alter non-empty path with query" do
      assert Norma.normalize("http://example.com/dir?page=2", %{add_root_path: true}) ==
               "http://example.com/dir?page=2"
    end

    test "is weaker than force_root_path when both are set" do
      assert Norma.normalize("http://example.com/dir?page=2#x", %{
               force_root_path: true,
               add_root_path: true
             }) == "http://example.com/"
    end
  end
end
