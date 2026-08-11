# Changelog

All notable changes to this project will be documented in this file.

## [1.9.0] - 2026-08-11

### Added

- Package docs via `ex_doc` (`docs: [main: "Norma", extras: ["CHANGELOG.md"]]`)
- `dialyxir` and `ex_doc` as development dependencies

### Fixed

- Emit query before fragment in `form_url` (RFC 3986 order). Previously
  `Norma.Utils.form_url/1` concatenated the fragment before the query, producing
  invalid URLs like `/Path#Frag?Q=Foo`. The fragment must come last. (#11)
- Avoid a duplicate trailing slash when the URL path already ends with `/`
  and `add_trailing_slash` is set. (#11)
