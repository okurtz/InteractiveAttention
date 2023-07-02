# Creates the transition matrices for each participant, given the participant's beta values, the gambles employed
# in the respective study. Results will be saved as .jld2 as nxm Matrix, where n is the participant number and m is the gamble number.
# The partcipant number is not the same as the participant index as some participants may have been excluded.
# Where no data is available for a given participant number, the transition matrices will be missing in the resulting data structure.
# Script can be run directly. 

using
    CSV,
    DataFrames,
    JLD2,
    JSON3,
    NamedArrays;

include("transition_matrix_creator.jl");

cd("C:\\Users\\Oliver\\Documents\\Studium\\Psychologie\\Bachelorarbeit\\Skripte");

const OBSERVATIONS_FILE_NAME = "data/Study 2/Observations_Fiedler_Glöckner_2012_study_2_preprocessed.csv";
const PARAMETER_FILE_NAME = "data/Study 2/parameters_10_FiedlerGloeckner2012_EXP2.csv";
const OUTPUT_FILE_NAME = "data/Study 2/Fiedler_Glöckner_2012_Exp2_transition_matrices";

const BETAS = CSV.read(PARAMETER_FILE_NAME, DataFrame);
const GAMBLES = transition_matrix_creator.get_gambles();
const OBSERVATIONS = CSV.read(OBSERVATIONS_FILE_NAME, DataFrame);

const numberOfSubjects = maximum(OBSERVATIONS.subject);
const numberOfGambles = maximum(OBSERVATIONS.trigger);
const subjectsWithObservationData = unique(OBSERVATIONS.subject);
const transitionMatrices = Matrix{Union{Matrix{Float64}, Missing}}(missing, numberOfSubjects, numberOfGambles);
currentBetas::DataFrameRow = BETAS[1, Not(:subject)];

for subject in 1:numberOfSubjects
    if(!(subject in subjectsWithObservationData))
        continue;
    end
    for gamble in 1:numberOfGambles
        global currentBetas = BETAS[BETAS[!, :subject] .== subject, :][1, Not(:subject)];
        transitionMatrices[subject, gamble] = transition_matrix_creator.get_transition_matrix(gamble, currentBetas);
    end
end

@save OUTPUT_FILE_NAME*".jld2" transitionMatrices;
println("Run finished");