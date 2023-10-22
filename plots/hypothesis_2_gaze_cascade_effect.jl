using
    CSV,
    DataFrames,
    Plots,
    Pipe,
    Printf,
    StatsBase;

cd("C:\\Users\\Oliver\\Documents\\Studium\\Psychologie\\Bachelorarbeit\\Skripte");

x = range(0.1, 1, step=0.1);

study1Data = @pipe CSV.read("data/Study 1/hypothesis_2_aggregated_data.csv", DataFrame) |> filter(row -> !(all(ismissing, row[4:13])), _);
study2Data = @pipe CSV.read("data/Study 2/hypothesis_2_aggregated_data.csv", DataFrame) |> filter(row -> !(all(ismissing, row[4:13])), _);
study1DecisionLeftData = map(col -> mean(skipmissing(col)), eachcol(study1Data[study1Data[!, :optionChosen] .== "A", :][!, 4:13]));
study1DecisionRightData = map(col -> mean(skipmissing(col)), eachcol(study1Data[study1Data[!, :optionChosen] .== "B", :][!, 4:13]));
study2DecisionLeftData = map(col -> mean(skipmissing(col)), eachcol(study2Data[study2Data[!, :optionChosen] .== "A", :][!, 4:13]));
study2DecisionRightData = map(col -> mean(skipmissing(col)), eachcol(study2Data[study2Data[!, :optionChosen] .== "B", :][!, 4:13]));

plotStudy1 = plot(x, [study1DecisionLeftData, study1DecisionRightData],
    color=:black,
    label=["Entscheidung für linke Lotterie" "Entscheidung für rechte Lotterie"],
    seriestype=:path,
    legend_position=:outerbottom,
    line=1,
    linestyle=[:dash :solid],
    marker=:circle,
    title="Studie 1",
    ylims=(0.48,0.521));
plotStudy2 = plot(x, [study2DecisionLeftData, study2DecisionRightData],
    color=:black,
    label=["Entscheidung für linke Lotterie" "Entscheidung für rechte Lotterie"],
    seriestype=:path,
    legend=false,
    line=1,
    linestyle=[:dash :solid],
    marker=:circle,
    title="Studie 2",
    ylims=(0.48,0.521));
plotTotal = plot(plotStudy1, plotStudy2,
    plot_title="Aufmerksamkeits-Bias",
    gridalpha=0.5,
    legendfontsize=10,
    # legend_position=:outerbottom,
    legend_margin=5*Plots.mm,
    margin=5*Plots.mm,
    xlabel="Anteil der Entscheidungszeit",
    ylabel="Anteil linksseitiger Fixationen",
    size=(900, 525)
);
savefig("../Bachelorarbeit/Grafiken/plot_hypothesis_2.png");