using
    CSV,
    DataFrames,
    HypothesisTests,
    Pipe,
    StatsBase;

cd("C:\\Users\\Oliver\\Documents\\Studium\\Psychologie\\Bachelorarbeit\\Skripte");

data = @pipe CSV.read("data/Study 1/hypothesis_7_aggregated_data.csv", DataFrame) |> _[!, :fixWithinLottery];
t_test = OneSampleTTest(mean(data), std(data), length(data), 0.5)
pvalue(t_test, tail = :right)
confint(t_test)