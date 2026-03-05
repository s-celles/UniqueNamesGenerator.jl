module UniqueNamesGenerator

using Random
using Unicode
using Artifacts
using LazyArtifacts

export generate_name, load_dictionary
export ADJECTIVES, ANIMALS, COLORS, NOUNS, CELESTIAL, SCIENCE, NATURE, NUMBERS

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
    elseif style == :lowercase
        return lowercase(name)
    end
    return String(name)
end

# ---------------------------------------------------------------------------
# Public API — single name
# ---------------------------------------------------------------------------

"""
    generate_name(
        dictionaries = DEFAULT_DICTIONARIES;
        separator = " ",
        style = :capital,
        rng = Random.default_rng(),
    )::String

Generate a single random name by picking one word from each dictionary.
"""
function generate_name(
    dictionaries::AbstractVector{<:AbstractVector{<:AbstractString}} = DEFAULT_DICTIONARIES;
    separator::String = " ",
    style::Symbol = :capital,
    rng::AbstractRNG = Random.default_rng(),
)::String
    for d in dictionaries
        isempty(d) && throw(ArgumentError("Cannot generate a name from an empty dictionary."))
    end
    words = [rand(rng, d) for d in dictionaries]
    _apply_style(join(words, separator), separator, style)
end

# ---------------------------------------------------------------------------
# Public API — single name with exclusion set  (REQ-NAMEPKG-003 / 010)
# ---------------------------------------------------------------------------

"""
    generate_name(
        dictionaries,
        exclude::AbstractSet{String};
        separator = " ",
        style = :capital,
        rng = Random.default_rng(),
    )::String

Generate a name that is **not** present in `exclude`.
Throws `ExhaustedNameSpaceError` if all combinations are exhausted.
"""
function generate_name(
    dictionaries::AbstractVector{<:AbstractVector{<:AbstractString}},
    exclude::AbstractSet{<:AbstractString};
    separator::String = " ",
    style::Symbol = :capital,
    rng::AbstractRNG = Random.default_rng(),
)::String
    max_combos = _combination_count(dictionaries)
    if length(exclude) >= max_combos
        throw(ExhaustedNameSpaceError(max_combos, length(exclude)))
    end
    # Try random draws (fast path for sparse exclusion sets)
    max_attempts = min(max_combos, 1000)
    for _ in 1:max_attempts
        name = generate_name(dictionaries; separator, style, rng)
        lowercase(name) ∉ (lowercase(e) for e in exclude) && return name
    end
    # Fallback: brute-force remaining space (guaranteed termination)
    for combo in Iterators.product(dictionaries...)
        candidate = _apply_style(join(combo, separator), separator, style)
        lowercase(candidate) ∉ (lowercase(e) for e in exclude) && return candidate
    end
    throw(ExhaustedNameSpaceError(max_combos, length(exclude)))  # unreachable in theory
end

# ---------------------------------------------------------------------------
# Public API — batch generation  (REQ-NAMEPKG-003)
# ---------------------------------------------------------------------------

"""
    generate_name(
        dictionaries,
        n::Integer;
        unique = true,
        separator = " ",
        style = :capital,
        rng = Random.default_rng(),
    )::Vector{String}

Generate `n` names.  When `unique=true`, all names in the returned vector are
distinct (case-insensitive).  Throws `ExhaustedNameSpaceError` when requesting
more unique names than available combinations.
"""
function generate_name(
    dictionaries::AbstractVector{<:AbstractVector{<:AbstractString}},
    n::Integer;
    unique::Bool = true,
    separator::String = " ",
    style::Symbol = :capital,
    rng::AbstractRNG = Random.default_rng(),
)::Vector{String}
    if unique
        max_combos = _combination_count(dictionaries)
        if n > max_combos
            throw(ExhaustedNameSpaceError(max_combos, 0))
        end
        results = String[]
        seen = Set{String}()
        for _ in 1:n
            name = generate_name(dictionaries, seen; separator, style, rng)
            push!(results, name)
            push!(seen, lowercase(name))
        end
        return results
    else
        return [generate_name(dictionaries; separator, style, rng) for _ in 1:n]
    end
end

end # module UniqueNamesGenerator
