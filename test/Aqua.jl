@testset "Aqua.jl" begin
    Aqua.test_all(BibInternal; deps_compat = false)

    @testset "Dependencies compatibility (no extras)" begin
        Aqua.test_deps_compat(BibInternal; check_extras = false)
    end
end
