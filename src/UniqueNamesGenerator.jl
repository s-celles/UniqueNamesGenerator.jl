module UniqueNamesGenerator

using Random
using Unicode
using Artifacts

export UniqueName, RenderOptions
export generate, render
export TITLE, SLUG, SCREAMING_SNAKE
export load_dictionary
export ADJECTIVES, ANIMALS, COLORS, NOUNS, CELESTIAL, SCIENCE, NATURE, NUMBERS, NATO

# ---------------------------------------------------------------------------
# Dictionary loading
# ---------------------------------------------------------------------------

"""
    load_dictionary(file::AbstractString)::Vector{String}

Load a word list from a CSV file (first column, skipping the header line).
"""
function load_dictionary(file::AbstractString)::Vector{String}
    lines = readlines(file)
    length(lines) <= 1 && return String[]
    [split(line, ',')[1] for line in lines[2:end] if !isempty(strip(line))]
end

# ---------------------------------------------------------------------------
# Built-in dictionaries (populated at __init__ time)
# ---------------------------------------------------------------------------

const ADJECTIVES = String[]
const ANIMALS    = String[]
const COLORS     = String[]
const CELESTIAL  = String[]
const SCIENCE    = String[]
const NATURE     = String[]
const NUMBERS    = String[]
const NATO       = String[]   # NATO phonetic alphabet (Alpha, Bravo, …, Zulu)
const NOUNS      = String[]   # union of animals + celestial + science + nature

function __init__()
    dir = joinpath(artifact"unique-names-data", "data")
    append!(ADJECTIVES, load_dictionary(joinpath(dir, "adjectives.csv")))
    append!(ANIMALS,    load_dictionary(joinpath(dir, "animals.csv")))
    append!(COLORS,     load_dictionary(joinpath(dir, "colors.csv")))
    append!(CELESTIAL,  load_dictionary(joinpath(dir, "celestial.csv")))
    append!(SCIENCE,    load_dictionary(joinpath(dir, "science.csv")))
    append!(NATURE,     load_dictionary(joinpath(dir, "nature.csv")))
    append!(NUMBERS,    load_dictionary(joinpath(dir, "numbers.csv")))
    append!(NATO,       load_dictionary(joinpath(dir, "nato.csv")))
    # NOUNS = animals ∪ celestial ∪ science ∪ nature (unique, sorted)
    append!(NOUNS, sort!(unique(vcat(ANIMALS, CELESTIAL, SCIENCE, NATURE))))
end

const DEFAULT_DICTIONARIES = [ADJECTIVES, ADJECTIVES, NOUNS]

# ---------------------------------------------------------------------------
# Errors
# ---------------------------------------------------------------------------

"""
    ExhaustedNameSpaceError(max, excluded)

Thrown when all possible name combinations have been exhausted.
"""
struct ExhaustedNameSpaceError <: Exception
    max_combinations::Int
    excluded_count::Int
end

function Base.showerror(io::IO, e::ExhaustedNameSpaceError)
    print(io, "ExhaustedNameSpaceError: all $(e.max_combinations) possible ",
          "name combinations are exhausted ",
          "($(e.excluded_count) excluded).")
end

export ExhaustedNameSpaceError

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

"""
Return the total number of possible combinations for `dictionaries`.
"""
function _combination_count(
    dictionaries::AbstractVector{<:AbstractVector{<:AbstractString}},
)::Int
    isempty(dictionaries) && return 0
    prod(length(d) for d in dictionaries)
end

function _apply_style(name::AbstractString, separator::AbstractString, style::Symbol)::String
    if style == :capital
        return join(uppercasefirst.(split(name, separator)), separator)
    elseif style == :uppercase
        return uppercase(name)
    else  # :lowercase — RenderOptions guarantees style ∈ {:capital, :uppercase, :lowercase}
        return lowercase(name)
    end
end

# ---------------------------------------------------------------------------
# Public types — UniqueName and RenderOptions
# ---------------------------------------------------------------------------

"""
    UniqueName(words::Vector{String})

Immutable value type representing a generated name as an ordered sequence of
selected words. Produced by [`generate`](@ref) and consumed by [`render`](@ref).

The single public field `words` is always a `Vector{String}`. A `UniqueName`
carries no rendering state — separator and style are the concern of
[`RenderOptions`](@ref).

# Examples

```jldoctest
julia> using UniqueNamesGenerator

julia> name = UniqueName(["swift", "falcon"]);

julia> name.words
2-element Vector{String}:
 "swift"
 "falcon"

julia> string(name)
"Swift Falcon"
```
"""
struct UniqueName
    words::Vector{String}
end

Base.:(==)(a::UniqueName, b::UniqueName) = a.words == b.words
Base.hash(n::UniqueName, h::UInt) = hash(n.words, hash(:UniqueName, h))

"""
    RenderOptions(; separator::AbstractString=" ", style::Symbol=:capital)

Immutable rendering configuration for [`render`](@ref). Holds the inter-word
`separator` and a word `style` from the closed set `{:capital, :uppercase,
:lowercase}`. Any other `style` symbol is rejected at construction time with an
`ArgumentError`.

As an immutable value type, `RenderOptions` is safe to share as a `const`
module-level value; the package ships three such presets: [`TITLE`](@ref),
[`SLUG`](@ref), and [`SCREAMING_SNAKE`](@ref).

# Examples

```jldoctest
julia> using UniqueNamesGenerator

julia> RenderOptions(; separator = "-", style = :lowercase)
RenderOptions("-", :lowercase)
```
"""
struct RenderOptions
    separator::String
    style::Symbol
    function RenderOptions(separator::AbstractString, style::Symbol)
        style in (:capital, :uppercase, :lowercase) ||
            throw(ArgumentError("RenderOptions: unknown style $(repr(style)); " *
                                "expected one of :capital, :uppercase, :lowercase."))
        return new(String(separator), style)
    end
end

RenderOptions(; separator::AbstractString = " ", style::Symbol = :capital) =
    RenderOptions(separator, style)

"""
    TITLE

`RenderOptions` preset: space-separated, `:capital` style. Semantically
identical to `RenderOptions()`; use it at call sites to spell the default
rendering intent explicitly (`render(name, TITLE)`).
"""
const TITLE = RenderOptions(; separator = " ", style = :capital)

"""
    SLUG

`RenderOptions` preset: dash-separated, `:lowercase` style. Suitable for
URL-safe slugs (`render(name, SLUG)` → `"swift-falcon"`).
"""
const SLUG = RenderOptions(; separator = "-", style = :lowercase)

"""
    SCREAMING_SNAKE

`RenderOptions` preset: underscore-separated, `:uppercase` style. Suitable for
constant names (`render(name, SCREAMING_SNAKE)` → `"SWIFT_FALCON"`).
"""
const SCREAMING_SNAKE = RenderOptions(; separator = "_", style = :uppercase)

# ---------------------------------------------------------------------------
# Public API — rendering
# ---------------------------------------------------------------------------

"""
    render(name::UniqueName, opts::RenderOptions)::String
    render(name::UniqueName; separator::AbstractString=" ", style::Symbol=:capital)::String

Render a [`UniqueName`](@ref) to a `String` using the given rendering
configuration. The options-object form is the canonical rendering kernel; the
keyword form is a thin wrapper that constructs a [`RenderOptions`](@ref) and
delegates to it, so both forms produce byte-identical output for the same
`(separator, style)` pair.

`render` is a pure function: no randomness, no I/O, no mutation of its
arguments. A zero-word `UniqueName` renders to `""`; a one-word `UniqueName`
renders the single word with `style` applied and `separator` has no effect.

# Examples

```jldoctest
julia> using UniqueNamesGenerator

julia> name = UniqueName(["swift", "falcon"]);

julia> render(name)
"Swift Falcon"

julia> render(name; separator = "-", style = :lowercase)
"swift-falcon"

julia> render(name, SCREAMING_SNAKE)
"SWIFT_FALCON"
```
"""
function render(name::UniqueName, opts::RenderOptions)::String
    isempty(name.words) && return ""
    return _apply_style(join(name.words, opts.separator), opts.separator, opts.style)
end

# Keyword convenience wrapper: one-liner that forwards to the kernel via a
# freshly-built RenderOptions, so style validation is inherited for free.
render(name::UniqueName; separator::AbstractString = " ", style::Symbol = :capital)::String =
    render(name, RenderOptions(; separator, style))

# Pure `Base.show` — no module-level state, no IOContext lookup (FR-004).
Base.show(io::IO, n::UniqueName) = print(io, render(n, RenderOptions()))

# ---------------------------------------------------------------------------
# Public API — generate
# ---------------------------------------------------------------------------

"""
    generate(; rng::AbstractRNG=Random.default_rng())::UniqueName
    generate(dictionaries; rng::AbstractRNG=Random.default_rng())::UniqueName

Generate a single random [`UniqueName`](@ref) by picking one word from each
dictionary. The no-arg form uses the built-in `[ADJECTIVES, ADJECTIVES, NOUNS]`
triplet; the explicit form accepts any `AbstractVector` of non-empty word
lists.

Throws `ArgumentError` if any dictionary is empty.

Use [`render`](@ref) to turn the returned `UniqueName` into a `String`.

# Examples

```jldoctest
julia> using UniqueNamesGenerator, Random

julia> n = generate([["swift"], ["falcon"]]);

julia> n.words
2-element Vector{String}:
 "swift"
 "falcon"

julia> string(n)
"Swift Falcon"
```
"""
function generate(
    dictionaries::AbstractVector{<:AbstractVector{<:AbstractString}};
    rng::AbstractRNG = Random.default_rng(),
)::UniqueName
    for d in dictionaries
        isempty(d) && throw(ArgumentError("Cannot generate a name from an empty dictionary."))
    end
    return UniqueName(String[rand(rng, d) for d in dictionaries])
end

generate(; rng::AbstractRNG = Random.default_rng())::UniqueName =
    generate(DEFAULT_DICTIONARIES; rng)

"""
    generate(dictionaries, exclude::AbstractSet{UniqueName};
             rng::AbstractRNG=Random.default_rng())::UniqueName

Generate a single [`UniqueName`](@ref) whose lowercased word projection is not
equal (element-wise) to the lowercased projection of any member of `exclude`.
Throws `ExhaustedNameSpaceError` when every combination is already excluded.
"""
function generate(
    dictionaries::AbstractVector{<:AbstractVector{<:AbstractString}},
    exclude::AbstractSet{UniqueName};
    rng::AbstractRNG = Random.default_rng(),
)::UniqueName
    projections = Set{Vector{String}}(_lower_projection(n) for n in exclude)
    return _generate_excluding(dictionaries, projections; rng)
end

# Lowercased projection used for case-insensitive uniqueness and exclusion.
_lower_projection(n::UniqueName)::Vector{String} = String[lowercase(w) for w in n.words]

"""
    generate(dictionaries, n::Integer;
             unique::Bool=true,
             rng::AbstractRNG=Random.default_rng())::Vector{UniqueName}

Generate `n` [`UniqueName`](@ref) values in one call. When `unique=true`, all
returned names are distinct on their case-insensitive word projection, and
`ExhaustedNameSpaceError` is thrown if `n` exceeds the number of available
combinations. When `unique=false`, duplicates are allowed.
"""
function generate(
    dictionaries::AbstractVector{<:AbstractVector{<:AbstractString}},
    n::Integer;
    unique::Bool = true,
    rng::AbstractRNG = Random.default_rng(),
)::Vector{UniqueName}
    n >= 0 || throw(ArgumentError("generate: n must be non-negative, got $n"))
    if !unique
        return UniqueName[generate(dictionaries; rng) for _ in 1:n]
    end
    max_combos = _combination_count(dictionaries)
    if n > max_combos
        throw(ExhaustedNameSpaceError(max_combos, 0))
    end
    results = Vector{UniqueName}(undef, 0)
    seen_projections = Set{Vector{String}}()
    for _ in 1:n
        name = _generate_excluding(dictionaries, seen_projections; rng)
        push!(results, name)
        push!(seen_projections, _lower_projection(name))
    end
    return results
end

# Core helper: draw a UniqueName whose lowercased word projection is not in
# `excluded_projections`. Shared by the batch-unique and exclusion-set paths.
function _generate_excluding(
    dictionaries::AbstractVector{<:AbstractVector{<:AbstractString}},
    excluded_projections::AbstractSet{Vector{String}};
    rng::AbstractRNG = Random.default_rng(),
)::UniqueName
    max_combos = _combination_count(dictionaries)
    if length(excluded_projections) >= max_combos
        throw(ExhaustedNameSpaceError(max_combos, length(excluded_projections)))
    end
    # Fast path: bounded random draws.
    max_attempts = min(max_combos, 1000)
    for _ in 1:max_attempts
        candidate = generate(dictionaries; rng)
        _lower_projection(candidate) in excluded_projections || return candidate
    end
    # Deterministic fallback: sweep Iterators.product for guaranteed termination.
    for combo in Iterators.product(dictionaries...)
        candidate_words = String[w for w in combo]
        projection = String[lowercase(w) for w in candidate_words]
        projection in excluded_projections || return UniqueName(candidate_words)
    end
    throw(ExhaustedNameSpaceError(max_combos, length(excluded_projections)))
end

end # module UniqueNamesGenerator
