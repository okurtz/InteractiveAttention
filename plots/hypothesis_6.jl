using
    CSV,
    DataFrames,
    Plots,
    Pipe,
    Printf,
    StatsBase;

cd("C:\\Users\\Oliver\\Documents\\Studium\\Psychologie\\Bachelorarbeit\\Skripte");

study1Data = @pipe CSV.read("data/Study 1/hypothesis_6_aggregated_data.csv", DataFrame) |>
    _[!, 3:7] |>
    filter(row -> !(all(ismissing, row[1:5])), _) |>
    map(col -> mean(col), eachcol(_));
study2Data = @pipe CSV.read("data/Study 2/hypothesis_6_aggregated_data.csv", DataFrame) |>
    _[!, 3:7] |>
    filter(row -> !(all(ismissing, row[1:5])), _) |>
    map(col -> mean(col), eachcol(_));

x = range(0.2, 1, step=0.2);
plotStudy1 = plot(x, study1Data,
    color=:black,
    seriestype=:path,
    legend=false,
    line=1,
    linestyle=[:solid],
    marker=:circle,
    title="Studie 1",
    ylims=(0.415,0.4351)
    );
plotStudy2 = plot(x, study2Data,
    color=:black,
    seriestype=:path,
    legend=false,
    line=1,
    linestyle=[:solid],
    marker=:circle,
    title="Studie 2",
    ylims=(0.415,0.4351)
    );
plotTotal = plot(plotStudy1, plotStudy2,
    plot_title="Aufmerksamkeits-Bias auf Wahrscheinlichkeitsziele",
    gridalpha=0.5,
    legendfontsize=10,
    margin=5*Plots.mm,
    xlabel="Anteil der Entscheidungszeit",
    ylabel="Anteil der Fixationen auf Wahrscheinlichkeitsziele",
    size=(950, 525)
);
savefig("../Bachelorarbeit/Grafiken/plot_hypothesis_3.svg");