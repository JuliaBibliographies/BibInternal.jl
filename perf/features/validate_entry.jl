using BibInternal

function perf_setup()
    fields = Dict("_type" => "article", "title" => "A reusable performance contract",
        "author" => "Ada Lovelace", "journal" => "Julia Studies",
        "volume" => "1", "year" => "2026")
    return BibInternal.make_bibtex_entry("lovelace2026", fields)
end

perf_workload(entry) = BibInternal.validate(entry)
