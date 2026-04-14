using TestItemRunner

@run_package_tests

# ---------------------------------------------------------------------------
# Data package — dictionary loading (unchanged API)
# ---------------------------------------------------------------------------

@testitem "Built-in dictionaries loaded" begin
    using Test
    using UniqueNamesGenerator
    @test length(ADJECTIVES) >= 80
    @test length(NOUNS) >= 80
    @test length(ANIMALS) > 0
    @test length(COLORS) > 0
    @test length(NATO) >= 26
end

@testitem "NATO phonetic alphabet dictionary" begin
    using Test
    using UniqueNamesGenerator
    @test NATO isa Vector{String}
    @test length(NATO) == 26
    # The 26 NATO phonetic alphabet letters must all be present.
    expected = ["Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot",
                "Golf", "Hotel", "India", "Juliett", "Kilo", "Lima",
                "Mike", "November", "Oscar", "Papa", "Quebec", "Romeo",
                "Sierra", "Tango", "Uniform", "Victor", "Whiskey",
                "X-ray", "Yankee", "Zulu"]
    for word in expected
        @test word in NATO
    end
end

@testitem "NATO dictionary usable with generate + render" begin
    using Test
    using UniqueNamesGenerator
    using Random
    n = generate([NATO, NATO]; rng = MersenneTwister(42))
    @test n isa UniqueName
    @test length(n.words) == 2
    @test all(w -> w in NATO, n.words)
    # Rendered with all three presets
    @test render(n, TITLE) isa String
    @test render(n, SLUG) isa String
    @test render(n, SCREAMING_SNAKE) isa String
end

@testitem "load_dictionary from file" begin
    using Test
    using UniqueNamesGenerator
    path = tempname() * ".csv"
    write(path, "word,category\nalpha,a\nbeta,b\ngamma,c\n")
    d = load_dictionary(path)
    @test d == ["alpha", "beta", "gamma"]
    rm(path)
end

# ---------------------------------------------------------------------------
# Foundational — UniqueName struct (T003)
# ---------------------------------------------------------------------------

@testitem "UniqueName — construction and field access" begin
    using Test
    using UniqueNamesGenerator
    n = UniqueName(["alpha", "beta"])
    @test n.words == ["alpha", "beta"]
    @test length(n.words) == 2
    @test UniqueName(String[]).words == String[]
end

@testitem "UniqueName — equality is case-sensitive" begin
    using Test
    using UniqueNamesGenerator
    @test UniqueName(["a", "b"]) == UniqueName(["a", "b"])
    @test UniqueName(["a", "b"]) != UniqueName(["A", "B"])
    @test UniqueName(["a", "b"]) != UniqueName(["a", "c"])
    @test UniqueName(String[]) == UniqueName(String[])
end

@testitem "UniqueName — hash consistent with ==" begin
    using Test
    using UniqueNamesGenerator
    a = UniqueName(["a", "b"])
    b = UniqueName(["a", "b"])
    @test hash(a) == hash(b)
    # Usable as Dict / Set key
    d = Dict(a => 1)
    @test d[b] == 1
    s = Set([a, UniqueName(["c"])])
    @test b in s
    @test length(s) == 2
end

# ---------------------------------------------------------------------------
# Foundational — RenderOptions (T005)
# ---------------------------------------------------------------------------

@testitem "RenderOptions — default construction" begin
    using Test
    using UniqueNamesGenerator
    opts = RenderOptions()
    @test opts.separator == " "
    @test opts.style == :capital
end

@testitem "RenderOptions — explicit kwargs" begin
    using Test
    using UniqueNamesGenerator
    opts = RenderOptions(; separator = "-", style = :lowercase)
    @test opts.separator == "-"
    @test opts.style == :lowercase
end

@testitem "RenderOptions — valid styles accepted" begin
    using Test
    using UniqueNamesGenerator
    for s in (:capital, :uppercase, :lowercase)
        @test RenderOptions(; style = s).style === s
    end
end

@testitem "RenderOptions — invalid style rejected" begin
    using Test
    using UniqueNamesGenerator
    @test_throws ArgumentError RenderOptions(; style = :bogus)
    @test_throws ArgumentError RenderOptions(; style = :Capital)
    err = try
        RenderOptions(; style = :bogus)
    catch e
        e
    end
    @test err isa ArgumentError
    msg = sprint(showerror, err)
    @test occursin(":bogus", msg)
    @test occursin(":capital", msg)
    @test occursin(":uppercase", msg)
    @test occursin(":lowercase", msg)
end

@testitem "RenderOptions — structural equality" begin
    using Test
    using UniqueNamesGenerator
    @test RenderOptions(; separator = "-", style = :lowercase) ==
          RenderOptions(; separator = "-", style = :lowercase)
    @test RenderOptions() == RenderOptions(; separator = " ", style = :capital)
end

# ---------------------------------------------------------------------------
# Foundational — render(name, opts) canonical kernel (T007)
# ---------------------------------------------------------------------------

@testitem "render(name, opts) — empty UniqueName" begin
    using Test
    using UniqueNamesGenerator
    @test render(UniqueName(String[]), RenderOptions()) == ""
    @test render(UniqueName(String[]), RenderOptions(; separator = "-", style = :uppercase)) == ""
end

@testitem "render(name, opts) — single word" begin
    using Test
    using UniqueNamesGenerator
    n = UniqueName(["hello"])
    @test render(n, RenderOptions()) == "Hello"
    @test render(n, RenderOptions(; style = :uppercase)) == "HELLO"
    @test render(n, RenderOptions(; style = :lowercase)) == "hello"
    # Separator has no effect on single-word names
    @test render(n, RenderOptions(; separator = "-", style = :capital)) == "Hello"
end

@testitem "render(name, opts) — multi-word with each style" begin
    using Test
    using UniqueNamesGenerator
    n = UniqueName(["swift", "falcon"])
    @test render(n, RenderOptions(; separator = " ", style = :capital)) == "Swift Falcon"
    @test render(n, RenderOptions(; separator = "-", style = :lowercase)) == "swift-falcon"
    @test render(n, RenderOptions(; separator = "_", style = :uppercase)) == "SWIFT_FALCON"
end

@testitem "render(name, opts) — preserves input case for style :capital" begin
    using Test
    using UniqueNamesGenerator
    # The former generate_name used uppercasefirst on the joined split, so the
    # first character of each segment is uppercased; the rest is left as-is.
    @test render(UniqueName(["swift", "falcon"]), RenderOptions()) == "Swift Falcon"
end

# ---------------------------------------------------------------------------
# US1 — generate() + default display (T009)
# ---------------------------------------------------------------------------

@testitem "US1 — generate() default dictionaries" begin
    using Test
    using UniqueNamesGenerator
    name = generate()
    @test name isa UniqueName
    @test length(name.words) == 3
    @test all(w -> w isa String && !isempty(w), name.words)
end

@testitem "US1 — generate(dicts) explicit dictionaries" begin
    using Test
    using UniqueNamesGenerator
    dicts2 = [["a", "b"], ["c", "d"]]
    n = generate(dicts2)
    @test n isa UniqueName
    @test length(n.words) == 2
    @test n.words[1] in ["a", "b"]
    @test n.words[2] in ["c", "d"]

    n1 = generate([["hello"]])
    @test n1.words == ["hello"]

    n4 = generate([["a"], ["b"], ["c"], ["d"]])
    @test n4.words == ["a", "b", "c", "d"]
end

@testitem "US1 — empty dictionary throws ArgumentError" begin
    using Test
    using UniqueNamesGenerator
    @test_throws ArgumentError generate([String[]])
    @test_throws ArgumentError generate([["a"], String[]])
end

@testitem "US1 — default display via string / print / show / interpolation" begin
    using Test
    using UniqueNamesGenerator
    n = UniqueName(["swift", "falcon"])
    @test string(n) == "Swift Falcon"
    @test sprint(show, n) == "Swift Falcon"
    @test sprint(print, n) == "Swift Falcon"
    @test "$(n)" == "Swift Falcon"

    # Zero- and one-word names render consistently across all four paths.
    empty = UniqueName(String[])
    @test string(empty) == ""
    @test "$(empty)" == ""

    single = UniqueName(["hello"])
    @test string(single) == "Hello"
    @test "$(single)" == "Hello"
end

@testitem "US1 — generate + display end-to-end" begin
    using Test
    using UniqueNamesGenerator
    n = generate([["swift"], ["falcon"]])
    @test n.words == ["swift", "falcon"]
    @test string(n) == "Swift Falcon"
end

# ---------------------------------------------------------------------------
# US2 — render keyword form (T012)
# ---------------------------------------------------------------------------

@testitem "US2 — render(name; separator, style) kwarg form" begin
    using Test
    using UniqueNamesGenerator
    n = UniqueName(["swift", "falcon"])
    @test render(n) == "Swift Falcon"
    @test render(n; separator = "-", style = :lowercase) == "swift-falcon"
    @test render(n; separator = "_", style = :uppercase) == "SWIFT_FALCON"
    @test render(n; style = :lowercase) == "swift falcon"
    @test render(n; separator = "/") == "Swift/Falcon"
end

@testitem "US2 — render kwarg form parity with options-object form (SC-005)" begin
    using Test
    using UniqueNamesGenerator
    n = UniqueName(["alpha", "beta", "gamma"])
    for sep in (" ", "-", "_", "/", "::"), style in (:capital, :uppercase, :lowercase)
        @test render(n; separator = sep, style = style) ==
              render(n, RenderOptions(; separator = sep, style = style))
    end
end

@testitem "US2 — render kwarg form inherits RenderOptions style validation" begin
    using Test
    using UniqueNamesGenerator
    n = UniqueName(["a", "b"])
    @test_throws ArgumentError render(n; style = :bogus)
    @test_throws ArgumentError render(n; separator = "-", style = :Capital)
end

@testitem "US2 — same UniqueName rendered many ways without regeneration" begin
    using Test
    using UniqueNamesGenerator
    n = generate([["swift"], ["falcon"]])  # one generation
    # Render it three different ways from the same UniqueName
    @test render(n) == "Swift Falcon"
    @test render(n; separator = "-", style = :lowercase) == "swift-falcon"
    @test render(n; separator = "_", style = :uppercase) == "SWIFT_FALCON"
    # The underlying words are unchanged
    @test n.words == ["swift", "falcon"]
end

# ---------------------------------------------------------------------------
# US3 — raw word access (T014)
# ---------------------------------------------------------------------------

@testitem "US3 — .words is a Vector{String} of raw unformatted words" begin
    using Test
    using UniqueNamesGenerator
    n = generate([["alpha"], ["beta"], ["gamma"]])
    @test n.words isa Vector{String}
    @test n.words == ["alpha", "beta", "gamma"]
end

@testitem "US3 — length(name.words) matches dictionary count" begin
    using Test
    using UniqueNamesGenerator
    @test length(generate([["x"]]).words) == 1
    @test length(generate([["a"], ["b"]]).words) == 2
    @test length(generate([["a"], ["b"], ["c"]]).words) == 3
    @test length(generate([["a"], ["b"], ["c"], ["d"]]).words) == 4
end

# ---------------------------------------------------------------------------
# US4 — batch generation with uniqueness (T015)
# ---------------------------------------------------------------------------

@testitem "US4 — batch unique returns distinct UniqueName values" begin
    using Test
    using UniqueNamesGenerator
    using Random
    dicts = [["a", "b", "c"], ["d", "e", "f"]]
    names = generate(dicts, 5; unique = true, rng = MersenneTwister(1))
    @test names isa Vector{UniqueName}
    @test length(names) == 5
    # All distinct under case-insensitive word projection
    projected = [[lowercase(w) for w in n.words] for n in names]
    @test length(Set(projected)) == 5
end

@testitem "US4 — batch non-unique allows duplicates" begin
    using Test
    using UniqueNamesGenerator
    dicts = [["a"], ["b"]]
    names = generate(dicts, 5; unique = false)
    @test names isa Vector{UniqueName}
    @test length(names) == 5
    @test all(n -> n == UniqueName(["a", "b"]), names)
end

@testitem "US4 — n == 0 returns empty vector" begin
    using Test
    using UniqueNamesGenerator
    @test generate([["a"], ["b"]], 0) == UniqueName[]
    @test generate([["a"], ["b"]], 0; unique = false) == UniqueName[]
end

@testitem "US4 — batch unique exhausted throws ExhaustedNameSpaceError" begin
    using Test
    using UniqueNamesGenerator
    @test_throws UniqueNamesGenerator.ExhaustedNameSpaceError generate([["a"], ["b"]], 2; unique = true)
end

@testitem "US4 — batch determinism under seeded RNG" begin
    using Test
    using UniqueNamesGenerator
    using Random
    dicts = [["a", "b", "c", "d"], ["e", "f", "g", "h"]]
    s1 = generate(dicts, 6; unique = true, rng = MersenneTwister(7))
    s2 = generate(dicts, 6; unique = true, rng = MersenneTwister(7))
    @test s1 == s2
end

# ---------------------------------------------------------------------------
# US5 — exclusion set of UniqueName (T017)
# ---------------------------------------------------------------------------

@testitem "US5 — exclusion set yields the only remaining combination" begin
    using Test
    using UniqueNamesGenerator
    using Random
    dicts = [["a", "b"], ["c"]]
    exclude = Set([UniqueName(["a", "c"])])
    n = generate(dicts, exclude; rng = MersenneTwister(1))
    @test n isa UniqueName
    @test n.words == ["b", "c"]
end

@testitem "US5 — exclusion comparison is case-insensitive on word projection" begin
    using Test
    using UniqueNamesGenerator
    using Random
    dicts = [["a", "b"], ["c"]]
    # Exclusion set built with UPPER-case variant still excludes the lowercase draw.
    exclude = Set([UniqueName(["A", "C"])])
    n = generate(dicts, exclude; rng = MersenneTwister(1))
    @test n.words == ["b", "c"]
end

@testitem "US5 — empty exclusion set yields any valid combination" begin
    using Test
    using UniqueNamesGenerator
    using Random
    dicts = [["x"], ["y"]]
    exclude = Set{UniqueName}()
    n = generate(dicts, exclude; rng = MersenneTwister(2))
    @test n.words == ["x", "y"]
end

@testitem "US5 — fully-excluded space throws ExhaustedNameSpaceError" begin
    using Test
    using UniqueNamesGenerator
    dicts = [["a"], ["b"]]
    exclude = Set([UniqueName(["a", "b"])])
    @test_throws UniqueNamesGenerator.ExhaustedNameSpaceError generate(dicts, exclude)
end

@testitem "US5 — generic AbstractSet{UniqueName} accepted" begin
    using Test
    using UniqueNamesGenerator
    using Random
    # `BitSet` is out — keys aren't integers; but any `AbstractSet{UniqueName}` works.
    dicts = [["a", "b"], ["c"]]
    exclude::AbstractSet{UniqueName} = Set([UniqueName(["a", "c"])])
    n = generate(dicts, exclude; rng = MersenneTwister(1))
    @test n.words == ["b", "c"]
end

# ---------------------------------------------------------------------------
# US6 — deterministic seeding (T020)
# ---------------------------------------------------------------------------

@testitem "US6 — deterministic single-name generation under seeded RNG" begin
    using Test
    using UniqueNamesGenerator
    using Random
    dicts = [["a", "b", "c", "d"], ["e", "f", "g", "h"]]
    a = generate(dicts; rng = MersenneTwister(42))
    b = generate(dicts; rng = MersenneTwister(42))
    @test a == b
    @test a.words == b.words
end

@testitem "US6 — determinism across all generate forms" begin
    using Test
    using UniqueNamesGenerator
    using Random
    dicts = [["a", "b", "c"], ["d", "e", "f"]]

    # Single-name
    @test generate(dicts; rng = MersenneTwister(1)) ==
          generate(dicts; rng = MersenneTwister(1))

    # Batch unique
    @test generate(dicts, 4; unique = true, rng = MersenneTwister(1)) ==
          generate(dicts, 4; unique = true, rng = MersenneTwister(1))

    # Exclusion set
    exclude = Set([UniqueName(["a", "d"])])
    @test generate(dicts, exclude; rng = MersenneTwister(1)) ==
          generate(dicts, exclude; rng = MersenneTwister(1))
end

# ---------------------------------------------------------------------------
# US7 — render presets (T021)
# ---------------------------------------------------------------------------

@testitem "US7 — TITLE preset renders default title-case with spaces" begin
    using Test
    using UniqueNamesGenerator
    n = UniqueName(["swift", "falcon"])
    @test render(n, TITLE) == "Swift Falcon"
    @test render(n, TITLE) == render(n)               # identical to no-opts default
    @test TITLE == RenderOptions()
    @test TITLE == RenderOptions(; separator = " ", style = :capital)
end

@testitem "US7 — SLUG preset renders dash-lowercase" begin
    using Test
    using UniqueNamesGenerator
    n = UniqueName(["swift", "falcon"])
    @test render(n, SLUG) == "swift-falcon"
    @test render(n, SLUG) == render(n; separator = "-", style = :lowercase)
    @test SLUG == RenderOptions(; separator = "-", style = :lowercase)
end

@testitem "US7 — SCREAMING_SNAKE preset renders underscore-uppercase" begin
    using Test
    using UniqueNamesGenerator
    n = UniqueName(["swift", "falcon"])
    @test render(n, SCREAMING_SNAKE) == "SWIFT_FALCON"
    @test render(n, SCREAMING_SNAKE) == render(n; separator = "_", style = :uppercase)
    @test SCREAMING_SNAKE == RenderOptions(; separator = "_", style = :uppercase)
end

@testitem "US7 — preset parity (SC-005) across 3-word names" begin
    using Test
    using UniqueNamesGenerator
    n = UniqueName(["alpha", "beta", "gamma"])
    @test render(n, TITLE) == "Alpha Beta Gamma"
    @test render(n, SLUG) == "alpha-beta-gamma"
    @test render(n, SCREAMING_SNAKE) == "ALPHA_BETA_GAMMA"
end

@testitem "US7 — presets are immutable const values (identity across calls)" begin
    using Test
    using UniqueNamesGenerator
    # Each preset is a single module-level value; accessing it repeatedly
    # returns the same object (same hash, ==, and structural fields).
    @test TITLE === TITLE
    @test SLUG === SLUG
    @test SCREAMING_SNAKE === SCREAMING_SNAKE
end
