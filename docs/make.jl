using Documenter, BibInternal

makedocs(
    sitename = "BibInternal.jl",
    authors = "Jean-François BAFFIER",
    format = Documenter.HTML(
        prettyurls = true,
        canonical = "https://juliabibliographies.github.io/BibInternal.jl",
        edit_link = "master"
    ),
    pages = [
        "Entries" => "index.md",
        "BibTeX" => "bibtex.md",
        "Utilities" => "utilities.md"
    ]
)

deploydocs(;
    repo = "github.com/JuliaBibliographies/BibInternal.jl.git", devbranch = "master")
