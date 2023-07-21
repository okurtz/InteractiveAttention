using
    CSV,
    DataFrames,
    HypothesisTests,
    Pipe,
    StatsBase;

cd("C:\\Users\\Oliver\\Documents\\Studium\\Psychologie\\Bachelorarbeit\\Skripte");

data = @pipe CSV.read("data/Study 2/hypothesis_6_aggregated_data.csv", DataFrame) |> filter(row -> !(all(ismissing, row[3:7])), _);
groupA::Array{Float64} = data[:, 3];
groupB::Array{Float64} = @pipe data[:, 4:7] |> [mean(i) for i in eachrow(_)];
t_test = OneSampleTTest(groupA, groupB);
pvalue(t_test, tail = :left)
confint(t_test)
