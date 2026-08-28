using BibInternal

function perf_setup()
    return Dict("_type" => "article", "title" => "A reusable performance contract",
        "author" => "Ada Lovelace", "journal" => "Julia Studies",
        "volume" => "1", "year" => "2026")
end

perf_workload(fields) = BibInternal.make_bibtex_entry("lovelace2026", copy(fields))
