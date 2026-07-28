BibInternal ships the validation rules and normalization helpers that turn a
dictionary of fields into a canonical entry.

Use `make_bibtex_entry` when you want strict BibTeX validation, and
`make_biblatex_entry` when you want BibLaTeX aliases and partial ISO dates to
be normalized before the canonical entry is built.

```@contents
```

```@autodocs
Modules = [BibInternal]
Pages   = ["bibtex.jl", "rules.jl"]
```
