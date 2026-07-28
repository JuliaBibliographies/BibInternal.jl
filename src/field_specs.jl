"""
    FieldSpec

Format-independent description of a canonical bibliography field. Parsers and
exporters own source-format mappings; this catalog only describes the semantic
field exposed to downstream consumers.
"""
Base.@kwdef struct FieldSpec
    name::String
    value_kind::Symbol = :text
    repeatable::Bool = false
    description::String = ""
end

function _field_spec(name; value_kind = :text, repeatable = false, description = "")
    FieldSpec(
        name = String(name),
        value_kind = Symbol(value_kind),
        repeatable = Bool(repeatable),
        description = String(description)
    )
end

const _CANONICAL_FIELD_SPECS = FieldSpec[
    _field_spec("abstract"; description = "Abstract or summary."),
    _field_spec("address"; description = "Place associated with publication."),
    _field_spec("annotation"; description = "Source annotation."),
    _field_spec("annote"; description = "BibTeX annotation."),
    _field_spec("archiveprefix"; value_kind = :identifier,
        description = "Archive or repository identifier prefix."),
    _field_spec("author"; value_kind = :names, repeatable = true,
        description = "Ordered author list."),
    _field_spec("booktitle"; description = "Title of the containing book or proceedings."),
    _field_spec("chapter"; description = "Chapter or section identifier."),
    _field_spec("crossref"; value_kind = :identifier,
        description = "Citation key of a related entry."),
    _field_spec("date"; value_kind = :date,
        description = "Publication date, including extended source syntax when preserved."),
    _field_spec("day"; value_kind = :integer, description = "Publication day."),
    _field_spec("doi"; value_kind = :identifier, description = "Digital object identifier."),
    _field_spec("edition"; description = "Edition statement."),
    _field_spec("editor"; value_kind = :names, repeatable = true,
        description = "Ordered editor list."),
    _field_spec("eprint"; value_kind = :identifier,
        description = "Electronic preprint identifier."),
    _field_spec("eventdate"; value_kind = :date, description = "Event date or date range."),
    _field_spec("eventtitle"; description = "Event or conference title."),
    _field_spec("file"; value_kind = :uri, repeatable = true,
        description = "Associated local or remote files."),
    _field_spec("howpublished"; description = "Publication or availability statement."),
    _field_spec("institution"; description = "Responsible institution."),
    _field_spec("isbn"; value_kind = :identifier, repeatable = true,
        description = "International Standard Book Number."),
    _field_spec("issn"; value_kind = :identifier, repeatable = true,
        description = "International Standard Serial Number."),
    _field_spec("journal"; description = "Journal or periodical title."),
    _field_spec("key"; value_kind = :identifier,
        description = "Source-specific sorting or citation key field."),
    _field_spec("labels"; value_kind = :labels, repeatable = true,
        description = "Canonical product-neutral labels."),
    _field_spec("language"; value_kind = :language,
        description = "Language identifier or name."),
    _field_spec("month"; value_kind = :month, description = "Publication month."),
    _field_spec("note"; description = "General note."),
    _field_spec("number"; description = "Issue or report number."),
    _field_spec("organization"; description = "Responsible organization."),
    _field_spec("origdate"; value_kind = :date, description = "Original publication date."),
    _field_spec("pages"; value_kind = :range, description = "Page or locator range."),
    _field_spec("primaryclass"; value_kind = :identifier,
        description = "Primary archive classification."),
    _field_spec("publisher"; description = "Publisher name."),
    _field_spec("school"; description = "Degree-granting institution."),
    _field_spec("series"; description = "Series title."),
    _field_spec("subtitle"; description = "Publication subtitle."),
    _field_spec("title"; description = "Primary title."),
    _field_spec("type"; description = "Publication or report subtype."),
    _field_spec("url"; value_kind = :uri, description = "Online resource URL."),
    _field_spec("urldate"; value_kind = :date, description = "Online access date."),
    _field_spec("version"; description = "Version identifier."),
    _field_spec("volume"; description = "Volume identifier."),
    _field_spec("year"; value_kind = :year, description = "Publication year.")
]

const CANONICAL_FIELD_SPECS = Dict(spec.name => spec for spec in _CANONICAL_FIELD_SPECS)

"""
    canonical_field_specs()

Return the canonical field catalog in stable display order.
"""
canonical_field_specs() = copy(_CANONICAL_FIELD_SPECS)

"""
    field_spec(name)

Return the canonical specification for `name`, or `nothing` for a
source-specific extra field.
"""
function field_spec(name::AbstractString)
    get(CANONICAL_FIELD_SPECS, lowercase(String(name)), nothing)
end

@testitem "Canonical field specifications" tags=[:fields] begin
    import BibInternal
    import Test: @test

    specs = BibInternal.canonical_field_specs()
    @test issorted(getproperty.(specs, :name))
    @test length(specs) == length(unique(getproperty.(specs, :name)))
    @test BibInternal.field_spec("AUTHOR").value_kind == :names
    @test BibInternal.field_spec("labels").repeatable
    @test BibInternal.field_spec("source-specific-extra") === nothing
end
