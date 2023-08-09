println("Starting up...")
using
    CSV,
    DataFrames,
    JLD2,
    NamedArrays,
    OrderedCollections,
    Printf,
    StatsBase;

cd("C:\\Users\\Oliver\\Documents\\Studium\\Psychologie\\Bachelorarbeit\\Skripte");
include("generation_util.jl");

println("Startup completed. Loading data...")

const STUDY::Int64 = 1;
const PREDICTIONS_PER_GAMBLE::Int64 = 1000;
const MISSING_GAMBLES::Int64 = 4;   # Number of gambles missing from participants that are still included. Do not count missing gambles from participants that were taken out of the sample. Study 1: Gambles 4, 35 and 45 of subject 4, gamble 27 of subject 17
const SOURCE_FILE_NAME::String = "data/Study 1/Fiedler_Glöckner_2012_Exp1_transition_matrices";
const GAMBLES::DataFrame = CSV.read("data/Study 1/Observations_Fiedler_Glöckner_2012_study_1_aggregated.csv", DataFrame, types=Dict([(:optionChosen, Char)]));
const BETAS::DataFrame = CSV.read("data/Study 1/parameters_10_FiedlerGloeckner2012_EXP1.csv", DataFrame);
const NUM_SUBJECTS::Int64 = length(unique(GAMBLES.subject));
const NUM_GAMBLES::Int64 = length(unique(GAMBLES.trigger));
const INITIAL_STRUCTURE_SIZE::Int64 = NUM_SUBJECTS * NUM_GAMBLES - MISSING_GAMBLES;

const hypothesis3Data::NamedTuple = generation_util.newHypothesis3Data(INITIAL_STRUCTURE_SIZE);
const hypothesis5Data::NamedTuple = generation_util.newHypothesis5Data(INITIAL_STRUCTURE_SIZE);
const hypothesis6Data::NamedTuple = generation_util.newHypothesis6Data(INITIAL_STRUCTURE_SIZE);
const hypothesis7Data::NamedTuple = generation_util.newHypothesis7Data(INITIAL_STRUCTURE_SIZE);
const hypothesis7Data_noDuplicateFixations::NamedTuple = generation_util.newHypothesis7Data(INITIAL_STRUCTURE_SIZE);

@load SOURCE_FILE_NAME*".jld2" transitionMatrices;  # first index: subject, second index: gamble

println(@sprintf("Starting model data computation using %i threads.", Threads.nthreads()));

Threads.@threads for gamble::DataFrameRow{DataFrame, DataFrames.Index} in eachrow(GAMBLES)
    currentBetas::DataFrameRow{DataFrame, DataFrames.SubIndex{DataFrames.Index, Vector{Int64}, Vector{Int64}}} = BETAS[BETAS[!, :subject] .== gamble.subject,:][1, Not(:subject)];
    currentMatrix::NamedMatrix{Float64, Matrix{Float64}, Tuple{OrderedDict{String, Int64}, OrderedDict{String, Int64}}} = transitionMatrices[gamble.subject, gamble.trigger];
    currentSamplingPaths::DataFrame = generation_util.simulate(currentMatrix, currentBetas, gamble, PREDICTIONS_PER_GAMBLE);

    currentHypothesis3Data::DataFrameRow{DataFrame, DataFrames.Index} = generation_util.calculateHypothesis3(currentSamplingPaths);
    currentHypothesis5Data::DataFrameRow{DataFrame, DataFrames.Index} = generation_util.calculateHypothesis5(currentSamplingPaths, gamble.optionChosen);
    currentHypothesis6Data::DataFrameRow{DataFrame, DataFrames.Index} = generation_util.calculateHypothesis6(currentSamplingPaths);
    currentHypothesis7Data::DataFrameRow{DataFrame, DataFrames.Index} = generation_util.calculateHypothesis7(currentSamplingPaths);
    currentHypothesis7Data_noDuplicateFixations::DataFrameRow{DataFrame, DataFrames.Index} = generation_util.calculateHypothesis7_noDuplicateFixations(currentSamplingPaths);

    foreach(x -> (global hypothesis3Data[x][rownumber(gamble)] = currentHypothesis3Data[x]), keys(currentHypothesis3Data));
    foreach(x -> (global hypothesis5Data[x][rownumber(gamble)] = currentHypothesis5Data[x]), keys(currentHypothesis5Data));
    foreach(x -> (global hypothesis6Data[x][rownumber(gamble)] = currentHypothesis6Data[x]), keys(currentHypothesis6Data));
    foreach(x -> (global hypothesis7Data[x][rownumber(gamble)] = currentHypothesis7Data[x]), keys(currentHypothesis7Data));
    foreach(x -> (global hypothesis7Data_noDuplicateFixations[x][rownumber(gamble)] = currentHypothesis7Data_noDuplicateFixations[x]), keys(currentHypothesis7Data_noDuplicateFixations));

    println(@sprintf("Thread %i: Simulated %i samples in %i iterations of gamble %i, participant %i.", Threads.threadid(), gamble.numberOfSamples, PREDICTIONS_PER_GAMBLE, gamble.trigger, gamble.subject))
end

println("Simulation finished. Writing results...")
for i in [3, 5, 6, 7]
    rm(@sprintf("data/Study %i/hypothesis_%i_aggregated_data.csv", STUDY, i), force=true);
end
CSV.write(@sprintf("data/Study %i/hypothesis_%i_aggregated_data.csv", STUDY, 3), hypothesis3Data);
CSV.write(@sprintf("data/Study %i/hypothesis_%i_aggregated_data.csv", STUDY, 5), hypothesis5Data);
CSV.write(@sprintf("data/Study %i/hypothesis_%i_aggregated_data.csv", STUDY, 6), hypothesis6Data);
CSV.write(@sprintf("data/Study %i/hypothesis_%i_aggregated_data.csv", STUDY, 7), hypothesis7Data);
CSV.write(@sprintf("data/Study %i/hypothesis_%i_no_duplicate_fixations.csv", STUDY, 7), hypothesis7Data_noDuplicateFixations);

println("Run finished.")