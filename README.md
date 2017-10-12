# Norma

[![Hex.pm](https://img.shields.io/hexpm/v/norma.svg?style=flat-square)]()
[![Hex.pm](https://img.shields.io/hexpm/l/norma.svg?style=flat-square)]()
[![Maintenance](https://img.shields.io/maintenance/yes/2017.svg?style=flat-square)]()
[![GitHub issues](https://img.shields.io/github/issues/zuraguerra/dumballah.svg?style=flat-square)](https://github.com/mazingstudio/norma/issues)

Normalize URLs to the format you need.

## Installation

Add `Norma` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    # get always the latest ñ___ñ
    {:norma, ">= 0.0.0"}
  ]
end
```

### Note on compatibility

Norma depends heavily on the implementation of the `URI` module (part of the standard library), which was recently changed when adding [support for Erlang 20](https://github.com/elixir-lang/elixir/issues/5851). Use [the module history](https://github.com/elixir-lang/elixir/commits/master/lib/elixir/lib/uri.ex) as a guide if you encounter any weird error (specially if you suspect it's related to a regex).

## Usage

```elixir
iex> Norma.normalize("mazing.studio")
> "http://mazing.studio"

iex> options = %{remove_fragment: true, force_root_path: true, remove_www: true}
iex> Norma.normalize("//www.mazing.studio:1337/test#test", options)
> "http://mazing.studio/"
```

### Options

- Remove fragment:
  ```elixir
  iex> Norma.normalize("https://mazing.studio#test", %{remove_fragment: true})
  > "https://mazing.studio"
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

### TO-DO
- Rewrite scheme inference from port
- Maybe change options interface
- Deactivate defaulting to `http` with an option

### Adding options

1. Add support for the option in `/lib/norma/normalizer.ex`. Prefer pattern matching and guards over `if`s and `case`s.
2. Add a test in `/test/norma_test.exs`.
2. Add documentation to the `README`.
3. Send a PR 🎉

---

## A Mazing project

![Mazing Studio](https://avatars3.githubusercontent.com/u/19610766?v=4&s=200)

Sponsored by [_Mazing Studio_](https://mazing.studio)

We love solving problems using Elixir and Go.

Have a project we can help you with? [Tell us about it!](https://mazing.studio/#section-form)
