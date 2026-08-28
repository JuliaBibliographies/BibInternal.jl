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
    return PackageSuite("BibInternal"; source, environment, versions = :all,
        features = [construction, validation])
end
