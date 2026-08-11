# Migrating to Norma 2.0

Norma **2.0.0** is a breaking release. Most callers will see different output
strings for the same input, especially when ports, host case, path dot-segments,
or query strings are involved.

This guide lists each behavior change with **before (1.x)** and **after (2.0)**
strings. Lead item is **D6** — it rewrites the largest surface of default output.

Minimum Elixir is **1.13** (`URI.new/1`).

---

## D6 — RFC 3986 normalization is default-on

**What changed.** After option transforms, `form_url/1` runs
`:uri_string.normalize/1`. That applies RFC 3986 rules:

| Rule | Effect |
|------|--------|
| Dot-segment removal | `/a/./b/../c` → `/a/c` |
| Host case folding | `EXAMPLE.com` → `example.com` |
| Percent-encoding | `%7E` → `~`; reserved hex digits uppercased |
| Scheme-aware default ports | omit `:80` for `http`, `:443` for `https`, etc. |

**What was removed.** The scheme-blind `@masked_ports` list
(`[443, 80, 8080, 21]`) and `form_port/1`. In 1.x those ports were **always**
stripped, regardless of scheme. In 2.0 only the **default port for the scheme**
is omitted (via `:uri_string`); `8080` and non-default ports **survive**.

There is **no opt-out**. Normalization is always on. If
`:uri_string.normalize/1` returns an error, Norma falls back to the
pre-normalization string rather than raising.

### Before / after

```elixir
# 1.x — scheme-blind mask stripped :443 even on http
iex> Norma.normalize("http://example.com:443")
"http://example.com"

# 2.0 — 443 is not the default port for http; port kept
iex> Norma.normalize("http://example.com:443")
"http://example.com:443"
```

```elixir
# 1.x — 8080 always masked
iex> Norma.normalize("http://example.com:8080")
"http://example.com"

# 2.0 — 8080 is not a scheme default; kept
iex> Norma.normalize("http://example.com:8080")
"http://example.com:8080"
```

```elixir
# Default ports still omitted (scheme-aware, both versions for 80/443 defaults)
iex> Norma.normalize("http://example.com:80")
"http://example.com"

iex> Norma.normalize("https://example.com:443")
"https://example.com"
```

```elixir
# Host case folding (2.0 default-on via :uri_string.normalize)
iex> Norma.normalize("http://EXAMPLE.com/Path")
"http://example.com/Path"
```

```elixir
# Dot-segment removal
iex> Norma.normalize("http://example.com/a/./b/../c")
"http://example.com/a/c"
```

```elixir
# Percent-encoding normalization (%7E is unreserved ~)
iex> Norma.normalize("http://example.com/%7Euser")
"http://example.com/~user"
```

### Migration tips

- If you **depended** on 1.x stripping `:8080` or `http://…:443`, update
  expectations or strip those ports yourself after normalize.
- Cache keys / signatures that assumed alphabetized query or stripped ports
  need re-baselining (see D1 as well).
- Golden / snapshot tests against Norma output must be re-recorded for 2.0.

---

## D1 — Query parameter order and duplicates

**What changed.** 1.x rebuilt the query through `URI.decode_query/1` → map →
`URI.encode_query/1`. Maps drop duplicate keys (last wins) and
`encode_query` emits **sorted** keys.

2.0 preserves **input order** and **duplicate keys** (pair-list path).

### Restore 1.x query behavior

```elixir
Norma.normalize(url, %{restore_old_query_behavior: true})
```

With that option, query strings are again sorted and de-duplicated as in 1.x.
Default is **off** (preserve order + dups).

### Before / after

```elixir
# Duplicates
# 1.x
iex> Norma.normalize("http://example.com?z=1&a=2&z=3&b=4")
"http://example.com?a=2&b=4&z=3"

# 2.0
iex> Norma.normalize("http://example.com?z=1&a=2&z=3&b=4")
"http://example.com?z=1&a=2&z=3&b=4"

# Multi-value tags
# 1.x
iex> Norma.normalize("http://example.com?tag=a&tag=b&tag=c")
"http://example.com?tag=c"

# 2.0
iex> Norma.normalize("http://example.com?tag=a&tag=b&tag=c")
"http://example.com?tag=a&tag=b&tag=c"
```

```elixir
# Order (no sort)
# 1.x — alphabetized
iex> Norma.normalize("http://example.com?m=1&c=2&a=3")
"http://example.com?a=3&c=2&m=1"

# 2.0 — input order
iex> Norma.normalize("http://example.com?m=1&c=2&a=3")
"http://example.com?m=1&c=2&a=3"
```

```elixir
# Opt-in 1.x query path
iex> Norma.normalize("http://example.com?m=1&c=2&a=3", %{restore_old_query_behavior: true})
"http://example.com?a=3&c=2&m=1"
```

---

## D3 — `add_trailing_slash` and dotted path segments

**What changed.** 1.x treated any path containing `.` anywhere as “file-like”
and skipped the trailing slash. That false-positived on versioned segments
(`v1.2`) and dotted prefixes (`api.v2`).

2.0 inspects only the **final** path segment: if that segment contains `.`,
the slash is skipped; intermediate dots no longer block it.

### Before / after

```elixir
opts = %{add_trailing_slash: true}

# 1.x — '.' in "v1.2" blocked the slash
iex> Norma.normalize("http://example.com/v1.2/docs", opts)
"http://example.com/v1.2/docs"

# 2.0 — final segment "docs" has no dot
iex> Norma.normalize("http://example.com/v1.2/docs", opts)
"http://example.com/v1.2/docs/"
```

```elixir
# Unchanged: undotted directory still gets a slash
iex> Norma.normalize("http://example.com/docs", %{add_trailing_slash: true})
"http://example.com/docs/"

# Unchanged: final segment with extension still skipped
iex> Norma.normalize("http://example.com/sitemap.xml", %{add_trailing_slash: true})
"http://example.com/sitemap.xml"
```

```elixir
# Dotted middle segment
# 1.x
iex> Norma.normalize("http://example.com/api.v2/users", %{add_trailing_slash: true})
"http://example.com/api.v2/users"

# 2.0
iex> Norma.normalize("http://example.com/api.v2/users", %{add_trailing_slash: true})
"http://example.com/api.v2/users/"
```

---

## D4 — `force_root_path` and `add_root_path`

**What changed.** 1.x `force_root_path: true` only set `path` to `"/"` and left
`:query` and `:fragment` intact ([#7](https://github.com/mazingstudio/norma/issues/7)).

2.0 clears **path, query, and fragment** together.

**Additive:** `add_root_path: true` sets path to `"/"` only when path is `nil`
or empty; non-empty paths are left alone (unlike `add_trailing_slash`, which
appends `/` to every path that is not already file-like).

### Before / after

```elixir
# force_root_path
# 1.x — query and fragment survived
iex> Norma.normalize("example.com/some/dir?page=2#faqs", %{force_root_path: true})
"http://example.com/?page=2#faqs"

# 2.0 — root means root
iex> Norma.normalize("example.com/some/dir?page=2#faqs", %{force_root_path: true})
"http://example.com/"
```

```elixir
# add_root_path (new in 2.0)
iex> Norma.normalize("example.com", %{add_root_path: true})
"http://example.com/"

iex> Norma.normalize("example.com/some/dir", %{add_root_path: true})
"http://example.com/some/dir"
# contrast: add_trailing_slash would yield ".../some/dir/"
```

---

## D5 — Parse with `URI.new/1` (Elixir 1.13+)

**What changed.** Internal `safe_parse/1` + recursive `has_valid_host?` is
replaced by `URI.new/1`, which returns `{:ok, uri} | {:error, part}` instead of
raising. That removes the unbounded re-parse loop at the root.

Scheme-less inputs that need a `//` prefix for correct host parsing are still
handled, but as a **single explicit branch**, not mutual recursion.

For inputs that already normalized successfully on 1.x, **public output is
unchanged** by D5 alone. The break is the **toolchain floor**: Elixir **1.13+**.

### Before / after (toolchain)

| | 1.x | 2.0 |
|--|-----|-----|
| `mix.exs` elixir | `~> 1.11` | `~> 1.13` |
| Parse API | `URI.parse/1` + recursive fixup | `URI.new/1` + one-shot `//` branch |

```elixir
# Behavior for normal inputs is stable across the parse rewrite, e.g.:
iex> Norma.normalize("mazing.studio:80")
"http://mazing.studio"
```

If you still need Elixir 1.11–1.12, stay on Norma 1.9.x.

---

## D8 — `downcase_host` option removed

**What changed.** In 1.x, host case was preserved unless you passed
`downcase_host: true`. In 2.0, **D6** always runs `:uri_string.normalize/1`,
which folds the host to lowercase. The option can no longer be honored
(`downcase_host: false` would fight unconditional RFC normalize), so it was
**removed** from the public API.

Passing `%{downcase_host: …}` is silently ignored (unknown keys are not
errors). There is **no escape hatch** to keep an uppercase host.

### Before / after

```elixir
# 1.x default — host case preserved
iex> Norma.normalize("HTTP://EXAMPLE.COM/DIR?PAGE=2")
"http://EXAMPLE.COM/DIR?PAGE=2"

# 1.x opt-in
iex> Norma.normalize("HTTP://EXAMPLE.COM/DIR", %{downcase_host: true})
"http://example.com/DIR"

# 2.0 — always downcased; option gone
iex> Norma.normalize("HTTP://EXAMPLE.COM/DIR?PAGE=2")
"http://example.com/DIR?PAGE=2"
```

### Migration tips

- Delete any `downcase_host: true` / `false` keys from options maps.
- If you **needed** an uppercase host in the string, normalize first, then
  re-case the host yourself (unusual; RFC hosts are case-insensitive).

---

## Quick checklist

1. Bump `{:norma, "~> 2.0"}` and ensure Elixir `>= 1.13`.
2. Re-run any snapshot / golden tests; expect widespread string diffs from **D6**
   and **D1**.
3. Audit callers that assumed:
   - ports `80`/`443`/`8080`/`21` always stripped → **D6**
   - query keys sorted / unique → use `restore_old_query_behavior: true` or adapt → **D1**
   - `force_root_path` kept `?query` / `#fragment` → **D4**
   - trailing slash skipped because of a `.` mid-path → **D3**
   - `downcase_host: false` kept uppercase hosts → **D8** / **D6**
4. Prefer `add_root_path` when you only want a root path on host-only URLs.
5. Drop `downcase_host` from options maps (**D8**).

---

## Decision index

| ID | Topic | Default 2.0 | Escape hatch |
|----|--------|-------------|--------------|
| D6 | RFC 3986 via `:uri_string.normalize` | on | none (error → pre-normalize string) |
| D1 | Query order + duplicate keys | preserve | `restore_old_query_behavior: true` |
| D3 | Trailing slash / final segment | final-segment `.` only | — |
| D4 | `force_root_path` | wipe path+query+fragment | —; new `add_root_path` |
| D5 | `URI.new/1` | required | stay on 1.9.x if Elixir &lt; 1.13 |
| D8 | `downcase_host` option | removed (always fold) | none |
