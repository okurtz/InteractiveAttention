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

data = @pipe CSV.read("data/Study 2/hypothesis_6_aggregated_data.csv", DataFrame) |>
    filter(row -> !(all(ismissing, row[3:7])), _) |>
    groupby(_, :subject) |>
    combine(_, Symbol("20%") => meanskipmissing, Symbol("40%") => meanskipmissing, Symbol("60%") => meanskipmissing,
        Symbol("80%") => meanskipmissing, Symbol("100%") => meanskipmissing, renamecols=false);

groupA = data[:, 2];
groupB = @pipe data[:, 3:6] |> [mean(i) for i in eachrow(_)];
t_test = OneSampleTTest(groupA, groupB);
pvalue(t_test, tail = :right)
confint(t_test)
d = EffectSizes.CohenD(groupA, groupB)