const Required = Union{String, Tuple{String, String}}

"""
    const rules = Dict([
        "article"       => ["author", "journal", "title", "year"]
        "book"          => [("author", "editor"), "publisher", "title", "year"]
        "booklet"       => ["title"]
        "eprint"        => ["author", "eprint", "title", "year"]
        "inbook"        => [("author", "editor"), ("chapter", "pages"), "publisher", "title", "year"]
        "incollection"  => ["author", "booktitle", "publisher", "title", "year"]
        "inproceedings" => ["author", "booktitle", "title", "year"]
        "manual"        => ["title"]
        "mastersthesis" => ["author", "school", "title", "year"]
        "misc"          => []
        "phdthesis"     => ["author", "school", "title", "year"]
        "proceedings"   => ["title", "year"]
        "techreport"    => ["author", "institution", "title", "year"]
        "unpublished"   => ["author", "note", "title"]
    ])
List of BibTeX rules bases on the entry type. A field value as a singleton represents a required field. A pair of values represents mutually exclusive required fields.
"""
const rules = Dict{String, Vector{Required}}(
    ["article" => ["author", "journal", "title", "year"]
     "book" => [("author", "editor"), "publisher", "title", "year"]
     "booklet" => ["title"]
     "eprint" => ["author", "eprint", "title", "year"]
     "inbook" => [("author", "editor"), ("chapter", "pages"), "publisher", "title", "year"]
     "incollection" => ["author", "booktitle", "publisher", "title", "year"]
     "inproceedings" => ["author", "booktitle", "title", "year"]
     "manual" => ["title"]
     "mastersthesis" => ["author", "school", "title", "year"]
     "misc" => []
     "phdthesis" => ["author", "school", "title", "year"]
     "proceedings" => ["title", "year"]
     "techreport" => ["author", "institution", "title", "year"]
     "unpublished" => ["author", "note", "title"]],
)

"""
    check_entry(fields::Fields)
Check the validity of the fields of a BibTeX entry.
"""
function check_entry(fields, check, id)
    errors = Vector{String}()

    entry_type = get(fields, "_type", "misc")
    if entry_type ∉ keys(rules)
        if check ∈ [:error, :warn]
            @warn """KeyError: key "software" not found in BibTeX rules, parsed from the entry `$id` with""" fields
        end
        check == :error && throw(KeyError(entry_type))
    end

    for t_field in get(rules, entry_type, Vector{Required}())
        at_least_one = false
        if typeof(t_field) == Tuple{String, String}
            for field in t_field
                if get(fields, field, "") != ""
                    at_least_one = true
                    break
                end
            end
            if !at_least_one
                s = foldl((x, y) -> "$x≡$y", t_field; init = "")
                # To remove the starting `≡`, we need `nextind` as it is a
                # multibyte character
                push!(errors, "{" * s[nextind(s, 1):end] * "}")
            end
        else
            get(fields, t_field, "") == "" && push!(errors, t_field)
        end
    end

    return errors
end

"""
    make_bibtex_entry(id::String, fields::Fields)
Make an entry if the entry follows the BibTeX guidelines. Throw an error otherwise.
"""
function make_bibtex_entry(id, fields; check = :error)
    # @info id fields
    fields = Dict(lowercase(k) => v for (k, v) in fields) # lowercase tag names
    errors = check_entry(fields, check, id)
    if length(errors) > 0 && check ∈ [:error, :warn]
        message = "Entry $id is missing the " *
                  foldl(((x, y) -> x * ", " * y), errors) *
                  " field(s)."
        check == :error ? (error(message)) : (@warn message)
    end
    return Entry(id, fields)
end

function _normalize_biblatex_date!(fields)
    date = get(fields, "date", "")
    isempty(date) && return fields
    # The canonical Date view supports complete or partial ISO calendar dates.
    # More expressive BibLaTeX date syntax remains preserved in fields["date"].
    m = match(r"^(\d{4})(?:-(0?[1-9]|1[0-2])(?:-(0?[1-9]|[12]\d|3[01]))?)?$", date)
    isnothing(m) && return fields
    haskey(fields, "year") || (fields["year"] = something(m.captures[1], ""))
    haskey(fields, "month") || (fields["month"] = something(m.captures[2], ""))
    haskey(fields, "day") || (fields["day"] = something(m.captures[3], ""))
    return fields
end

function _normalize_biblatex_aliases!(fields)
    aliases = Dict(
        "journaltitle" => "journal",
        "eprinttype" => "archiveprefix",
        "eprintclass" => "primaryclass",
        "location" => "address"
    )
    for (alias, canonical) in aliases
        if haskey(fields, alias) && !haskey(fields, canonical)
            fields[canonical] = fields[alias]
        end
    end
    return fields
end

"""
    make_biblatex_entry(id::String, fields::Fields; check = :error)

Make an entry using BibLaTeX field aliases and date conventions while
preserving source-specific fields that are not part of the canonical view.
"""
function make_biblatex_entry(id, fields; check = :error)
    fields = Dict(lowercase(k) => v for (k, v) in fields)
    validation = validate_fields(fields, BIBLATEX_RULESET; id)
    handle_validation(validation, check)
    _normalize_biblatex_aliases!(fields)
    _normalize_biblatex_date!(fields)
    return Entry(id, fields)
end

@testitem "BibTeX and BibLaTeX constructors" tags=[:bibtex] begin
    import BibInternal

    @testset "BibTeX checking" begin
        fields = Dict(
            "_TYPE" => "book",
            "EDITOR" => "Lovelace, Ada",
            "PUBLISHER" => "Publisher",
            "TITLE" => "Notes",
            "YEAR" => "1843"
        )
        entry = BibInternal.make_bibtex_entry("book", fields)
        @test entry.type == "book"
        @test isempty(entry.authors)
        @test only(entry.editors).last == "Lovelace"
        @test_throws ErrorException BibInternal.make_bibtex_entry(
            "bad", Dict("_type" => "article", "title" => "Incomplete")
        )
        @test_logs (:warn, r"missing") BibInternal.make_bibtex_entry(
            "bad", Dict("_type" => "article", "title" => "Incomplete"); check = :warn
        )
        @test_logs (:warn, r"KeyError") begin
            @test_throws KeyError BibInternal.make_bibtex_entry(
                "bad", Dict("_type" => "software", "title" => "Program")
            )
        end
    end

    @testset "BibLaTeX date normalization" begin
        base = Dict(
            "_type" => "online",
            "author" => "Doe, Jane",
            "title" => "Dataset",
            "url" => "https://example.test"
        )
        for (date, expected) in (
            "2024" => BibInternal.Date("", "", "2024"),
            "2024-3" => BibInternal.Date("", "3", "2024"),
            "2024-03-15" => BibInternal.Date("15", "03", "2024")
        )
            entry = BibInternal.make_biblatex_entry(
                date, merge(base, Dict("date" => date))
            )
            @test entry.date == expected
        end

        for date in ("2024-00", "2024-13", "2024-02-32", "2024-03-15junk")
            entry = BibInternal.make_biblatex_entry(
                date, merge(base, Dict("date" => date))
            )
            @test entry.date == BibInternal.Date("", "", "")
            @test entry.fields["date"] == date
        end

        entry = BibInternal.make_biblatex_entry(
            "canonical-wins",
            merge(
                base,
                Dict(
                    "date" => "2024",
                    "location" => "Alias",
                    "address" => "Canonical"
                )
            )
        )
        @test entry.in.address == "Canonical"
        @test entry.fields["location"] == "Alias"
    end
end
