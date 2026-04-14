# UniqueNamesGenerator.jl

```@meta
CurrentModule = UniqueNamesGenerator
```

Generate unique, memorable, human-readable names from configurable word-list
dictionaries. Name **generation** (word selection) is cleanly separated from
name **rendering** (formatting into a string), so the same generated name can
be displayed in multiple formats without regenerating.

## Quick Start

```julia
using UniqueNamesGenerator

# 1. Generate a name and display it
name = generate()                # → UniqueName(["brave", "elegant", "dolphin"])
println(name)                    # "Brave Elegant Dolphin"
string(name)                     # "Brave Elegant Dolphin"

# 2. Inspect the raw words
name.words                       # ["brave", "elegant", "dolphin"]

# 3. Render the same name in several formats (keyword form)
name = generate([["swift"], ["falcon"]])
render(name)                                           # "Swift Falcon"
render(name; separator = "-", style = :lowercase)      # "swift-falcon"
render(name; separator = "_", style = :uppercase)      # "SWIFT_FALCON"

# 4. Render via RenderOptions and the shipped presets
render(name, TITLE)              # "Swift Falcon"
render(name, SLUG)               # "swift-falcon"
render(name, SCREAMING_SNAKE)    # "SWIFT_FALCON"

# 5. Batch generation
generate([ADJECTIVES, ANIMALS], 3; unique = true)

# 6. Exclusion set
exclude = Set([UniqueName(["swift", "falcon"])])
generate([["swift", "brave"], ["falcon"]], exclude)    # UniqueName(["brave", "falcon"])

# 7. Deterministic RNG
using Random
generate([ADJECTIVES, ANIMALS]; rng = MersenneTwister(42))
```

## Generate vs. render

- [`generate`](@ref) picks one word from each input dictionary and returns a
  [`UniqueName`](@ref) holding the raw `Vector{String}` of selected words. No
  formatting happens here.
- [`render`](@ref) turns a [`UniqueName`](@ref) into a `String`. It accepts
  either keyword arguments (`separator`, `style`) or a [`RenderOptions`](@ref)
  value. Both forms share a single rendering kernel and produce byte-identical
  output for the same `(separator, style)` pair.
- [`TITLE`](@ref), [`SLUG`](@ref), and [`SCREAMING_SNAKE`](@ref) are exported
  `const RenderOptions` presets for the most common formats.

## Built-in Dictionaries

The word lists are maintained in a **separate data repository**:
[`unique-names-data`](https://github.com/s-celles/unique-names-data/).

Decoupling data from code allows the dictionaries to be updated, enriched, or
reused by other projects (in any language) without releasing a new version of
the Julia package. The data is fetched at build time via the Julia
[Artifacts](https://pkgdocs.julialang.org/v1/artifacts/) system and cached
locally.

| Constant      | Description                                       |
|---------------|---------------------------------------------------|
| `ADJECTIVES`  | Common adjectives                                 |
| `ANIMALS`     | Animal names                                      |
| `COLORS`      | Colour names                                      |
| `CELESTIAL`   | Stars, galaxies, constellations …                 |
| `SCIENCE`     | Scientific terms                                  |
| `NATURE`      | Nature-related words                              |
| `NUMBERS`     | Number words                                      |
| `NATO`        | NATO phonetic alphabet (Alpha, Bravo, …, Zulu)    |
| `NOUNS`       | Union of animals + celestial + science + nature   |

## Custom Dictionaries

Use [`load_dictionary`](@ref) to load a CSV file (expects `word,category` header):

```julia
my_dict = load_dictionary("path/to/words.csv")
generate([ADJECTIVES, my_dict])
```
