defmodule NormalizeUrlTest do
  use ExUnit.Case

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
