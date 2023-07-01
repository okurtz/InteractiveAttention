# Creates the transition matrices for each participant, given the participant's beta values, the gambles employed
# in the respective study. Results will be saved as .jld2 as nxm Matrix, where n is the participant index and m is the gamble index.
# Script can be run directly. 

using
    CSV,
    DataFrames,
    JLD2,
    JSON3,
    NamedArrays;

include("transition_matrix_creator.jl");

cd("C:\\Users\\Oliver\\Documents\\Studium\\Psychologie\\Bachelorarbeit\\Skripte");

const OUTPUT_FILE_NAME = "data/Study 2/Fiedler_Glöckner_2012_Exp2_transition_matrices";
const BETAS = CSV.read("data/Study 2/parameters_10_FiedlerGloeckner2012_EXP2.csv", DataFrame);
const GAMBLES = transition_matrix_creator.get_gambles();

transitionMatrices = [transition_matrix_creator.get_transition_matrix(gamble, BETAS[participant, Not(:subject)])
    for participant in eachindex(BETAS.subject), gamble in eachindex(GAMBLES.trigger)];

@save OUTPUT_FILE_NAME*".jld2" transitionMatrices;
println("Run finished");