using PerfChecker

include("suite.jl")

function build_suite()
    source = get(ENV, "BIBINTERNAL_PATH", normpath(joinpath(@__DIR__, "..")))
    package = bibinternal_perf_suite(; source,
        environment = joinpath(source, "perf", "runner"))
    return SoftwareSuite(:bibinternal, [package];
        description = "Public performance surface of BibInternal")
end
