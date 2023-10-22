println("Starting up...")
using
    CSV,
    DataFrames,
    JLD2,
    NamedArrays,
    OrderedCollections,
    Printf;

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

const hypothesis1Data::NamedTuple = generation_util.newHypothesis1Data(INITIAL_STRUCTURE_SIZE);
const hypothesis2Data::NamedTuple = generation_util.newHypothesis2Data(INITIAL_STRUCTURE_SIZE);
const hypothesis3Data::NamedTuple = generation_util.newHypothesis3Data(INITIAL_STRUCTURE_SIZE);
const hypothesis4Data::NamedTuple = generation_util.newHypothesis4Data(INITIAL_STRUCTURE_SIZE);
const hypothesis4Data_noDuplicateFixations::NamedTuple = generation_util.newHypothesis4Data(INITIAL_STRUCTURE_SIZE);

@load SOURCE_FILE_NAME*".jld2" transitionMatrices;  # first index: subject, second index: gamble

println(@sprintf("Starting model data computation using %i threads.", Threads.nthreads()));

Threads.@threads for gamble::DataFrameRow{DataFrame, DataFrames.Index} in eachrow(GAMBLES)
    currentBetas::DataFrameRow{DataFrame, DataFrames.SubIndex{DataFrames.Index, Vector{Int64}, Vector{Int64}}} = BETAS[BETAS[!, :subject] .== gamble.subject,:][1, Not(:subject)];
    currentMatrix::NamedMatrix{Float64, Matrix{Float64}, Tuple{OrderedDict{String, Int64}, OrderedDict{String, Int64}}} = transitionMatrices[gamble.subject, gamble.trigger];
    currentSamplingPaths::DataFrame = generation_util.simulate(currentMatrix, currentBetas, gamble, PREDICTIONS_PER_GAMBLE);

    currentHypothesis1Data::DataFrameRow{DataFrame, DataFrames.Index} = generation_util.calculateHypothesis1(currentSamplingPaths);
    currentHypothesis2Data::DataFrameRow{DataFrame, DataFrames.Index} = generation_util.calculateHypothesis2(currentSamplingPaths, gamble.optionChosen);
    currentHypothesis3Data::DataFrameRow{DataFrame, DataFrames.Index} = generation_util.calculateHypothesis3(currentSamplingPaths);
    currentHypothesis4Data::DataFrameRow{DataFrame, DataFrames.Index} = generation_util.calculateHypothesis4(currentSamplingPaths);
    currentHypothesis4Data_noDuplicateFixations::DataFrameRow{DataFrame, DataFrames.Index} = generation_util.calculateHypothesis4_noDuplicateFixations(currentSamplingPaths);

    foreach(x -> (global hypothesis1Data[x][rownumber(gamble)] = currentHypothesis1Data[x]), keys(currentHypothesis1Data));
    foreach(x -> (global hypothesis2Data[x][rownumber(gamble)] = currentHypothesis2Data[x]), keys(currentHypothesis2Data));
    foreach(x -> (global hypothesis3Data[x][rownumber(gamble)] = currentHypothesis3Data[x]), keys(currentHypothesis3Data));
    foreach(x -> (global hypothesis4Data[x][rownumber(gamble)] = currentHypothesis4Data[x]), keys(currentHypothesis4Data));
    foreach(x -> (global hypothesis4Data_noDuplicateFixations[x][rownumber(gamble)] = currentHypothesis4Data_noDuplicateFixations[x]), keys(currentHypothesis4Data_noDuplicateFixations));

    println(@sprintf("Thread %i: Simulated %i samples in %i iterations of gamble %i, participant %i.", Threads.threadid(), gamble.numberOfSamples, PREDICTIONS_PER_GAMBLE, gamble.trigger, gamble.subject))
end

println("Simulation finished. Writing results...")
for i in 1:4
    rm(@sprintf("data/Study %i/hypothesis_%i_aggregated_data.csv", STUDY, i), force=true);
end
CSV.write(@sprintf("data/Study %i/hypothesis_%i_aggregated_data.csv", STUDY, 1), hypothesis1Data);
CSV.write(@sprintf("data/Study %i/hypothesis_%i_aggregated_data.csv", STUDY, 2), hypothesis2Data);
CSV.write(@sprintf("data/Study %i/hypothesis_%i_aggregated_data.csv", STUDY, 3), hypothesis3Data);
CSV.write(@sprintf("data/Study %i/hypothesis_%i_aggregated_data.csv", STUDY, 4), hypothesis4Data);
CSV.write(@sprintf("data/Study %i/hypothesis_%i_no_duplicate_fixations.csv", STUDY, 4), hypothesis4Data_noDuplicateFixations);

println("Run finished.")