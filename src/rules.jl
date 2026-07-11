abstract type AbstractFieldRequirement end

"""
    RequiredField(name)

A single required field in an entry rule.
"""
struct RequiredField <: AbstractFieldRequirement
    name::String
end

"""
    AlternativeRequiredField(names)

A requirement where at least one of the listed fields must be present.
"""
struct AlternativeRequiredField <: AbstractFieldRequirement
    names::Tuple{Vararg{String}}
end

AlternativeRequiredField(names::AbstractVector{<:AbstractString}) =
    AlternativeRequiredField(Tuple(String.(names)))

"""
    EntryRule

Validation rule for one source entry type.
"""
Base.@kwdef struct EntryRule
    entry_type::String
    required::Vector{AbstractFieldRequirement} = AbstractFieldRequirement[]
    optional::Set{String} = Set{String}()
    aliases::Dict{String, String} = Dict{String, String}()
end

"""
    EntryRuleSet

Versioned collection of entry validation rules for a bibliography format.
"""
Base.@kwdef struct EntryRuleSet
    name::Symbol
    version::VersionNumber
    rules::Dict{String, EntryRule}
    aliases::Dict{String, String} = Dict{String, String}()
end

"""
    ValidationResult

Result of validating one entry or a bibliography document.
"""
struct ValidationResult
    ok::Bool
    diagnostics::Vector{Diagnostic}
end

ValidationResult(diagnostics::Vector{Diagnostic}) =
    ValidationResult(!any(d -> d.severity == diagnostic_error, diagnostics), diagnostics)

_req(field::AbstractString) = RequiredField(String(field))
_req(fields::Tuple) = AlternativeRequiredField(Tuple(String.(fields)))

function _entry_rule(entry_type::String, required; optional = String[], aliases = Dict{String, String}())
    return EntryRule(
        entry_type = entry_type,
        required = AbstractFieldRequirement[_req(r) for r in required],
        optional = Set(String.(optional)),
        aliases = Dict(String(k) => String(v) for (k, v) in aliases)
    )
end

const _BIBTEX_OPTIONAL_FIELDS = String[
    "address",
    "annote",
    "archiveprefix",
    "chapter",
    "crossref",
    "day",
    "doi",
    "edition",
    "editor",
    "eprint",
    "howpublished",
    "institution",
    "isbn",
    "issn",
    "journal",
    "key",
    "month",
    "note",
    "number",
    "organization",
    "pages",
    "primaryclass",
    "publisher",
    "school",
    "series",
    "title",
    "type",
    "url",
    "volume",
    "year",
]

const BIBTEX_RULESET = EntryRuleSet(
    name = :BibTeX,
    version = v"1.0.0",
    rules = Dict{String, EntryRule}(
        "article" => _entry_rule("article", ["author", "journal", "title", "year"]; optional = _BIBTEX_OPTIONAL_FIELDS),
        "book" => _entry_rule("book", [("author", "editor"), "publisher", "title", "year"]; optional = _BIBTEX_OPTIONAL_FIELDS),
        "booklet" => _entry_rule("booklet", ["title"]; optional = _BIBTEX_OPTIONAL_FIELDS),
        "eprint" => _entry_rule("eprint", ["author", "eprint", "title", "year"]; optional = _BIBTEX_OPTIONAL_FIELDS),
        "inbook" => _entry_rule("inbook", [("author", "editor"), ("chapter", "pages"), "publisher", "title", "year"]; optional = _BIBTEX_OPTIONAL_FIELDS),
        "incollection" => _entry_rule("incollection", ["author", "booktitle", "publisher", "title", "year"]; optional = _BIBTEX_OPTIONAL_FIELDS),
        "inproceedings" => _entry_rule("inproceedings", ["author", "booktitle", "title", "year"]; optional = _BIBTEX_OPTIONAL_FIELDS),
        "manual" => _entry_rule("manual", ["title"]; optional = _BIBTEX_OPTIONAL_FIELDS),
        "mastersthesis" => _entry_rule("mastersthesis", ["author", "school", "title", "year"]; optional = _BIBTEX_OPTIONAL_FIELDS),
        "misc" => _entry_rule("misc", String[]; optional = _BIBTEX_OPTIONAL_FIELDS),
        "phdthesis" => _entry_rule("phdthesis", ["author", "school", "title", "year"]; optional = _BIBTEX_OPTIONAL_FIELDS),
        "proceedings" => _entry_rule("proceedings", ["title", "year"]; optional = _BIBTEX_OPTIONAL_FIELDS),
        "techreport" => _entry_rule("techreport", ["author", "institution", "title", "year"]; optional = _BIBTEX_OPTIONAL_FIELDS),
        "unpublished" => _entry_rule("unpublished", ["author", "note", "title"]; optional = _BIBTEX_OPTIONAL_FIELDS),
    ),
)

const _BIBLATEX_ALIASES = Dict{String, String}(
    "eprinttype" => "archiveprefix",
    "eprintclass" => "primaryclass",
    "journaltitle" => "journal",
    "location" => "address",
)

const _BIBLATEX_OPTIONAL_FIELDS = union(
    Set(_BIBTEX_OPTIONAL_FIELDS),
    Set(String[
        "abstract",
        "addendum",
        "annotation",
        "date",
        "eventdate",
        "eventtitle",
        "file",
        "keywords",
        "language",
        "location",
        "origdate",
        "subtitle",
        "urldate",
        "version",
    ])
)

const BIBLATEX_RULESET = EntryRuleSet(
    name = :BibLaTeX,
    version = v"1.0.0",
    aliases = _BIBLATEX_ALIASES,
    rules = Dict{String, EntryRule}(
        "article" => _entry_rule("article", ["author", "title", "journal", "date"]; optional = collect(_BIBLATEX_OPTIONAL_FIELDS), aliases = _BIBLATEX_ALIASES),
        "book" => _entry_rule("book", [("author", "editor"), "title", "date"]; optional = collect(_BIBLATEX_OPTIONAL_FIELDS), aliases = _BIBLATEX_ALIASES),
        "inbook" => _entry_rule("inbook", [("author", "editor"), "title", "booktitle", "date"]; optional = collect(_BIBLATEX_OPTIONAL_FIELDS), aliases = _BIBLATEX_ALIASES),
        "incollection" => _entry_rule("incollection", ["author", "title", "booktitle", "date"]; optional = collect(_BIBLATEX_OPTIONAL_FIELDS), aliases = _BIBLATEX_ALIASES),
        "inproceedings" => _entry_rule("inproceedings", ["author", "title", "booktitle", "date"]; optional = collect(_BIBLATEX_OPTIONAL_FIELDS), aliases = _BIBLATEX_ALIASES),
        "online" => _entry_rule("online", ["title", "url"]; optional = collect(_BIBLATEX_OPTIONAL_FIELDS), aliases = _BIBLATEX_ALIASES),
        "proceedings" => _entry_rule("proceedings", ["title", "date"]; optional = collect(_BIBLATEX_OPTIONAL_FIELDS), aliases = _BIBLATEX_ALIASES),
        "report" => _entry_rule("report", ["author", "title", "type", "institution", "date"]; optional = collect(_BIBLATEX_OPTIONAL_FIELDS), aliases = _BIBLATEX_ALIASES),
        "thesis" => _entry_rule("thesis", ["author", "title", "type", "institution", "date"]; optional = collect(_BIBLATEX_OPTIONAL_FIELDS), aliases = _BIBLATEX_ALIASES),
        "unpublished" => _entry_rule("unpublished", ["author", "title", "date"]; optional = collect(_BIBLATEX_OPTIONAL_FIELDS), aliases = _BIBLATEX_ALIASES),
        "misc" => _entry_rule("misc", String[]; optional = collect(_BIBLATEX_OPTIONAL_FIELDS), aliases = _BIBLATEX_ALIASES),
    ),
)

function _canonical_field_name(name::AbstractString, ruleset::EntryRuleSet, rule::EntryRule)
    lowered = lowercase(String(name))
    return get(rule.aliases, lowered, get(ruleset.aliases, lowered, lowered))
end

function _normalized_fields(fields::AbstractDict, ruleset::EntryRuleSet, rule::EntryRule)
    normalized = Dict{String, String}()
    for (name, value) in fields
        normalized[_canonical_field_name(name, ruleset, rule)] = String(value)
    end
    return normalized
end

_entry_type(fields::AbstractDict) = lowercase(get(fields, "_type", get(fields, "type", "misc")))

function _missing_requirement(requirement::RequiredField, fields)
    return isempty(get(fields, requirement.name, ""))
end

function _missing_requirement(requirement::AlternativeRequiredField, fields)
    return !any(name -> !isempty(get(fields, name, "")), requirement.names)
end

_requirement_label(requirement::RequiredField) = requirement.name
_requirement_label(requirement::AlternativeRequiredField) = "{" * join(requirement.names, "|") * "}"

function validate_fields(fields::AbstractDict, ruleset::EntryRuleSet; id::AbstractString = "")
    entry_type = _entry_type(fields)
    diagnostics = Diagnostic[]
    if !haskey(ruleset.rules, entry_type)
        push!(
            diagnostics,
            Diagnostic(
                code = :unknown_entry_type,
                severity = diagnostic_error,
                message = "Unknown $(ruleset.name) entry type '$entry_type'.",
                entry_id = String(id),
                suggestion = "Use a known entry type or validate with a more permissive ruleset."
            )
        )
        return ValidationResult(diagnostics)
    end

    rule = ruleset.rules[entry_type]
    normalized = _normalized_fields(fields, ruleset, rule)
    for requirement in rule.required
        if _missing_requirement(requirement, normalized)
            push!(
                diagnostics,
                Diagnostic(
                    code = :missing_required_field,
                    severity = diagnostic_error,
                    message = "Entry $(repr(String(id))) is missing required field $(_requirement_label(requirement)).",
                    entry_id = String(id),
                    field = _requirement_label(requirement),
                    suggestion = "Add the missing field or change the entry type."
                )
            )
        end
    end
    return ValidationResult(diagnostics)
end

function entry_fields(entry::Entry)
    data = Dict{String, String}(entry.fields)
    data["_type"] = entry.type
    data["author"] = join(
        map(n -> join(filter(!isempty, [n.particle, n.last, n.junior, n.first, n.middle]), " "), entry.authors),
        " and "
    )
    data["booktitle"] = entry.booktitle
    data["day"] = entry.date.day
    data["month"] = entry.date.month
    data["year"] = entry.date.year
    data["editor"] = join(
        map(n -> join(filter(!isempty, [n.particle, n.last, n.junior, n.first, n.middle]), " "), entry.editors),
        " and "
    )
    data["doi"] = entry.access.doi
    data["howpublished"] = entry.access.howpublished
    data["url"] = entry.access.url
    data["archiveprefix"] = entry.eprint.archive_prefix
    data["eprint"] = entry.eprint.eprint
    data["primaryclass"] = entry.eprint.primary_class
    data["note"] = entry.note
    data["title"] = entry.title
    data["address"] = entry.in.address
    data["chapter"] = entry.in.chapter
    data["edition"] = entry.in.edition
    data["institution"] = entry.in.institution
    data["isbn"] = entry.in.isbn
    data["issn"] = entry.in.issn
    data["journal"] = entry.in.journal
    data["number"] = entry.in.number
    data["organization"] = entry.in.organization
    data["pages"] = entry.in.pages
    data["publisher"] = entry.in.publisher
    data["school"] = entry.in.school
    data["series"] = entry.in.series
    data["volume"] = entry.in.volume
    return data
end

validate(entry::Entry, ruleset::EntryRuleSet = BIBTEX_RULESET) =
    validate_fields(entry_fields(entry), ruleset; id = entry.id)

validate(entry::LosslessEntry, ruleset::EntryRuleSet = BIBTEX_RULESET) =
    validate(entry.canonical, ruleset)

function validate(document::BibliographyDocument, ruleset::EntryRuleSet)
    diagnostics = copy(document.diagnostics)
    for entry in document.entries
        append!(diagnostics, validate(entry, ruleset).diagnostics)
    end
    return ValidationResult(diagnostics)
end

function handle_validation(result::ValidationResult, level)
    level in (:none, nothing, false) && return result
    for diagnostic in result.diagnostics
        diagnostic.severity == diagnostic_error || level == :warn || continue
        msg = diagnostic.message
        if !isempty(diagnostic.suggestion)
            msg *= " Suggestion: $(diagnostic.suggestion)"
        end
        if level == :error && diagnostic.severity == diagnostic_error
            error(msg)
        elseif level == :warn
            @warn msg
        end
    end
    return result
end

@testitem "Rulesets and validation" tags=[:rules] begin
    import BibInternal

    valid = Dict(
        "_type" => "article",
        "author" => "Lovelace, Ada",
        "journal" => "Notes",
        "title" => "Computing",
        "year" => "1843",
    )
    result = BibInternal.validate_fields(valid, BibInternal.BIBTEX_RULESET; id = "lovelace1843")
    @test result.ok
    @test isempty(result.diagnostics)

    missing = copy(valid)
    delete!(missing, "journal")
    result = BibInternal.validate_fields(missing, BibInternal.BIBTEX_RULESET; id = "missing")
    @test !result.ok
    @test length(result.diagnostics) == 1
    @test result.diagnostics[1].code == :missing_required_field
    @test result.diagnostics[1].field == "journal"

    biblatex = Dict(
        "_type" => "article",
        "author" => "Lovelace, Ada",
        "journaltitle" => "Notes",
        "title" => "Computing",
        "date" => "1843",
    )
    result = BibInternal.validate_fields(biblatex, BibInternal.BIBLATEX_RULESET; id = "lovelace1843")
    @test result.ok
end
