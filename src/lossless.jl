"""
    @enum DiagnosticSeverity diagnostic_info diagnostic_warning diagnostic_error

Severity level for structured diagnostics emitted while parsing, normalizing, or
validating bibliography data.
"""
@enum DiagnosticSeverity begin
    diagnostic_info
    diagnostic_warning
    diagnostic_error
end

"""
    SourceSpan

Optional source location for raw bibliography content and diagnostics.
The span uses 1-based inclusive coordinates.
"""
Base.@kwdef struct SourceSpan
    file::String = ""
    start_line::Int = 0
    start_column::Int = 0
    end_line::Int = 0
    end_column::Int = 0
end

"""
    Diagnostic

Structured message attached to a bibliography document, raw entry, or field.
The `suggestion` field is intentionally textual for now so command line tools
and future GUIs can present a friendly next action without depending on a fix
engine.
"""
Base.@kwdef struct Diagnostic
    code::Symbol
    severity::DiagnosticSeverity = diagnostic_warning
    message::String
    span::Union{Nothing, SourceSpan} = nothing
    entry_id::String = ""
    field::String = ""
    suggestion::String = ""
end

"""
    RawField

Lossless representation of a parsed field.

`name` and `value` contain the interpreted field pair, while `raw` preserves
the source representation. `span` and `diagnostics` are optional metadata
collected by parsers that keep source locations.
"""
Base.@kwdef struct RawField
    name::String
    value::String
    raw::String = ""
    span::Union{Nothing, SourceSpan} = nothing
    diagnostics::Vector{Diagnostic} = Diagnostic[]
end

"""
    RawEntry

Lossless representation of a parsed bibliography entry. `kind` is the source
entry type, `key` is the citation key when the format has one, and `fields`
preserves source order.
"""
Base.@kwdef struct RawEntry
    kind::String
    key::String = ""
    fields::Vector{RawField} = RawField[]
    raw::String = ""
    span::Union{Nothing, SourceSpan} = nothing
    diagnostics::Vector{Diagnostic} = Diagnostic[]
    metadata::Dict{Symbol, Any} = Dict{Symbol, Any}()
end

"""
    RawBlock

Top-level source block that is not necessarily a bibliographic entry, such as a
BibTeX comment, preamble, string definition, or free text.
"""
Base.@kwdef struct RawBlock
    kind::Symbol
    raw::String
    key::String = ""
    span::Union{Nothing, SourceSpan} = nothing
    metadata::Dict{Symbol, Any} = Dict{Symbol, Any}()
end

"""
    LosslessEntry

Pair a stable canonical `Entry` with the raw source entry and diagnostics used
to build it. This keeps existing consumers on `Entry` while enabling parsers and
writers to preserve source information.
"""
struct LosslessEntry <: AbstractEntry
    canonical::Entry
    raw::RawEntry
    diagnostics::Vector{Diagnostic}
end

LosslessEntry(canonical::Entry, raw::RawEntry) = LosslessEntry(canonical, raw, Diagnostic[])

"""
    BibliographyDocument

Lossless document-level container returned by parsers that need to preserve
ordering, non-entry blocks, and parse diagnostics.
"""
Base.@kwdef struct BibliographyDocument
    format::Symbol
    entries::Vector{LosslessEntry} = LosslessEntry[]
    blocks::Vector{RawBlock} = RawBlock[]
    diagnostics::Vector{Diagnostic} = Diagnostic[]
    source::String = ""
    metadata::Dict{Symbol, Any} = Dict{Symbol, Any}()
end

"""
    canonical(entry)

Return the canonical `Entry` view of an entry-like object.
"""
canonical(entry::Entry) = entry
canonical(entry::LosslessEntry) = entry.canonical

"""
    raw(entry)

Return the raw source representation attached to a lossless entry.
"""
raw(entry::LosslessEntry) = entry.raw

"""
    diagnostics(entry)

Return the diagnostics attached to a lossless entry or document.
"""
diagnostics(entry::LosslessEntry) = entry.diagnostics
diagnostics(document::BibliographyDocument) = document.diagnostics

function Base.getproperty(entry::LosslessEntry, name::Symbol)
    if name in (:canonical, :raw, :diagnostics)
        return getfield(entry, name)
    end
    return getproperty(getfield(entry, :canonical), name)
end

@testitem "Lossless model" tags=[:lossless] begin
    import BibInternal

    fields = Dict(
        "_type" => "article",
        "author" => "Lovelace, Ada",
        "journal" => "Notes",
        "title" => "Computing",
        "year" => "1843"
    )
    entry = BibInternal.Entry("lovelace1843", copy(fields))
    raw = BibInternal.RawEntry(
        kind = "article",
        key = "lovelace1843",
        fields = [BibInternal.RawField(
            name = "title", value = "Computing", raw = "title = {Computing}")],
        raw = "@article{lovelace1843,...}"
    )
    wrapped = BibInternal.LosslessEntry(entry, raw)

    @test BibInternal.canonical(wrapped) === entry
    @test BibInternal.raw(wrapped) === raw
    @test wrapped.id == "lovelace1843"
    @test wrapped.title == "Computing"
    @test isempty(BibInternal.diagnostics(wrapped))

    span = BibInternal.SourceSpan(
        file = "refs.bib", start_line = 1, start_column = 1, end_line = 3, end_column = 2
    )
    diagnostic = BibInternal.Diagnostic(
        code = :duplicate_field,
        message = "Duplicate title",
        span = span,
        entry_id = "lovelace1843",
        field = "title"
    )
    wrapped_with_diagnostic = BibInternal.LosslessEntry(entry, raw, [diagnostic])
    document = BibInternal.BibliographyDocument(
        format = :bibtex,
        entries = [wrapped_with_diagnostic],
        blocks = [BibInternal.RawBlock(
            kind = :comment, raw = "@comment{kept}", span = span)],
        source = "refs.bib"
    )
    @test BibInternal.canonical(entry) === entry
    @test only(BibInternal.diagnostics(wrapped_with_diagnostic)) === diagnostic
    @test isempty(BibInternal.diagnostics(document))
    @test only(document.blocks).raw == "@comment{kept}"
    @test diagnostic.span.start_line == 1
end
