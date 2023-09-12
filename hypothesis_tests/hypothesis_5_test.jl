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

data = @pipe CSV.read("data/Study 1/hypothesis_5_aggregated_data.csv", DataFrame) |>
    filter(row -> !(all(ismissing, row[4:13])), _) |>
    _[!, Not(:optionChosen)];
groupA = @pipe data[:, Not(10:12)] |>
    groupby(_, :subject) |>
    combine(_, Symbol("10%") => meanskipmissing, Symbol("20%") => meanskipmissing, Symbol("30%") => meanskipmissing,
        Symbol("40%") => meanskipmissing, Symbol("50%") => meanskipmissing, Symbol("60%") => meanskipmissing,
        Symbol("70%") => meanskipmissing, renamecols=false) |>
    [mean(skipmissing(i)) for i in eachrow(_[!, Not(:subject)])];
groupB = @pipe data[:, Not(3:9)] |>
    groupby(_, :subject) |>
    combine(_, Symbol("80%") => meanskipmissing, Symbol("90%") => meanskipmissing, Symbol("100%") => meanskipmissing, renamecols=false) |>
    [mean(skipmissing(i)) for i in eachrow(_[!, Not(:subject)])];

t_test = OneSampleTTest(groupA, groupB);
pvalue(t_test, tail = :left)
confint(t_test)
d = EffectSizes.CohenD(groupB, groupA)