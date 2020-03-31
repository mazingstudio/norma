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
  @upcase "HTTP://EXAMPLE.COM/DIR?PAGE=2"

  describe "normalize_if_valid" do
    test "returns the normalized URL",
      do: assert(Norma.normalize_if_valid("example.com") == {:ok, "http://example.com"})

    test "returns error if the URL is invalid",
      do: assert(Norma.normalize_if_valid("example") == {:error, "Not an URL."})
  end

  describe "normalize" do
    test "returns the normalized URL",
      do: assert(Norma.normalize("example.com") == "http://example.com")

    test "full normalization",
      do:
        assert(
          Norma.normalize(
            @full_example,
            %{force_root_path: true, remove_fragment: true, remove_www: true}
          ) == "http://mazing.studio:1337/"
        )
  end

  describe "scheme" do
    test "scheme defaults to `http` when not provided (nor a port)" do
      assert Norma.normalize(@without_scheme) == "http://mazing.studio"
      assert Norma.normalize(@without_scheme_but_path) == "http://mazing.studio/test"
      assert Norma.normalize(@without_scheme_but_port_alt) == "http://mazing.studio:1337"

      assert Norma.normalize(@without_scheme_but_port_and_path) ==
               "http://mazing.studio:1337/test"
    end

    test "scheme gets infered from port",
      do: assert(Norma.normalize(@without_scheme_but_port) == "ftp://mazing.studio")

    test "adds a scheme by default" do
      assert(Norma.normalize("example.com") == "http://example.com")
      assert(Norma.normalize("example.com/dir") == "http://example.com/dir")
      assert(Norma.normalize("example.com:3000") == "http://example.com:3000")
      assert(Norma.normalize("example.com:3000/dir") == "http://example.com:3000/dir")
    end

    test "keeps the http scheme" do
      assert(Norma.normalize("http://example.com") == "http://example.com")
    end

    test "keeps the https scheme" do
      assert(Norma.normalize("https://example.com") == "https://example.com")
    end

    test "keeps the mailto scheme" do
      assert(Norma.normalize("mailto:joe@example.com") == "mailto:joe@example.com")
    end

    test "keeps the javascript scheme" do
      assert(Norma.normalize("javascript:alert('hey')") == "javascript:alert('hey')")
    end

    test "keeps the ftp scheme" do
      assert(Norma.normalize("ftp://example.com") == "ftp://example.com")
    end

    test "explicitly remove scheme",
      do:
        assert(
          Norma.normalize(
            @with_scheme,
            %{remove_scheme: true}
          ) == "mazing.studio"
        )
  end

  describe "fragment" do
    test "keeps fragment by default" do
      assert(
        Norma.normalize("example.com#about") ==
          "http://example.com#about"
      )
    end

    test "explicitly remove fragment",
      do:
        assert(
          Norma.normalize(
            @with_fragment,
            %{remove_fragment: true}
          ) == "https://mazing.studio"
        )

    test "does not remove fragment with option remove_fragment: false" do
      assert(
        Norma.normalize("example.com#about", %{remove_fragment: false}) ==
          "http://example.com#about"
      )
    end
  end

  describe "root path" do
    test "doesn't add root path by default" do
      assert(Norma.normalize("http://example.com") == "http://example.com")
    end

    test "force root path",
      do:
        assert(
          Norma.normalize(
            @with_path,
            %{force_root_path: true}
          ) == "https://mazing.studio/"
        )
  end

  describe "www" do
    test "keeps www by default" do
      assert(Norma.normalize(@with_www) == "https://www.mazing.studio")
    end

    test "keeps www with option remove_www: false" do
      assert(Norma.normalize(@with_www, %{remove_www: false}) == @with_www)
    end

    test "removes www with option remove_www: true" do
      assert(Norma.normalize(@with_www, %{remove_www: true}) == "https://mazing.studio")
    end
  end

  describe "port" do
    test "adds the correct protocol if 443 is specified" do
      assert(Norma.normalize("//example.com:443") == "https://example.com")
    end

    test "adds the correct protocol if 80 is specified" do
      assert(Norma.normalize("//example.com:80") == "http://example.com")
    end

    test "adds the correct protocol if 8080 is specified" do
      assert(Norma.normalize("//example.com:8080") == "http://example.com")
    end

    test "handles URLs with port" do
      assert Norma.normalize("http://example.com:3000") == "http://example.com:3000"
      assert Norma.normalize("https://example.com:3000") == "https://example.com:3000"
      assert Norma.normalize("https://example.com:3000/dir") == "https://example.com:3000/dir"
      assert Norma.normalize("example.com:3000") == "http://example.com:3000"
      assert Norma.normalize("example.com:3000/dir") == "http://example.com:3000/dir"
    end
  end

  describe "query params" do
    test "sorts query params" do
      assert(
        Norma.normalize("example.com?b=foo&a=bar&123=hi") ==
          "http://example.com?123=hi&a=bar&b=foo"
      )
    end

    test "puts the fragment before the query params" do
      assert(
        Norma.normalize("example.com?b=foo&a=bar&123=hi#top") ==
          "http://example.com#top?123=hi&a=bar&b=foo"
      )
    end

    test "encodes back query params" do
      assert(
        Norma.normalize("example.com?b=foo's+bar&a=joe+smith") ==
          "http://example.com?a=joe+smith&b=foo%27s+bar"
      )
    end
  end

  describe "relative protocol" do
    test "strips a relative protocol and replaces with http" do
      assert(Norma.normalize("//example.com") == "http://example.com")
    end
  end

  describe "downcase_host" do
    test "does not downcase host by default" do
      assert Norma.normalize(@upcase) == "http://EXAMPLE.COM/DIR?PAGE=2"
    end

    test "does not downcase host with downcase_host: false" do
      assert Norma.normalize(@upcase, %{downcase_host: false}) == "http://EXAMPLE.COM/DIR?PAGE=2"
    end

    test "downcases host with downcase_host: true" do
      assert Norma.normalize(@upcase, %{downcase_host: true}) == "http://example.com/DIR?PAGE=2"
    end
  end
end
