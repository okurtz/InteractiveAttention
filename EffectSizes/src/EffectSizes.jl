module EffectSizes

using Statistics
using Distributions
using StatsBase
using SpecialFunctions

import Distributions: quantile
import StatsBase: confint

export
    AbstractEffectSize,
    EffectSize,
    CohenD,
    HedgeG,
    GlassΔ,
    effectsize,
    confint,
    quantile,
    AbstractConfidenceInterval,
    ConfidenceInterval,
    BootstrapConfidenceInterval,
    lower,
    upper

"""
    _update_module_doc()

This function updates the module docs and is called before running the doctests.
This way, the docs in README.md are also tested.
"""
function _update_module_doc()
    path = joinpath(@__DIR__, "..", "README.md")
    text = read(path, String)
    # The code blocks in the README.md should be julia blocks the syntax highlighter.
    text = replace(text, "```julia" => "```jldoctest")
    @doc text EffectSizes
end
_update_module_doc()

include("confidence_interval.jl")
include("effect_size.jl")

end # module
