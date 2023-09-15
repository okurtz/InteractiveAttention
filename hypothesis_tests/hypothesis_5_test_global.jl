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
groupA = map(col -> mean(skipmissing(col)), eachcol(data[data[!, :optionChosen] .== "A", :][!, 4:13]));
groupB = map(col -> mean(skipmissing(col)), eachcol(data[data[!, :optionChosen] .== "B", :][!, 4:13]));
t_test = OneSampleTTest(groupA, 0.5);   # Oder groupB, 0.5
pvalue(t_test, tail = :right)
confint(t_test)
d = EffectSizes.CohenD(groupA, groupB)