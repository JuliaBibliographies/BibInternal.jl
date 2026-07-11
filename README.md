[![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://Humans-of-Julia.github.io/BibInternal.jl/dev)
[![Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://Humans-of-Julia.github.io/BibInternal.jl/stable)
[![Build Status](https://github.com/Humans-of-Julia/BibInternal.jl/workflows/CI/badge.svg)](https://github.com/Humans-of-Julia/BibInternal.jl/actions)
[![codecov](https://codecov.io/gh/Humans-of-Julia/BibInternal.jl/branch/master/graph/badge.svg?token=zkneHUR45j)](https://codecov.io/gh/Humans-of-Julia/BibInternal.jl)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Discord chat](https://img.shields.io/discord/762167454973296644.svg?logo=discord&colorB=7289DA&style=flat-square)](https://discord.gg/7KC28q98nP)

# BibInternal.jl

This package provides an internal format to translate from/to other bibliographic format.

**!Warning** The support for this package will move to Julia LTS once the next LTS release is available.

All entries depend on an abstract super type `AbstractEntry`.
One generic entry `GenericEntry` is available to make entries without any specific rules.

Versioned rule sets are available for traditional BibTeX and for the BibLaTeX
entry types currently represented by the canonical model. Required fields and
alternatives such as `author`/`editor`, `date`/`year`, and `doi`/`eprint`/`url`
are validated. BibLaTeX's more expressive date syntax is preserved losslessly;
only complete or partial ISO calendar dates (`YYYY`, `YYYY-MM`, and
`YYYY-MM-DD`) are projected onto the canonical `Date` fields.

The BibLaTeX rule set currently supports `article`, `book`, `inbook`,
`incollection`, `inproceedings`, `online`, `proceedings`, `report`, `thesis`,
`unpublished`, and `misc`. Other BibLaTeX entry types produce an
`unknown_entry_type` diagnostic until their canonical representation is
defined.

Pull Requests to add more entries (or update the BibTeX rules) are welcome.

Discussions are welcome either on this GitHub repository or on the `#modern-academics` channel of [Humans of Julia](https://humansofjulia.org/) (to join the Discord server, please click the `chat` badge above).

## Packages using BibInternal.jl
- [BibParser.jl](https://github.com/Humans-of-Julia/BibParser.jl) : A package to parse bibliography files
- [Bibliography.jl](https://github.com/Humans-of-Julia/Bibliography.jl) : A wrapper package to translate from/to different bibliographic formats such as BibTeX, [StaticWebPages.jl](https://github.com/Humans-of-Julia/StaticWebPages.jl), and [DocumenterCitations.jl](https://github.com/ali-ramadhan/DocumenterCitations.jl).
