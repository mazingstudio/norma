# Norma

[![Hex.pm](https://img.shields.io/hexpm/v/norma.svg?style=flat-square)](https://hex.pm/packages/norma)
[![Hexdocs](https://img.shields.io/badge/hex-docs-purple.svg?style=flat-square)](https://hexdocs.pm/norma)
[![Downloads](https://img.shields.io/hexpm/dt/norma.svg?style=flat-square)](https://hex.pm/packages/norma)
[![License](https://img.shields.io/hexpm/l/norma.svg?style=flat-square)](https://github.com/mazingstudio/norma/blob/master/LICENSE)
[![CI](https://img.shields.io/github/actions/workflow/status/mazingstudio/norma/ci.yml?branch=master&style=flat-square)](https://github.com/mazingstudio/norma/actions)

Normalize URLs to the format you need.

## Installation

Add `Norma` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:norma, "~> 1.9"}
  ]
end
```

Documentation is on [HexDocs](https://hexdocs.pm/norma).

### Note on compatibility

Norma requires Elixir `~> 1.11` and is tested against Elixir 1.13 through 1.19.

It leans heavily on the standard library's `URI` module, whose parsing behavior has shifted across Elixir releases. If you hit a surprising result, [the module's history](https://github.com/elixir-lang/elixir/commits/main/lib/elixir/lib/uri.ex) is usually the fastest explanation.

## Usage

```elixir
iex> Norma.normalize("mazing.studio")
> "http://mazing.studio"

iex> Norma.normalize_if_valid("mazing.studio")
> {:ok, "http://mazing.studio"}

iex> Norma.normalize_if_valid("mazing")
> {:error, "Not an URL."}

iex> options = %{remove_fragment: true, force_root_path: true, remove_www: true}
iex> Norma.normalize("//www.mazing.studio:1337/test#test", options)
> "http://mazing.studio/"
```

### Options

- Remove scheme:
  ```elixir
  iex> Norma.normalize("https://mazing.studio", %{remove_scheme: true})
  > "mazing.studio"
  ```

- Remove fragment:
  ```elixir
  iex> Norma.normalize("https://mazing.studio#test", %{remove_fragment: true})
  > "https://mazing.studio"
  ```

- Add trailing slash:
  ```elixir
  iex> Norma.normalize("https://mazing.studio/test", %{add_trailing_slash: true})
  > "https://mazing.studio/test/"
  ```

- Force root path:
  ```elixir
  iex> Norma.normalize("https://mazing.studio/test", %{force_root_path: true})
  > "https://mazing.studio/"
  ```

- Remove `www`:
  ```elixir
  iex> Norma.normalize("https://www.mazing.studio", %{remove_www: true})
  > "https://mazing.studio"
  ```

- Downcase host:
  ```elixir
  iex> Norma.normalize("https://EXAMPLE.COM/FAQS", %{downcase_host: true})
  > "https://example.com/FAQS"
  ```

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

1. Add support for the option in `/lib/norma/normalizer.ex`. Prefer pattern matching and guards over `if`s and `case`s.
2. Add a test in `/test/norma_test.exs`.
2. Add documentation to the `README`.
3. Send a PR 🎉

### Maintainers

- [Zura Guerra](https://github.com/ZuraGuerra) - [@grafofilia](https://twitter.com/grafofilia)

---

## A Mazing project

![Mazing Studio](https://avatars3.githubusercontent.com/u/19610766?v=4&s=200)

Sponsored by [_Mazing Studio_](https://mazing.studio)

We love to solve problems using Elixir and Go.

Have a project you need help with? [Tell us about it!](https://mazing.studio/#section-form)
