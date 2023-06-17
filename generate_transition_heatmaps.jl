using
    CSV,
    DataFrames,
    JLD2,
    NamedArrays,
    Pipe,
    PlotlyJS,
    Printf;

include("transition_matrix_creator.jl");

cd("data/Study 1");

const INPUT_FILE_NAME = "Fiedler_Glöckner_2012_Exp1_transition_matrices";
const OUTPUT_DIR = "heatmaps/";
const GAMBLE_NUMBERS = @pipe CSV.read("Gambles_Fiedler_Glöckner_2012_Study_1_standardized.csv", DataFrame) |> _[:, :trigger];
const PARTICIPANT_NUMBERS = @pipe CSV.read("parameters_10_FiedlerGloeckner2012_EXP1.csv", DataFrame) |> _[:, :subject];
@load INPUT_FILE_NAME*".jld2" transitionMatrices;

for participantIndex in eachindex(PARTICIPANT_NUMBERS), gambleIndex in eachindex(GAMBLE_NUMBERS)
    fig = plot(heatmap(
        x=transition_matrix_creator.TARGETS,
        y=transition_matrix_creator.TARGETS,
        z=transitionMatrices[participantIndex, gambleIndex]),
        Layout(
            title=@sprintf("Study 1, participant %i, gamble %i", PARTICIPANT_NUMBERS[participantIndex], GAMBLE_NUMBERS[gambleIndex]),
            xaxis_side="top"
        )
    );
    savefig(fig, @sprintf("%s/participant %i, gamble %i.png", OUTPUT_DIR, PARTICIPANT_NUMBERS[participantIndex], GAMBLE_NUMBERS[gambleIndex]));
end
println("Run finished")