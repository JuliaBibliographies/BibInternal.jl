using PerfChecker

function bibinternal_perf_suite(;
        source = normpath(joinpath(@__DIR__, "..")),
        environment = joinpath(@__DIR__, "runner"))
    construction = FeatureSpec(:construct_entry;
        description = "Construct a normalized article entry",
        backend = :benchmark,
        variants = [
            FeatureVariant(joinpath(@__DIR__, "features", "construct_v010.jl");
                since = v"0.1.0", until = v"0.1.0",
                comparison_key = "entry-construction/v1"),
            FeatureVariant(joinpath(@__DIR__, "features", "construct_legacy.jl");
                since = v"0.1.1", until = v"0.2.0",
                comparison_key = "entry-construction/v1"),
            FeatureVariant(joinpath(@__DIR__, "features", "construct_v02.jl");
                since = v"0.2.1", until = v"0.2.7",
                comparison_key = "entry-construction/v1"),
            FeatureVariant(joinpath(@__DIR__, "features", "construct_entry.jl");
                since = v"0.2.8", comparison_key = "entry-construction/v1")],
        options = Dict(:samples => 20, :evals => 1, :seconds => 0.2))
    validation = FeatureSpec(:validate_entry;
        description = "Validate an entry against the canonical rules",
        entrypoint = joinpath(@__DIR__, "features", "validate_entry.jl"),
        since = v"0.4.0", comparison_key = "entry-validation/v1",
        options = Dict(:samples => 20, :evals => 1, :seconds => 0.2))
    allocation_options = Dict(:targets => ["BibInternal"], :track => "none", :repeat => true)
    construction_allocations = FeatureSpec(:construct_entry_allocations;
        description = "Attribute entry-construction allocations to source file and line",
        backend = :profile_alloc, variants = construction.variants,
        options = allocation_options)
    validation_allocations = FeatureSpec(:validate_entry_allocations;
        description = "Attribute validation allocations to source file and line",
        backend = :profile_alloc, variants = validation.variants,
        options = allocation_options)
    profile_options = Dict(:targets => ["BibInternal"], :track => "none",
        :repeat => true, :profile_seconds => 0.5, :profile_delay => 0.001)
    construction_profile = FeatureSpec(:construct_entry_profile;
        description = "Capture entry-construction CPU call stacks for flame graphs",
        backend = :profile, variants = construction.variants, options = profile_options)
    validation_profile = FeatureSpec(:validate_entry_profile;
        description = "Capture validation CPU call stacks for flame graphs",
        backend = :profile, variants = validation.variants, options = profile_options)
    return PackageSuite("BibInternal"; source, environment, versions = :all,
        features = [construction, validation, construction_allocations,
            validation_allocations, construction_profile, validation_profile])
end
