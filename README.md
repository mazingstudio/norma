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
{:norma, "~> 1.9"}
```

Documentation is on [HexDocs](https://hexdocs.pm/norma).

### Note on compatibility

Norma requires Elixir `~> 1.11` and is tested against Elixir 1.13 through 1.19.

It leans heavily on the standard library's `URI` module, whose parsing behavior has shifted
across Elixir releases. If you hit a surprising result, [the module's
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
- Ports `80`, `443`, `8080` and `21` are stripped from the output regardless of scheme.
- `force_root_path` replaces the path only; an existing query and fragment survive it.
- Query parameters are sorted alphabetically and duplicate keys are collapsed, so
  `?tag=a&tag=b` does not round-trip.
- `add_trailing_slash` reads any `.` in the path as a file extension, so `/v1.2/docs` is left
  without a slash.

These are the behaviors of the `1.x` line, pinned by the test suite as-is. They are queued to
change in `2.0`.

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
