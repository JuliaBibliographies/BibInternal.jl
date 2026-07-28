"""
    ForbiddenField(name)

Reject a field when it has a value.
"""
struct ForbiddenField <: AbstractBibliographyRule
    name::String
end

"""
    MutuallyExclusiveFields(names)

Allow at most one populated field in the group.
"""
struct MutuallyExclusiveFields <: AbstractBibliographyRule
    names::Tuple{Vararg{String}}
end

function MutuallyExclusiveFields(names::AbstractVector{<:AbstractString})
    MutuallyExclusiveFields(Tuple(String.(names)))
end

"""
    FieldTypeRule(name, value_kind)

Require a populated field to match a canonical value kind such as `:integer`,
`:year`, `:date`, or `:uri`.
"""
struct FieldTypeRule <: AbstractBibliographyRule
    name::String
    value_kind::Symbol
end

"""
    FieldCardinalityRule(name, minimum=0, maximum=nothing)

Constrain the number of values in a structured field. Flat string values count
as one; parsers that preserve multiple values should pass a collection.
"""
struct FieldCardinalityRule <: AbstractBibliographyRule
    name::String
    minimum::Int
    maximum::Union{Nothing, Int}

    function FieldCardinalityRule(
            name::AbstractString,
            minimum::Integer = 0,
            maximum::Union{Nothing, Integer} = nothing
    )
        minimum >= 0 || throw(ArgumentError("minimum cardinality must be non-negative"))
        maximum === nothing || maximum >= minimum ||
            throw(ArgumentError("maximum cardinality must be at least minimum"))
        new(String(name), Int(minimum), isnothing(maximum) ? nothing : Int(maximum))
    end
end

"""
    RuleContext

Context passed to `validate_rule`. Custom rule packages can extend
`validate_rule(rule, fields, context)` for their own
`AbstractBibliographyRule` subtype.
"""
Base.@kwdef struct RuleContext
    profile_name::Symbol
    profile_version::VersionNumber
    entry_id::String = ""
    entry_type::String = "misc"
end

"""
    RuleProfile

Named and versioned set of composable bibliography rules. A `nothing`
`supported_entry_types` value means that the profile accepts every entry type;
it is used for product or institution overlays.
"""
struct RuleProfile
    name::Symbol
    version::VersionNumber
    supported_entry_types::Union{Nothing, Set{String}}
    aliases::Dict{String, String}
    global_rules::Vector{AbstractBibliographyRule}
    entry_rules::Dict{String, Vector{AbstractBibliographyRule}}
    global_fields::Set{String}
    entry_fields::Dict{String, Set{String}}
    diagnostics::Vector{Diagnostic}
end

function RuleProfile(;
        name::Symbol,
        version::VersionNumber = v"1.0.0",
        supported_entry_types::Union{Nothing, AbstractSet} = nothing,
        aliases::AbstractDict = Dict{String, String}(),
        global_rules::AbstractVector = AbstractBibliographyRule[],
        entry_rules::AbstractDict = Dict{String, Vector{AbstractBibliographyRule}}(),
        global_fields::AbstractSet = Set{String}(),
        entry_fields::AbstractDict = Dict{String, Set{String}}(),
        diagnostics::AbstractVector{Diagnostic} = Diagnostic[]
)
    normalized_entry_rules = Dict{String, Vector{AbstractBibliographyRule}}()
    for (entry_type, rules) in pairs(entry_rules)
        normalized_entry_rules[lowercase(String(entry_type))] = AbstractBibliographyRule[rules...]
    end
    normalized_entry_fields = Dict{String, Set{String}}()
    for (entry_type, names) in pairs(entry_fields)
        normalized_entry_fields[lowercase(String(entry_type))] = Set(lowercase.(String.(collect(names))))
    end
    return RuleProfile(
        name,
        version,
        isnothing(supported_entry_types) ?
        nothing : Set(lowercase.(String.(collect(supported_entry_types)))),
        Dict(
            lowercase(String(alias)) => lowercase(String(canonical))
        for (alias, canonical) in pairs(aliases)
        ),
        AbstractBibliographyRule[global_rules...],
        normalized_entry_rules,
        Set(lowercase.(String.(collect(global_fields)))),
        normalized_entry_fields,
        collect(diagnostics)
    )
end

function _requirement_fields(requirement::RequiredField)
    Set([lowercase(requirement.name)])
end

function _requirement_fields(requirement::AlternativeRequiredField)
    Set(lowercase.(collect(requirement.names)))
end

function RuleProfile(ruleset::EntryRuleSet)
    entry_rules = Dict{String, Vector{AbstractBibliographyRule}}()
    entry_fields = Dict{String, Set{String}}()
    for (entry_type, rule) in pairs(ruleset.rules)
        name = lowercase(entry_type)
        entry_rules[name] = AbstractBibliographyRule[rule.required...]
        names = Set(lowercase.(collect(rule.optional)))
        for requirement in rule.required
            union!(names, _requirement_fields(requirement))
        end
        union!(names, values(rule.aliases))
        entry_fields[name] = names
    end
    return RuleProfile(
        name = ruleset.name,
        version = ruleset.version,
        supported_entry_types = Set(keys(ruleset.rules)),
        aliases = ruleset.aliases,
        entry_rules = entry_rules,
        entry_fields = entry_fields
    )
end

const BIBTEX_PROFILE = RuleProfile(BIBTEX_RULESET)
const BIBLATEX_PROFILE = RuleProfile(BIBLATEX_RULESET)

function _profile_diagnostic(
        code::Symbol,
        message::AbstractString;
        field::AbstractString = ""
)
    Diagnostic(
        code = code,
        severity = diagnostic_error,
        message = String(message),
        field = String(field),
        suggestion = "Adjust or remove one of the conflicting rule profiles."
    )
end

function _required_names(rules)
    Set(
        lowercase(rule.name)
    for rule in rules
    if rule isa RequiredField
    )
end

function _forbidden_names(rules)
    Set(
        lowercase(rule.name)
    for rule in rules
    if rule isa ForbiddenField
    )
end

function _profile_rule_conflicts(rules, scope::AbstractString)
    diagnostics = Diagnostic[]
    required = _required_names(rules)
    forbidden = _forbidden_names(rules)
    for name in intersect(required, forbidden)
        push!(
            diagnostics,
            _profile_diagnostic(
                :contradictory_field_rules,
                "Field '$name' is both required and forbidden in $scope.",
                field = name
            )
        )
    end
    for rule in rules
        if rule isa AlternativeRequiredField
            names = Set(lowercase.(collect(rule.names)))
            names ⊆ forbidden && push!(
                diagnostics,
                _profile_diagnostic(
                    :impossible_alternative_requirement,
                    "Every alternative in {$(join(sort!(collect(names)), "|"))} is forbidden in $scope.",
                    field = join(sort!(collect(names)), "|")
                )
            )
        elseif rule isa MutuallyExclusiveFields
            names = Set(lowercase.(collect(rule.names)))
            conflicting = intersect(names, required)
            length(conflicting) > 1 && push!(
                diagnostics,
                _profile_diagnostic(
                    :required_fields_are_mutually_exclusive,
                    "Required fields $(join(sort!(collect(conflicting)), ", ")) are mutually exclusive in $scope.",
                    field = join(sort!(collect(conflicting)), "|")
                )
            )
        end
    end
    type_rules = Dict{String, Set{Symbol}}()
    cardinalities = Dict{String, Vector{FieldCardinalityRule}}()
    for rule in rules
        if rule isa FieldTypeRule
            push!(
                get!(type_rules, lowercase(rule.name), Set{Symbol}()),
                rule.value_kind
            )
        elseif rule isa FieldCardinalityRule
            push!(
                get!(
                    cardinalities,
                    lowercase(rule.name),
                    FieldCardinalityRule[]
                ),
                rule
            )
        end
    end
    for (name, kinds) in pairs(type_rules)
        length(kinds) > 1 && push!(
            diagnostics,
            _profile_diagnostic(
                :contradictory_field_types,
                "Field '$name' has incompatible value kinds $(join(sort!(string.(collect(kinds))), ", ")) in $scope.",
                field = name
            )
        )
    end
    for (name, constraints) in pairs(cardinalities)
        lower_bound = maximum(rule.minimum for rule in constraints)
        finite_maxima = Int[rule.maximum
                            for rule in constraints if !isnothing(rule.maximum)]
        maximum_value = isempty(finite_maxima) ? nothing : minimum(finite_maxima)
        if !isnothing(maximum_value) && lower_bound > maximum_value
            push!(
                diagnostics,
                _profile_diagnostic(
                    :contradictory_field_cardinality,
                    "Field '$name' has incompatible cardinality limits in $scope.",
                    field = name
                )
            )
        end
    end
    return diagnostics
end

"""
    profile_rules(profile, entry_type)

Return global rules followed by rules for the normalized entry type.
"""
function profile_rules(profile::RuleProfile, entry_type::AbstractString)
    vcat(
        profile.global_rules,
        get(
            profile.entry_rules,
            lowercase(String(entry_type)),
            AbstractBibliographyRule[]
        )
    )
end

"""
    profile_field_names(profile, entry_type)

Return fields made available by the profile for an entry type. Custom fields
remain legal unless a profile explicitly forbids them.
"""
function profile_field_names(profile::RuleProfile, entry_type::AbstractString)
    names = copy(profile.global_fields)
    union!(
        names,
        get(profile.entry_fields, lowercase(String(entry_type)), Set{String}())
    )
    for rule in profile_rules(profile, entry_type)
        if rule isa RequiredField || rule isa ForbiddenField ||
           rule isa FieldTypeRule || rule isa FieldCardinalityRule
            push!(names, lowercase(rule.name))
        elseif rule isa AlternativeRequiredField || rule isa MutuallyExclusiveFields
            union!(names, lowercase.(collect(rule.names)))
        end
    end
    return names
end

function _derived_profile_name(profiles)
    Symbol(join(string.(getproperty.(profiles, :name)), "__"))
end

"""
    compose_profiles(profiles...; name)

Compose format, product, and institution profiles. Constraints accumulate.
Conflicts are retained as error diagnostics on the resulting profile rather
than being resolved through precedence.
"""
function compose_profiles(
        profiles::RuleProfile...;
        name::Symbol = _derived_profile_name(profiles)
)
    isempty(profiles) && throw(ArgumentError("At least one rule profile is required"))
    diagnostics = Diagnostic[]
    restricted = [profile.supported_entry_types
                  for profile in profiles
                  if !isnothing(profile.supported_entry_types)]
    supported = if isempty(restricted)
        nothing
    else
        reduce(intersect, restricted)
    end
    if !isnothing(supported) && isempty(supported)
        push!(
            diagnostics,
            _profile_diagnostic(
                :incompatible_entry_type_profiles,
                "The selected profiles have no entry type in common."
            )
        )
    end

    aliases = Dict{String, String}()
    global_rules = AbstractBibliographyRule[]
    entry_rules = Dict{String, Vector{AbstractBibliographyRule}}()
    global_fields = Set{String}()
    entry_fields = Dict{String, Set{String}}()
    for profile in profiles
        append!(diagnostics, profile.diagnostics)
        append!(global_rules, profile.global_rules)
        union!(global_fields, profile.global_fields)
        for (alias, canonical) in pairs(profile.aliases)
            previous = get(aliases, alias, canonical)
            if previous != canonical
                push!(
                    diagnostics,
                    _profile_diagnostic(
                        :contradictory_field_alias,
                        "Alias '$alias' maps to both '$previous' and '$canonical'.",
                        field = alias
                    )
                )
            else
                aliases[alias] = canonical
            end
        end
        for (entry_type, rules) in pairs(profile.entry_rules)
            append!(
                get!(
                    entry_rules,
                    entry_type,
                    AbstractBibliographyRule[]
                ),
                rules
            )
        end
        for (entry_type, names) in pairs(profile.entry_fields)
            union!(get!(entry_fields, entry_type, Set{String}()), names)
        end
    end

    append!(diagnostics, _profile_rule_conflicts(global_rules, "global rules"))
    scopes = isnothing(supported) ?
             union(Set(keys(entry_rules)), Set(keys(entry_fields))) :
             supported
    for entry_type in scopes
        append!(
            diagnostics,
            _profile_rule_conflicts(
                vcat(
                    global_rules,
                    get(
                        entry_rules,
                        entry_type,
                        AbstractBibliographyRule[]
                    )
                ),
                "entry type '$entry_type'"
            )
        )
    end
    unique_diagnostics = unique(
        diagnostic -> (
            diagnostic.code,
            diagnostic.message,
            diagnostic.field
        ),
        diagnostics
    )
    return RuleProfile(
        name = name,
        version = maximum(getproperty.(profiles, :version)),
        supported_entry_types = supported,
        aliases = aliases,
        global_rules = global_rules,
        entry_rules = entry_rules,
        global_fields = global_fields,
        entry_fields = entry_fields,
        diagnostics = unique_diagnostics
    )
end

function _profile_fields(fields::AbstractDict, profile::RuleProfile)
    normalized = Dict{String, Any}()
    for (name, value) in pairs(fields)
        lowered = lowercase(String(name))
        canonical = get(profile.aliases, lowered, lowered)
        normalized[canonical] = value
    end
    return normalized
end

function _has_profile_value(fields::AbstractDict, name::AbstractString)
    value = get(fields, lowercase(String(name)), nothing)
    value === nothing && return false
    value isa AbstractString && return !isempty(strip(value))
    value isa AbstractArray && return !isempty(value)
    return true
end

function _profile_value_count(value)
    value === nothing && return 0
    value isa AbstractString && return isempty(strip(value)) ? 0 : 1
    value isa AbstractArray && return length(value)
    return 1
end

function _matches_value_kind(value, kind::Symbol)
    text = strip(string(value))
    kind in (:text, :identifier, :names, :labels, :range, :month, :language) &&
        return !isempty(text)
    kind == :integer && return tryparse(Int, text) !== nothing
    kind == :year && return occursin(r"^-?\d{1,6}$", text)
    kind == :date && return occursin(r"^-?\d{1,6}(?:-\d{2}(?:-\d{2})?)?(?:/.*)?$", text)
    kind == :uri &&
        return occursin(r"^[A-Za-z][A-Za-z0-9+.-]*:", text)
    return true
end

function _rule_diagnostic(
        context::RuleContext,
        code::Symbol,
        message::AbstractString,
        field::AbstractString;
        suggestion::AbstractString = ""
)
    Diagnostic(
        code = code,
        severity = diagnostic_error,
        message = String(message),
        entry_id = context.entry_id,
        field = String(field),
        suggestion = String(suggestion)
    )
end

function validate_rule(
        rule::RequiredField,
        fields::AbstractDict,
        context::RuleContext
)
    _has_profile_value(fields, rule.name) && return Diagnostic[]
    return Diagnostic[
        _rule_diagnostic(
        context,
        :missing_required_field,
        "Entry $(repr(context.entry_id)) is missing required field $(rule.name).",
        rule.name;
        suggestion = "Add the missing field or change the active rule profiles."
    ),
    ]
end

function validate_rule(
        rule::AlternativeRequiredField,
        fields::AbstractDict,
        context::RuleContext
)
    any(name -> _has_profile_value(fields, name), rule.names) &&
        return Diagnostic[]
    label = "{" * join(rule.names, "|") * "}"
    return Diagnostic[
        _rule_diagnostic(
        context,
        :missing_required_field,
        "Entry $(repr(context.entry_id)) is missing required field $label.",
        label;
        suggestion = "Fill at least one alternative or change the active rule profiles."
    ),
    ]
end

function validate_rule(
        rule::ForbiddenField,
        fields::AbstractDict,
        context::RuleContext
)
    !_has_profile_value(fields, rule.name) && return Diagnostic[]
    return Diagnostic[
        _rule_diagnostic(
        context,
        :forbidden_field,
        "Entry $(repr(context.entry_id)) contains forbidden field $(rule.name).",
        rule.name;
        suggestion = "Remove the field or change the active rule profiles."
    ),
    ]
end

function validate_rule(
        rule::MutuallyExclusiveFields,
        fields::AbstractDict,
        context::RuleContext
)
    present = [name for name in rule.names if _has_profile_value(fields, name)]
    length(present) <= 1 && return Diagnostic[]
    label = join(present, "|")
    return Diagnostic[
        _rule_diagnostic(
        context,
        :mutually_exclusive_fields,
        "Entry $(repr(context.entry_id)) contains mutually exclusive fields $(join(present, ", ")).",
        label;
        suggestion = "Keep only one of the mutually exclusive fields."
    ),
    ]
end

function validate_rule(
        rule::FieldTypeRule,
        fields::AbstractDict,
        context::RuleContext
)
    !_has_profile_value(fields, rule.name) && return Diagnostic[]
    value = get(fields, lowercase(rule.name), nothing)
    values = value isa AbstractArray ? value : Any[value]
    all(item -> _matches_value_kind(item, rule.value_kind), values) &&
        return Diagnostic[]
    return Diagnostic[
        _rule_diagnostic(
        context,
        :invalid_field_value,
        "Field $(rule.name) does not match value kind $(rule.value_kind).",
        rule.name;
        suggestion = "Use a value compatible with the active rule profile."
    ),
    ]
end

function validate_rule(
        rule::FieldCardinalityRule,
        fields::AbstractDict,
        context::RuleContext
)
    count = _profile_value_count(get(fields, lowercase(rule.name), nothing))
    valid = count >= rule.minimum &&
            (isnothing(rule.maximum) || count <= rule.maximum)
    valid && return Diagnostic[]
    range = isnothing(rule.maximum) ?
            "at least $(rule.minimum)" :
            "$(rule.minimum) to $(rule.maximum)"
    return Diagnostic[
        _rule_diagnostic(
        context,
        :invalid_field_cardinality,
        "Field $(rule.name) must contain $range values; found $count.",
        rule.name;
        suggestion = "Adjust the number of values."
    ),
    ]
end

function validate_rule(
        rule::AbstractBibliographyRule,
        ::AbstractDict,
        context::RuleContext
)
    return Diagnostic[
        _rule_diagnostic(
        context,
        :unimplemented_custom_rule,
        "No validator is registered for custom rule $(typeof(rule)).",
        "";
        suggestion = "Extend BibInternal.validate_rule for this rule type."
    ),
    ]
end

"""
    validate_fields(fields, profile; id="")

Validate one entry against a composed rule profile.
"""
function validate_fields(
        fields::AbstractDict,
        profile::RuleProfile;
        id::AbstractString = ""
)
    entry_type = lowercase(
        String(get(fields, "_type", get(fields, "type", "misc"))),
    )
    diagnostics = copy(profile.diagnostics)
    if !isnothing(profile.supported_entry_types) &&
       entry_type ∉ profile.supported_entry_types
        push!(
            diagnostics,
            Diagnostic(
                code = :unknown_entry_type,
                severity = diagnostic_error,
                message = "Unknown $(profile.name) entry type '$entry_type'.",
                entry_id = String(id),
                suggestion = "Use a supported entry type or change the active rule profiles."
            )
        )
        return ValidationResult(diagnostics)
    end
    normalized = _profile_fields(fields, profile)
    context = RuleContext(
        profile_name = profile.name,
        profile_version = profile.version,
        entry_id = String(id),
        entry_type = entry_type
    )
    for rule in profile_rules(profile, entry_type)
        append!(diagnostics, validate_rule(rule, normalized, context))
    end
    return ValidationResult(diagnostics)
end

function validate(entry::Entry, profile::RuleProfile)
    validate_fields(entry_fields(entry), profile; id = entry.id)
end

validate(entry::LosslessEntry, profile::RuleProfile) = validate(entry.canonical, profile)

function validate(document::BibliographyDocument, profile::RuleProfile)
    diagnostics = copy(document.diagnostics)
    for entry in document.entries
        append!(diagnostics, validate(entry, profile).diagnostics)
    end
    return ValidationResult(diagnostics)
end

@testitem "Composable rule profiles" tags=[:profiles] begin
    import BibInternal
    import Test: @test

    catalogue = BibInternal.RuleProfile(
        name = :CuratedCatalogue,
        global_rules = [
            BibInternal.RequiredField("labels"),
            BibInternal.FieldTypeRule("year", :year)
        ],
        global_fields = Set(["labels"])
    )
    combined = BibInternal.compose_profiles(
        BibInternal.BIBTEX_PROFILE,
        catalogue;
        name = :CuratedBibTeX
    )
    @test isempty(combined.diagnostics)
    @test "labels" in BibInternal.profile_field_names(combined, "article")
    @test "journal" in BibInternal.profile_field_names(combined, "article")

    valid = Dict(
        "_type" => "article",
        "author" => "Lovelace, Ada",
        "journal" => "Notes",
        "title" => "Computing",
        "year" => "1843",
        "labels" => "history, computing"
    )
    @test BibInternal.validate_fields(valid, combined; id = "lovelace1843").ok

    missing_labels = copy(valid)
    delete!(missing_labels, "labels")
    result = BibInternal.validate_fields(
        missing_labels,
        combined;
        id = "lovelace1843"
    )
    @test !result.ok
    @test any(
        diagnostic -> diagnostic.code == :missing_required_field &&
                      diagnostic.field == "labels",
        result.diagnostics
    )

    invalid_year = copy(valid)
    invalid_year["year"] = "next year"
    result = BibInternal.validate_fields(invalid_year, combined)
    @test any(
        diagnostic -> diagnostic.code == :invalid_field_value,
        result.diagnostics
    )
end

@testitem "Profile composition reports contradictions" tags=[:profiles] begin
    import BibInternal
    import Test: @test

    required = BibInternal.RuleProfile(
        name = :Required,
        global_rules = [
            BibInternal.RequiredField("labels"),
            BibInternal.RequiredField("doi"),
            BibInternal.RequiredField("url"),
            BibInternal.FieldTypeRule("year", :year),
            BibInternal.FieldCardinalityRule("author", 2, nothing)
        ]
    )
    forbidden = BibInternal.RuleProfile(
        name = :Forbidden,
        global_rules = [
            BibInternal.ForbiddenField("labels"),
            BibInternal.MutuallyExclusiveFields(["doi", "url"]),
            BibInternal.FieldTypeRule("year", :date),
            BibInternal.FieldCardinalityRule("author", 0, 1)
        ]
    )
    composed = BibInternal.compose_profiles(required, forbidden)
    codes = Set(getproperty.(composed.diagnostics, :code))
    @test :contradictory_field_rules in codes
    @test :required_fields_are_mutually_exclusive in codes
    @test :contradictory_field_types in codes
    @test :contradictory_field_cardinality in codes
    @test !BibInternal.validate_fields(
        Dict("_type" => "article"),
        composed
    ).ok
end

@testitem "Custom rules extend validation without changing the model" tags=[:profiles] begin
    import BibInternal
    import Test: @test

    struct StartsWithRule <: BibInternal.AbstractBibliographyRule
        field::String
        prefix::String
    end

    function BibInternal.validate_rule(
            rule::StartsWithRule,
            fields::AbstractDict,
            context::BibInternal.RuleContext
    )
        value = string(get(fields, rule.field, ""))
        startswith(value, rule.prefix) && return BibInternal.Diagnostic[]
        return BibInternal.Diagnostic[
            BibInternal.Diagnostic(
            code = :custom_prefix,
            severity = BibInternal.diagnostic_error,
            message = "Custom prefix rule failed.",
            entry_id = context.entry_id,
            field = rule.field
        ),
        ]
    end

    profile = BibInternal.RuleProfile(
        name = :Custom,
        global_rules = [StartsWithRule("doi", "10.")]
    )
    @test BibInternal.validate_fields(
        Dict("_type" => "misc", "doi" => "10.1234/example"),
        profile
    ).ok
    @test !BibInternal.validate_fields(
        Dict("_type" => "misc", "doi" => "example"),
        profile
    ).ok
end
