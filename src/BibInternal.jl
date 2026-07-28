"""
BibInternal provides the canonical bibliography model shared by the
bibliography stack.

It keeps the core entry types, validation rules, diagnostics, and lossless
document containers in one place so parsers and exporters can share the same
data model.
"""
module BibInternal

"""
Abstract entry supertype.
"""
abstract type AbstractEntry end

# Imports
import TestItems: @testitem

# Includes
include("constant.jl")
include("utilities.jl")
include("bibtex.jl")
include("entry.jl")
include("lossless.jl")
include("field_specs.jl")
include("rules.jl")
include("profiles.jl")

end # module
