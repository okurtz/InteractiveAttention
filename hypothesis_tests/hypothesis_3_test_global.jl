using
    CSV,
    DataFrames,
    HypothesisTests,
    Pipe,
    StatsBase;

cd("C:\\Users\\Oliver\\Documents\\Studium\\Psychologie\\Bachelorarbeit\\Skripte");
include("../EffectSizes/src/EffectSizes.jl");

meanskipmissing = function(v)
    return mean(skipmissing(v));
end

data = @pipe CSV.read("data/Study 1/hypothesis_3_aggregated_data.csv", DataFrame) |>
    filter(row -> !(all(ismissing, row[3:7])), _) |>
    groupby(_, :subject) |>
    combine(_, Symbol("20%") => meanskipmissing, Symbol("40%") => meanskipmissing, Symbol("60%") => meanskipmissing,
        Symbol("80%") => meanskipmissing, Symbol("100%") => meanskipmissing, renamecols=false) |>
    [mean(skipmissing(i)) for i in eachrow(_[!, Not(:subject)])];

t_test = OneSampleTTest(data, 0.5);
pvalue(t_test, tail = :right)
confint(t_test)
d = EffectSizes.CohenD(data, fill(0.5, length(data)))