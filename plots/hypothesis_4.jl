using
    CSV,
    DataFrames,
    Pipe,
    PlotlyJS;

cd("C:\\Users\\Oliver\\Documents\\Studium\\Psychologie\\Bachelorarbeit\\Skripte");

study1Data = @pipe CSV.read("data/Study 1/hypothesis_4_no_duplicate_fixations.csv", DataFrame, select=[:fixWithinLottery]);
study2Data = @pipe CSV.read("data/Study 2/hypothesis_4_no_duplicate_fixations.csv", DataFrame, select=[:fixWithinLottery]);
study1Data.study .= "Studie 1";
study2Data.study .= "Studie 2";
plotData = append!(study1Data, study2Data)

boxplot = plot(
    plotData,
    x = :study,
    y = :fixWithinLottery,
    kind="box",
    labels = Dict(
        :study => "",
        :fixWithinLottery => "Anteil Fixationsübergänge innerhalb einer Lotterie"
    ),
    Layout(
        # title = attr(
        #     text = "Verteilung der Fixationsübergänge innerhalb einer Lotterie -<br>keine doppelten Fixationen",
        #     x = 0.5,
        #     xanchor = "center"
        # ),
        plot_bgcolor = "white",
        colorway = ["black"],
        yaxis = attr(
            showgrid = true,
            zeroline = true,
            showline = true,
            gridcolor = "#bdbdbd",
            gridwidth = 2,
            zerolinecolor = "#969696",
            zerolinewidth = 2,
            linecolor = "#636363",
            linewidth = 2,
            tickmode = "linear",
            tick0 = 0.5,
            dtick = 0.05,
            font = attr(
                size = 20
            )
        ),
        font = attr(
            size = 20
        ),
        xaxis = attr(
                font = attr(
                size = 20
            )
        )
    )
);
savefig(boxplot, "../Bachelorarbeit/Grafiken/plot_hypothesis_4_no_duplicate_fixations.png");