[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaBibliographies.github.io/BibInternal.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaBibliographies.github.io/BibInternal.jl/dev)
[![Build Status](https://github.com/JuliaBibliographies/BibInternal.jl/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/JuliaBibliographies/BibInternal.jl/actions/workflows/ci.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/JuliaBibliographies/BibInternal.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaBibliographies/BibInternal.jl)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# BibInternal.jl

This package provides an internal format to translate from/to other bibliographic format.

**!Warning** The support for this package will move to Julia LTS once the next LTS release is available.

All entries depend on an abstract super type `AbstractEntry`.
One generic entry `GenericEntry` is available to make entries without any specific rules.

Currently, only one set of entries following the BibTeX rules is available. *Required* and *optional* BibTeX fields are checked by the constructor.

Pull Requests to add more entries (or update the BibTeX rules) are welcome.

Discussions are welcome on this GitHub repository.

## Packages using BibInternal.jl
- [BibParser.jl](https://github.com/JuliaBibliographies/BibParser.jl) : A package to parse bibliography files
- [Bibliography.jl](https://github.com/JuliaBibliographies/Bibliography.jl) : A wrapper package to translate from/to different bibliographic formats such as BibTeX, [StaticWebPages.jl](https://github.com/Humans-of-Julia/StaticWebPages.jl), and [DocumenterCitations.jl](https://github.com/JuliaDocs/DocumenterCitations.jl).
