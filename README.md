# Norma

[![Hex.pm](https://img.shields.io/hexpm/v/norma.svg?style=flat-square)](https://hex.pm/packages/norma)
[![Hexdocs](https://img.shields.io/badge/hex-docs-purple.svg?style=flat-square)](https://hexdocs.pm/norma)
[![Downloads](https://img.shields.io/hexpm/dt/norma.svg?style=flat-square)](https://hex.pm/packages/norma)
[![License](https://img.shields.io/hexpm/l/norma.svg?style=flat-square)](https://github.com/mazingstudio/norma/blob/master/LICENSE)

Normalize URLs to the format you need.

## Installation

Add `Norma` to your list of dependencies in `mix.exs`. Tracking the latest release is
recommended:

```elixir
def deps do
  [
    {:norma, ">= 0.0.0"}
  ]
end
```

If you prefer to pin the minor line:

```elixir
{:norma, "~> 2.0"}
```

Documentation is on [HexDocs](https://hexdocs.pm/norma).

### Which version do I want?

| | `2.0` | `1.9` |
| --- | --- | --- |
| Elixir | `~> 1.13` (tested 1.13, 1.16, 1.19, 1.20) | `~> 1.11` (tested 1.13 through 1.19) |
| Output | RFC 3986 normalized | as written since 2017 |
| Docs | this file | [README at `v1.9.0`](https://github.com/mazingstudio/norma/blob/v1.9.0/README.md) · [HexDocs](https://hexdocs.pm/norma/1.9.0) |

`2.0` requires Elixir 1.13 because it uses `URI.new/1`. On an older Elixir, pin
`{:norma, "~> 1.9"}` — it is still supported and its output is unchanged from `1.x`.

**What 2.0 introduces**

- **RFC 3986 normalization by default.** Dot segments are resolved (`/a/../b` → `/b`), the
  host is lowercased, percent-encoding is normalized, and a port is dropped only when it is
  the scheme's default. `8080` now survives; `http://…:443` keeps its port.
- **Query strings keep input order and duplicate keys.** `?tag=a&tag=b` round-trips instead
  of being sorted and de-duplicated. `restore_old_query_behavior: true` brings `1.x` back.
- **`force_root_path` now clears query and fragment too** ([#7](https://github.com/mazingstudio/norma/issues/7)),
  and a new `add_root_path` slashes only an empty path.
- **`add_trailing_slash` looks at the final path segment only**, so `/v1.2/docs` gets its slash.
- **`downcase_host` was removed** — RFC normalization lowercases the host unconditionally,
  so the option could no longer be honored.

Full list with before/after strings: [Migrating to 2.0](docs/migrating-to-2.0.md) and the
[CHANGELOG](CHANGELOG.md).

### Upgrading from 1.x in five minutes

Most upgrades are a no-op. Work down this list; if none of the symptoms apply to your
code, `{:norma, "~> 2.0"}` is a drop-in.

| If you… | You'll see | Do this |
| --- | --- | --- |
| store or compare normalized URLs | stored `1.x` strings no longer equal fresh output | re-normalize the column once, or compare through `Norma.normalize/1` on both sides |
| pass `downcase_host:` | `KeyError`-free but silently ignored; the option is gone | delete it — the host is always lowercased now |
| rely on `:8080` being stripped | the port survives | strip it yourself, or use the scheme's default port |
| compare query strings byte-for-byte | pairs keep input order and duplicates | pass `%{restore_old_query_behavior: true}` to get `1.x` sorting back |
| use `force_root_path` | query and fragment are now cleared too | use `add_root_path` if you only wanted a `/` on empty paths |
| have paths with a dot in a middle segment (`/v1.2/docs`) | `add_trailing_slash` now applies | nothing, unless you depended on the old miss |
| run Elixir < 1.13 | won't compile | stay on `{:norma, "~> 1.9"}` |

Two things that did **not** change, both machine-checked by the test suite: a URL with no
path stays pathless (`http://example.com`, not `.../`), and `normalize/2` is idempotent —
normalizing an already-normalized URL returns it unchanged.

### Note on compatibility

Norma leans heavily on the standard library's `URI` module, whose parsing behavior has
shifted across Elixir releases. If you hit a surprising result, [the module's
history](https://github.com/elixir-lang/elixir/commits/main/lib/elixir/lib/uri.ex) is usually
the fastest explanation.

## Usage

Two public functions. Both take a URL string and an optional map of options.

| Function | Returns |
| --- | --- |
| `Norma.normalize(url, opts \\ %{})` | `String.t()`; input it cannot parse as a URL is returned unchanged |
| `Norma.normalize_if_valid(url, opts \\ %{})` | `{:ok, String.t()}` or `{:error, "Not an URL."}` |

```elixir
iex> Norma.normalize("example.com")
"http://example.com"

iex> Norma.normalize_if_valid("example.com")
{:ok, "http://example.com"}

iex> Norma.normalize_if_valid("example")
{:error, "Not an URL."}
```

Use `normalize_if_valid/2` when the input is untrusted — user submissions, scraped text,
model output. Use `normalize/2` only when the value is already known to be a URL.

Options are a map. Every key defaults to `false`, and any subset may be combined.

| Option | Effect |
| --- | --- |
| `remove_scheme: true` | Drops `http://` / `https://` from the output |
| `remove_fragment: true` | Drops everything from `#` onward |
| `remove_www: true` | Drops a leading `www.` from the host |
| `add_trailing_slash: true` | Appends `/` to the path when the final segment is not file-like |
| `force_root_path: true` | Replaces the path with `/` and clears query + fragment |
| `add_root_path: true` | Sets path to `/` only when path is empty |
| `restore_old_query_behavior: true` | 1.x query sort + last-wins dedupe |

Host case is always lowercased (RFC 3986 normalize). The 1.x `downcase_host`
option was removed in 2.0 — see [Migrating to 2.0](docs/migrating-to-2.0.md).

```elixir
iex> Norma.normalize("https://example.com", %{remove_scheme: true})
"example.com"

iex> Norma.normalize("https://example.com#faqs", %{remove_fragment: true})
"https://example.com"

iex> Norma.normalize("https://www.example.com", %{remove_www: true})
"https://example.com"

iex> Norma.normalize("https://EXAMPLE.COM/FAQS")
"https://example.com/FAQS"

iex> Norma.normalize("https://example.com/docs", %{add_trailing_slash: true})
"https://example.com/docs/"

iex> Norma.normalize("https://example.com/docs", %{force_root_path: true})
"https://example.com/"

iex> Norma.normalize("//www.example.com:1337/test#test",
...>   %{remove_fragment: true, force_root_path: true, remove_www: true})
"http://example.com:1337/"
```

### Behavior worth knowing before you rely on it

- A scheme-less input is assumed to be `http`. Norma never upgrades to `https`.
- Output is RFC 3986 normalized: dot segments are resolved (`/a/../b` → `/b`), the host is
  lowercased, percent-encoding is normalized, and the port is dropped only when it is the
  scheme's default (`https://…:443` loses it, `http://…:443` keeps it). `8080` is never
  stripped.
- Query parameters keep their input order and duplicate keys, so `?tag=a&tag=b` round-trips.
  Pass `restore_old_query_behavior: true` for the 1.x sort-and-dedupe.
- `force_root_path` replaces the path **and** clears query and fragment.
- `add_trailing_slash` looks for a `.` in the final path segment only, so `/v1.2/docs` gets
  its slash.
- An input with no path stays pathless (`http://example.com`, not `http://example.com/`),
  a deliberate deviation from RFC 3986 §6.2.3 that keeps `add_trailing_slash`,
  `add_root_path` and `force_root_path` meaningful.

Every behavior above is pinned by the golden suite. See
[Migrating to 2.0](docs/migrating-to-2.0.md) for what changed since `1.x`.

### With Ecto

```elixir
def creation_changeset(params) do
  norma_options = %{
    remove_www: true,
    force_root_path: true,
    remove_fragment: true
  }

  %MyEntity{}
  |> cast(params, @fields)
  |> put_change(:url, Norma.normalize(params.url, norma_options))
end
```

## Contributing

### Adding options

1. Add support for the option in `/lib/norma/normalizer.ex`. Prefer pattern matching and
   guards over `if`s and `case`s.
2. Add a test in `/test/norma_test.exs`.
3. Add documentation to the `README`.
4. Send a PR 🎉

### Maintainers

- [Zura Guerra](https://github.com/ZuraGuerra)

---

## A Mazing project (Studio Closed!)

Originally sponsored by _Mazing Studio_.
