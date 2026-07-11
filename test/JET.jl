@testset "Code linting (JET.jl)" begin
    JET.test_package(BibInternal; target_modules = (BibInternal,))
end
