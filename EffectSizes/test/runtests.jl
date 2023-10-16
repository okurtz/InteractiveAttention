using Documenter
using EffectSizes
using Test

DocMeta.setdocmeta!(
    EffectSizes,
    :DocTestSetup,
    :(using EffectSizes);
    recursive=true
)

# Only test one Julia version to avoid differences due to changes in printing.
if v"1.6" ≤ VERSION
    EffectSizes._update_module_doc()
    doctest(EffectSizes)
else
    @warn "Skipping doctests"
end

@testset "EffectSizes.jl" begin
    include("test_confint.jl")
    include("test_effectsize.jl")
end
