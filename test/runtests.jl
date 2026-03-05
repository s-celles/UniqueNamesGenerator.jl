using TestItemRunner

@run_package_tests

# ---------------------------------------------------------------------------
# REQ-NAMEPKG-003 — basic single-name generation
# ---------------------------------------------------------------------------

@testitem "Basic functionality — default dictionaries" begin
    using Test
    using UniqueNamesGenerator
    name = generate_name()
    @test length(name) > 0
    @test length(split(name, " ")) == 3    # <Adj> <Adj> <Noun>
end

@testitem "Custom dictionaries — variable count and order" begin
    using Test
    using UniqueNamesGenerator
    # 2 dicts
    dicts2 = [["a", "b"], ["c", "d"]]
    @test generate_name(dicts2) in ["A C", "A D", "B C", "B D"]
    # 1 dict
    dicts1 = [["hello"]]
    @test generate_name(dicts1) == "Hello"
    # 4 dicts
    dicts4 = [["a"], ["b"], ["c"], ["d"]]
    @test generate_name(dicts4) == "A B C D"
end

@testitem "Empty dictionary throws" begin
    using Test
    using UniqueNamesGenerator
    @test_throws ArgumentError generate_name([String[]])
end

# ---------------------------------------------------------------------------
# REQ-NAMEPKG-005 — styles & separators
# ---------------------------------------------------------------------------

@testitem "Style :capital" begin
    using Test
    using UniqueNamesGenerator
    dicts = [["swift"], ["falcon"]]
    @test generate_name(dicts; style = :capital) == "Swift Falcon"
end

@testitem "Style :uppercase" begin
    using Test
    using UniqueNamesGenerator
    dicts = [["swift"], ["falcon"]]
    @test generate_name(dicts; style = :uppercase) == "SWIFT FALCON"
end

@testitem "Style :lowercase" begin
    using Test
    using UniqueNamesGenerator
    dicts = [["Swift"], ["Falcon"]]
    @test generate_name(dicts; style = :lowercase) == "swift falcon"
end

@testitem "Custom separator" begin
    using Test
    using UniqueNamesGenerator
    dicts = [["a"], ["b"]]
    @test generate_name(dicts; separator = "-") == "A-B"
    @test generate_name(dicts; separator = "_") == "A_B"
end

# ---------------------------------------------------------------------------
# REQ-NAMEPKG-006 — deterministic seeding
# ---------------------------------------------------------------------------

@testitem "Deterministic RNG" begin
    using Test
    using UniqueNamesGenerator
    using Random
    dicts = [["a", "b", "c", "d"], ["e", "f", "g", "h"]]
    rng1 = MersenneTwister(42)
    rng2 = MersenneTwister(42)
    names1 = [generate_name(dicts; rng = rng1) for _ in 1:10]
    names2 = [generate_name(dicts; rng = rng2) for _ in 1:10]
    @test names1 == names2
end

# ---------------------------------------------------------------------------
# REQ-NAMEPKG-003 — batch generation
# ---------------------------------------------------------------------------

@testitem "Batch generation — unique" begin
    using Test
    using UniqueNamesGenerator
    using Random
    dicts = [["a", "b", "c"], ["d", "e", "f"]]
    names = generate_name(dicts, 5; unique = true, rng = MersenneTwister(1))
    @test length(names) == 5
    @test length(unique(lowercase.(names))) == 5   # all distinct (case-insensitive)
end

@testitem "Batch generation — non-unique" begin
    using Test
    using UniqueNamesGenerator
    using Random
    dicts = [["a"], ["b"]]
    names = generate_name(dicts, 5; unique = false)
    @test length(names) == 5
    @test all(n -> n == "A B", names)   # only one combination → all identical
end

# ---------------------------------------------------------------------------
# REQ-NAMEPKG-003 — exclusion set
# ---------------------------------------------------------------------------

@testitem "Exclusion set" begin
    using Test
    using UniqueNamesGenerator
    using Random
    dicts = [["a", "b"], ["c"]]
    exclude = Set(["A C"])
    name = generate_name(dicts, exclude; rng = MersenneTwister(1))
    @test lowercase(name) == "b c"
end

@testitem "Exclusion set — case-insensitive" begin
    using Test
    using UniqueNamesGenerator
    using Random
    dicts = [["a", "b"], ["c"]]
    exclude = Set(["a c"])   # lowercase in exclusion
    name = generate_name(dicts, exclude; rng = MersenneTwister(1))
    @test lowercase(name) == "b c"
end

@testitem "Exclusion set — empty set" begin
    using Test
    using UniqueNamesGenerator
    name = generate_name([["x"], ["y"]], Set{String}())
    @test name == "X Y"
end

# ---------------------------------------------------------------------------
# REQ-NAMEPKG-010 — exhausted name space
# ---------------------------------------------------------------------------

@testitem "Exhausted name space — exclusion" begin
    using Test
    using UniqueNamesGenerator
    dicts = [["a"], ["b"]]
    exclude = Set(["A B"])
    @test_throws UniqueNamesGenerator.ExhaustedNameSpaceError generate_name(dicts, exclude)
end

@testitem "Exhausted name space — batch" begin
    using Test
    using UniqueNamesGenerator
    dicts = [["a"], ["b"]]   # only 1 combination
    @test_throws UniqueNamesGenerator.ExhaustedNameSpaceError generate_name(dicts, 2; unique = true)
end

# ---------------------------------------------------------------------------
# REQ-NAMEPKG-004 — Data Package loading
# ---------------------------------------------------------------------------

@testitem "Built-in dictionaries loaded" begin
    using Test
    using UniqueNamesGenerator
    @test length(ADJECTIVES) >= 80
    @test length(NOUNS) >= 80
    @test length(ANIMALS) > 0
    @test length(COLORS) > 0
end

@testitem "load_dictionary from file" begin
    using Test
    using UniqueNamesGenerator
    # Create a temp CSV and load it
    path = tempname() * ".csv"
    write(path, "word,category\nalpha,a\nbeta,b\ngamma,c\n")
    d = load_dictionary(path)
    @test d == ["alpha", "beta", "gamma"]
    rm(path)
end
