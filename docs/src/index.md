BibInternal defines the shared bibliography model used by the rest of the
stack.

It keeps two ideas separate:

- the canonical `Entry` view, which is convenient for validation, sorting, and
  export;
- the lossless `BibliographyDocument` view, which also preserves raw source
  blocks, diagnostics, and source spans.

For most users, the entry model is the main surface. If you need to preserve
comments, string macros, or other source-level details, use the lossless
document types instead.

Typical workflow:

```julia
using BibInternal

fields = Dict(
    "_type" => "article",
    "author" => "Lovelace, Ada",
    "journal" => "Notes",
    "title" => "Computing",
    "year" => "1843",
)

entry = make_bibtex_entry("lovelace1843", fields)
result = validate(entry)
```

```@contents
```

```@autodocs
Modules = [BibInternal]
Pages   = ["BibInternal.jl", "entry.jl"]
```
