using
    CSV,
    DataFrames,
    HypothesisTests,
    Pipe,
    StatsBase;

cd("C:\\Users\\Oliver\\Documents\\Studium\\Psychologie\\Bachelorarbeit\\Skripte");
include("../EffectSizes/src/EffectSizes.jl");

data = @pipe CSV.read("data/Study 2/hypothesis_7_aggregated_data.csv", DataFrame) |>
    _[!, Not(:gamble)] |>
    groupby(_, :subject) |>
    combine(_, :fixWithinLottery => mean, renamecols=false) |>
    _[!, :fixWithinLottery];
t_test = OneSampleTTest(data, 0.5)
pvalue(t_test, tail = :right)
confint(t_test)
d = EffectSizes.CohenD(data, fill(0.5, length(data)))