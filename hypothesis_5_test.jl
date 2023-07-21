using
    CSV,
    DataFrames,
    HypothesisTests,
    Pipe,
    StatsBase;

cd("C:\\Users\\Oliver\\Documents\\Studium\\Psychologie\\Bachelorarbeit\\Skripte");

data = @pipe CSV.read("data/Study 2/hypothesis_5_aggregated_data.csv", DataFrame) |> filter(row -> !(all(ismissing, row[4:13])), _);
groupA = @pipe data[:, 4:10] |> [mean(skipmissing(i)) for i in eachrow(_)];
groupB = @pipe data[:, 11:13] |> [mean(skipmissing(i)) for i in eachrow(_)];
t_test = OneSampleTTest(groupA, groupB);
pvalue(t_test, tail = :right)
confint(t_test)
