# UniqueNamesGenerator.jl

```@meta
CurrentModule = UniqueNamesGenerator
```

Generate unique, memorable, human-readable names from configurable word-list dictionaries.

## Quick Start

```julia
using UniqueNamesGenerator

generate_name()                          # "Brave Elegant Dolphin"
generate_name([ADJECTIVES, ANIMALS])     # "Swift Falcon"

# Batch
generate_name([ADJECTIVES, ANIMALS], 3; unique=true)

# Custom style / separator
generate_name([ADJECTIVES, COLORS, ANIMALS]; separator="-", style=:lowercase)

# Deterministic RNG
using Random
generate_name([ADJECTIVES, ANIMALS]; rng=MersenneTwister(42))
```

## Built-in Dictionaries

The word lists are maintained in a **separate data repository**:
[`unique-names-data`](https://github.com/s-celles/unique-names-data/).

Decoupling data from code allows the dictionaries to be updated, enriched, or
reused by other projects (in any language) without releasing a new version of the
Julia package.  The data is fetched at build time via the Julia
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
| `NOUNS`       | Union of animals + celestial + science + nature    |

## Custom Dictionaries

Use [`load_dictionary`](@ref) to load a CSV file (expects `word,category` header):

```julia
my_dict = load_dictionary("path/to/words.csv")
generate_name([ADJECTIVES, my_dict])
```
