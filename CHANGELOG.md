# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.1] - 2026-08-11

No behavior changes. Documentation and test coverage only.

### Added

- Property-based test suite (`stream_data`) covering the two assumptions 2.0 rests
  on: the empty-path deviation from `:uri_string.normalize/1` is limited to the root
  path and nothing else, and `normalize/2` is idempotent (including under
  `restore_old_query_behavior` and the path-shaping options).
- A short "Upgrading from 1.x in five minutes" table in the README, next to the full
  migration guide.

### Fixed

- Removed a docs reference to a `@doc false` function that made `ex_doc` warn on
  every build.

## [2.0.0] - 2026-08-11

Breaking release. Migration notes with before/after strings:
[Migrating to 2.0](docs/migrating-to-2.0.md).

### Changed

- **D6 — RFC 3986 normalization default-on.** `form_url/1` finishes with
  `:uri_string.normalize/1` (dot-segment removal, host case folding,
  percent-encoding normalization, scheme-aware default-port omission).
  The opinionated scheme-blind `@masked_ports` list and `form_port/1` are
  **removed**. Ports such as `8080` and non-default ports for the scheme
  (e.g. `http://…:443`) are no longer stripped.
- **D1 — Query order and duplicate keys preserved.** Query rebuild no longer
  round-trips through a map (`URI.decode_query` / `URI.encode_query`), which
  sorted keys and collapsed duplicates. Pairs keep input order and multi-value
  keys. Opt-in `restore_old_query_behavior: true` restores the 1.x sort+dedupe
  path.
- **D3 — Trailing slash looks at the final path segment only.**
  `add_trailing_slash` skips only when the **last** segment contains `.`
  (file-like), not when a `.` appears anywhere in the path. Versioned
  directories like `/v1.2/docs` now get a trailing slash.
- **D4 — `force_root_path` wipes query and fragment.** Setting path to `/` also
  clears `:query` and `:fragment`. New additive option `add_root_path: true`
  sets path to `/` only when the path is nil or empty (non-empty paths stay).
- **D5 — Parse via `URI.new/1`.** Replaces the recursive `safe_parse` /
  `has_valid_host?` loop. `URI.new/1` returns `{:ok, uri} | {:error, part}`
  and needs **Elixir 1.13+**. Scheme-less `//…` inference remains a single
  explicit branch, not mutual recursion.
- **D8 — `downcase_host` option removed.** Host case folding is always on via
  D6 (`:uri_string.normalize/1`). Passing `%{downcase_host: true | false}` is
  ignored; there is no way to keep an uppercase host in the normalized output.

### Toolchain

- Minimum Elixir: `~> 1.13` (was `~> 1.11`).
- CI matrix: Elixir 1.20/OTP 29, 1.19/OTP 28, 1.16/OTP 26, 1.13/OTP 24.

## [1.9.0] - 2026-08-11

### Added

- Package docs via `ex_doc` (`docs: [main: "Norma", extras: ["CHANGELOG.md"]]`)
- `dialyxir` and `ex_doc` as development dependencies

### Fixed

- Emit query before fragment in `form_url` (RFC 3986 order). Previously
  the internal URL assembly concatenated the fragment before the query, producing
  invalid URLs like `/Path#Frag?Q=Foo`. The fragment must come last. (#11)
- Avoid a duplicate trailing slash when the URL path already ends with `/`
  and `add_trailing_slash` is set. (#11)
