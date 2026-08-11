defmodule NormaPropertyTest do
  @moduledoc """
  Properties that pin the two assumptions 2.0 rests on but never proved by
  example: that the D7 empty-path clawback is *surgical*, and that normalization
  reaches a fixpoint in one pass.
  """
  use ExUnit.Case, async: true
  use ExUnitProperties

  # Generators build inputs from parts so the generated string is always a URL
  # Norma accepts; fuzzing raw binaries would only exercise the reject path.

  defp scheme, do: member_of(["http", "https"])

  defp label, do: string(?a..?z, min_length: 1, max_length: 6)

  defp host do
    gen all parts <- list_of(label(), min_length: 1, max_length: 3),
            tld <- member_of(["com", "net", "org", "io"]) do
      Enum.join(parts ++ [tld], ".")
    end
  end

  defp port, do: one_of([constant(nil), member_of([80, 443, 8080, 1337, 21])])

  defp segment, do: one_of([label(), member_of([".", "..", "a.b", "x%7Ey"])])

  defp path do
    one_of([
      constant(nil),
      constant("/"),
      gen all segs <- list_of(segment(), min_length: 1, max_length: 4) do
        "/" <> Enum.join(segs, "/")
      end
    ])
  end

  defp query do
    one_of([
      constant(nil),
      gen all pairs <-
                list_of(tuple({label(), label()}), min_length: 1, max_length: 4) do
        Enum.map_join(pairs, "&", fn {k, v} -> "#{k}=#{v}" end)
      end
    ])
  end

  defp fragment, do: one_of([constant(nil), label()])

  defp url do
    gen all s <- scheme(),
            h <- host(),
            p <- port(),
            pa <- path(),
            q <- query(),
            f <- fragment() do
      %URI{scheme: s, host: h, port: p, path: pa, query: q, fragment: f}
      |> URI.to_string()
    end
  end

  describe "D7 — empty-path clawback is surgical" do
    property "output differs from :uri_string.normalize/1 only by the root path" do
      check all raw <- url() do
        ours = Norma.normalize(raw)
        rfc = rfc_normalize(raw)

        # The clawback removes an added root path, which sits before any query
        # or fragment — so compare structurally, not by string suffix.
        {:ok, o} = URI.new(ours)
        {:ok, r} = URI.new(rfc)

        assert %{o | path: nil} == %{r | path: nil} and
                 (o.path == r.path or (o.path in [nil, ""] and r.path == "/")),
               """
               D7 deviated beyond the empty-path slash.
                 input: #{inspect(raw)}
                 norma: #{inspect(ours)}
                 rfc:   #{inspect(rfc)}
               """
      end
    end

    property "the deviation only ever fires when the input had no path" do
      check all raw <- url() do
        {:ok, parsed} = URI.new(raw)

        if Norma.normalize(raw) != rfc_normalize(raw) do
          assert parsed.path in [nil, ""],
                 "clawback fired on a URL that had a path: #{inspect(raw)}"
        end
      end
    end

    property "a non-empty path is never shortened away" do
      check all raw <- url() do
        {:ok, parsed} = URI.new(raw)

        if parsed.path not in [nil, ""] do
          {:ok, out} = URI.new(Norma.normalize(raw))
          assert out.path not in [nil, ""]
        end
      end
    end
  end

  describe "idempotence" do
    property "normalize/1 is a fixpoint after one pass" do
      check all raw <- url() do
        once = Norma.normalize(raw)
        assert Norma.normalize(once) == once
      end
    end

    property "idempotent under the 1.x query compatibility flag" do
      check all raw <- url() do
        opts = %{restore_old_query_behavior: true}
        once = Norma.normalize(raw, opts)
        assert Norma.normalize(once, opts) == once
      end
    end

    property "idempotent with the path-shaping options on" do
      check all raw <- url(),
                opts <-
                  member_of([
                    %{add_trailing_slash: true},
                    %{force_root_path: true},
                    %{add_root_path: true},
                    %{remove_www: true}
                  ]) do
        once = Norma.normalize(raw, opts)
        assert Norma.normalize(once, opts) == once
      end
    end
  end

  describe "invariants that must survive normalization" do
    property "scheme and host are preserved (host only up to case folding)" do
      check all raw <- url() do
        {:ok, before} = URI.new(raw)
        {:ok, out} = URI.new(Norma.normalize(raw))

        assert out.scheme == before.scheme
        assert out.host == String.downcase(before.host)
      end
    end

    property "query pairs keep their order and multiplicity" do
      check all raw <- url() do
        {:ok, before} = URI.new(raw)
        {:ok, out} = URI.new(Norma.normalize(raw))

        assert pairs(out.query) == pairs(before.query)
      end
    end
  end

  defp pairs(nil), do: []
  defp pairs(q), do: q |> URI.query_decoder() |> Enum.to_list()

  # Mirrors Utils.rfc_normalize/1 (private) so the property compares against the
  # RFC baseline rather than against Norma itself.
  defp rfc_normalize(raw) do
    case :uri_string.normalize(raw) do
      {:error, _, _} -> raw
      s when is_binary(s) -> s
      s when is_list(s) -> List.to_string(s)
    end
  end
end
