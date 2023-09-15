using
    CSV,
    DataFrames,
    HypothesisTests,
    Pipe,
    StatsBase;

cd("C:\\Users\\Oliver\\Documents\\Studium\\Psychologie\\Bachelorarbeit\\Skripte");
include("../EffectSizes/src/EffectSizes.jl");

meanskipmissing = function(itr)
    return mean(skipmissing(itr));
end
data = @pipe CSV.read("data/Study 1/hypothesis_5_aggregated_data.csv", DataFrame) |> filter(row -> !(all(ismissing, row[4:13])), _);
groupA = @pipe data[data[!, :optionChosen] .== "A", :] |>
    select!(_, Not([:gamble, :optionChosen])) |>
    groupby(_, :subject) |>
    combine(_, Symbol("10%") => mean, Symbol("20%") => meanskipmissing, Symbol("30%") => meanskipmissing, Symbol("40%") => meanskipmissing,
        Symbol("50%") => meanskipmissing, Symbol("60%") => meanskipmissing, Symbol("70%") => meanskipmissing, Symbol("80%") => meanskipmissing,
        Symbol("90%") => meanskipmissing, Symbol("100%") => meanskipmissing, renamecols=false);
groupB = @pipe data[data[!, :optionChosen] .== "B", :] |>
    select!(_, Not([:gamble, :optionChosen])) |>
    groupby(_, :subject) |>
    combine(_, Symbol("10%") => mean, Symbol("20%") => meanskipmissing, Symbol("30%") => meanskipmissing, Symbol("40%") => meanskipmissing,
        Symbol("50%") => meanskipmissing, Symbol("60%") => meanskipmissing, Symbol("70%") => meanskipmissing, Symbol("80%") => meanskipmissing,
        Symbol("90%") => meanskipmissing, Symbol("100%") => meanskipmissing, renamecols=false);
groupA = map(row -> mean(skipmissing(Array(row[2:11]))), eachrow(groupA));
groupB = map(row -> mean(skipmissing(Array(row[2:11]))), eachrow(groupB));
t_test = OneSampleTTest(groupA, 0.5);   # Oder groupB, 0.5
pvalue(t_test, tail = :left)
confint(t_test)
d = EffectSizes.CohenD(groupA, groupB)