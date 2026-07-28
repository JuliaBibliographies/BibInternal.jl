[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaBibliographies.github.io/BibInternal.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaBibliographies.github.io/BibInternal.jl/dev)
[![Build Status](https://github.com/JuliaBibliographies/BibInternal.jl/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/JuliaBibliographies/BibInternal.jl/actions/workflows/ci.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/JuliaBibliographies/BibInternal.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaBibliographies/BibInternal.jl)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# BibInternal.jl

BibInternal is the canonical bibliography model shared by the Humans of Julia
bibliography stack.

It sits between parsers such as `BibParser.jl` and higher-level exporters such
as `Bibliography.jl`. The package exposes the entry model, validation rules,
lossless document containers, and the helpers used to move between raw source
and canonical entries.

**!Warning** The support for this package will move to Julia LTS once the next LTS release is available.

All entries depend on the abstract supertype `AbstractEntry`.
One generic entry type, `Entry`, is available to represent canonical records.

Versioned rule sets are available for BibTeX and BibLaTeX entry types.
Required fields and alternatives such as `author`/`editor`, `date`/`year`, and
`doi`/`eprint`/`url` are validated. BibLaTeX's more expressive date syntax is
preserved losslessly; only complete or partial ISO calendar dates (`YYYY`,
`YYYY-MM`, and `YYYY-MM-DD`) are projected onto the canonical `Date` fields.

The BibLaTeX rule set currently supports `article`, `book`, `inbook`,
`incollection`, `inproceedings`, `online`, `proceedings`, `report`, `thesis`,
`unpublished`, and `misc`. Other BibLaTeX entry types produce an
`unknown_entry_type` diagnostic until their canonical representation is
defined.

If you only need the data model, this package can be used on its own. If you
want a full import/export layer, use `BibParser.jl` and `Bibliography.jl`
instead.

Pull requests to add more entries, more diagnostics, or better documentation
are welcome.

Discussions are welcome on this GitHub repository.

## Packages using BibInternal.jl
- [BibParser.jl](https://github.com/JuliaBibliographies/BibParser.jl) : A package to parse bibliography files
- [Bibliography.jl](https://github.com/JuliaBibliographies/Bibliography.jl) : A wrapper package to translate from/to different bibliographic formats such as BibTeX, [StaticWebPages.jl](https://github.com/Humans-of-Julia/StaticWebPages.jl), and [DocumenterCitations.jl](https://github.com/JuliaDocs/DocumenterCitations.jl).
