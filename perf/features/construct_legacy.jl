using BibInternal

function perf_setup()
    return Dict("title" => "A reusable performance contract",
        "author" => "Ada Lovelace", "journal" => "Julia Studies",
        "volume" => "1", "year" => "2026")
end

function perf_workload(fields)
    BibInternal.BibTeX.make_bibtex_entry(
        "article", "lovelace2026", copy(fields))
end
