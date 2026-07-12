import Pkg
Pkg.develop(path = joinpath(@__DIR__, ".."))
Pkg.instantiate()
using Documenter, BibInternal

makedocs(
    sitename = "BibInternal.jl",
    authors = "Jean-François BAFFIER",
    repo = "https://github.com/Humans-of-Julia/BibInternal.jl/blob/{commit}{path}#L{line}",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    pages = [
        "Entries" => "index.md",
        "BibTeX" => "bibtex.md",
        "Utilities" => "utilities.md"
    ]
)

deploydocs(; repo = "github.com/Humans-of-Julia/BibInternal.jl.git", devbranch = "master")
