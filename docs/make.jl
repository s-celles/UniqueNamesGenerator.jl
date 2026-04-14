using Documenter
using UniqueNamesGenerator

DocMeta.setdocmeta!(
    UniqueNamesGenerator,
    :DocTestSetup,
    :(using UniqueNamesGenerator);
    recursive = true,
)

makedocs(;
    modules = [UniqueNamesGenerator],
    sitename = "UniqueNamesGenerator.jl",
    repo = Remotes.GitHub("s-celles", "UniqueNamesGenerator.jl"),
    authors = "s-celles <s.celles@gmail.com>",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://s-celles.github.io/UniqueNamesGenerator.jl",
    ),
    pages = [
        "Home" => "index.md",
        "API Reference" => "api.md",
    ],
)

if get(ENV, "CI", "false") == "true"
    deploydocs(;
        repo = "github.com/s-celles/UniqueNamesGenerator.jl",
        devbranch = "main",
        push_preview = true,
    )
end
