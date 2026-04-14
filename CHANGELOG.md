# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-04-14

### Added

- `UniqueName` immutable value type holding the raw `Vector{String}` of words
  selected during name generation. Produced by `generate`, consumed by
  `render`. Implements `Base.:(==)`, `Base.hash`, and `Base.show` so it can be
  used as a `Dict`/`Set` key and interpolated into strings directly.
- `RenderOptions` immutable rendering configuration with `separator::String`
  and `style::Symbol` fields. The inner constructor validates `style` and
  throws `ArgumentError` for any symbol outside `{:capital, :uppercase,
  :lowercase}`.
- `generate` function replacing `generate_name`. Available in four forms:
  `generate()` (default dictionaries), `generate(dicts)`, `generate(dicts,
  exclude::AbstractSet{UniqueName})`, and `generate(dicts, n::Integer;
  unique)`. All forms return `UniqueName` (or `Vector{UniqueName}`) instead of
  `String`.
- `render` function in two coexisting forms:
  `render(name::UniqueName, opts::RenderOptions)` (canonical kernel) and
  `render(name::UniqueName; separator, style)` (keyword convenience wrapper).
  Both forms produce byte-identical output for the same `(separator, style)`
  pair.
- `TITLE`, `SLUG`, and `SCREAMING_SNAKE` exported `const RenderOptions`
  presets for the most common render formats (space / dash / underscore with
  `:capital` / `:lowercase` / `:uppercase` style respectively).
- `NATO` exported `const Vector{String}` containing the 26 NATO phonetic
  alphabet letters (Alpha, Bravo, Charlie, …, Zulu). Sourced from the bumped
  `unique-names-data` artifact.

### Changed

- Bumped `unique-names-data` artifact from `v0.1.1` to `v0.2.0`, which adds
  the `nato.csv` dictionary (exposed as the new `NATO` constant above).
- Exclusion sets passed to `generate` are now typed as
  `AbstractSet{UniqueName}` (previously `AbstractSet{String}`). Comparison is
  still case-insensitive, performed internally on a lowercased word projection.
- `Base.show(io::IO, ::UniqueName)` renders using the default
  `RenderOptions()` with no module-level mutable state and no `IOContext`
  lookup — it is a pure function of the `UniqueName` value, so `string(name)`,
  `print(name)`, and `"$name"` always produce the same output.

### Fixed

- `scripts/update_artifact.jl` now writes `lazy = false` so that
  `Artifacts.toml` regenerations keep the artifact eagerly downloaded at
  install time, preserving offline support.

### Removed

- **Breaking**: `generate_name` has been removed without a deprecation
  wrapper. Replace call sites with `render(generate(...))`, or keep the
  intermediate `UniqueName` for multi-render use cases:
  ```julia
  name = generate([ADJECTIVES, ANIMALS])
  render(name)                         # "Swift Falcon"
  render(name, SLUG)                   # "swift-falcon"
  ```

## [0.1.0] - 2026-03-05

Initial release.

[Unreleased]: https://github.com/s-celles/UniqueNamesGenerator.jl/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/s-celles/UniqueNamesGenerator.jl/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/s-celles/UniqueNamesGenerator.jl/releases/tag/v0.1.0
