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

const PREDICTIONS_PER_GAMBLE::Int64 = 1;
const MISSING_GAMBLES::Int64 = 4;   # Gambles 4, 35 and 45 of subject 4, gamble 27 of subject 17.
const SOURCE_FILE_NAME::String = "data/Study 1/Fiedler_Glöckner_2012_Exp1_transition_matrices";
const HYPOTHESIS_3_OUTPUT_FILE_NAME::String = "data/Study 1/hypothesis_3_aggregated_data.csv";
const GAMBLES::DataFrame = CSV.read("data/Study 1/Observations_Fiedler_Glöckner_2012_study_1_preprocessed.csv", DataFrame);
const BETAS::DataFrame = CSV.read("data/Study 1/parameters_10_FiedlerGloeckner2012_EXP1.csv", DataFrame);
const NUM_SUBJECTS = length(unique(GAMBLES.subject));
const NUM_GAMBLES = length(unique(GAMBLES.trigger));

hypothesis3Data::NamedTuple{(:subject, :gamble, :Av1, :Av2, :Bv1, :Bv2), Tuple{Vector{Int64}, Vector{Int64}, Vector{Float64}, Vector{Float64}, Vector{Float64}, Vector{Float64}}} = generation_util.newHypothesis3Data(NUM_SUBJECTS * NUM_GAMBLES - MISSING_GAMBLES);
@load SOURCE_FILE_NAME*".jld2" transitionMatrices;  # first index: subject, second index: gamble

l = Threads.SpinLock();

println(@sprintf("Starting model data computation using %i threads.", Threads.nthreads()));

Threads.@threads for gamble::DataFrameRow{DataFrame, DataFrames.Index} in eachrow(GAMBLES)
    currentBetas::DataFrameRow{DataFrame, DataFrames.SubIndex{DataFrames.Index, Vector{Int64}, Vector{Int64}}} = BETAS[BETAS[!, :subject] .== gamble.subject,:][1, Not(:subject)];
    currentMatrix::NamedMatrix{Float64, Matrix{Float64}, Tuple{OrderedDict{String, Int64}, OrderedDict{String, Int64}}} = transitionMatrices[gamble.subject, gamble.trigger];
    currentSamplingPaths::NamedTuple{(:subject, :gamble, :path, :sample, :AOI), Tuple{Vector{Int64}, Vector{Int64}, Vector{Int64}, Vector{Int64}, Vector{String}}} = generation_util.simulate(currentMatrix, currentBetas, gamble, PREDICTIONS_PER_GAMBLE);
    currentHypothesis3Data::NamedTuple{(:subject, :gamble, :Av1, :Av2, :Bv1, :Bv2), Tuple{Int64, Int64, Float64, Float64, Float64, Float64}} = generation_util.calculateHypothesis3(currentSamplingPaths);

    # Threads.lock(l)
        map(x -> (global hypothesis3Data[x][rownumber(gamble)] = currentHypothesis3Data[x]), keys(currentHypothesis3Data));
    # Threads.unlock(l)
    # Hier liegen alle Sampling-Pfade des gegenwärtigen Teilnehmers für das gegenwärtige Spiel vor.

    # Hypothese 3: Durchschnittliche Anzahl der Fixationen pro AOI
    # Hypothese 5: Anteil letztlich gewählten Option in den ersten zwei Dritteln und im letzten Drittel
    # Hypothese 6: Anteil der Samples auf ein Wahrscheinlichkeitsattribut im ersten Fünftel und in den übrigen vier Fünfteln
    # Hypothese 7: Durchschnittliche Anzahl der Fixationsübergänge innerhalb einer Option u. zwischen den Optionen

    # Ergebnis: Vier Ausgabedateien, eine für jede Hypothese.
    println(@sprintf("Simulated %i samples in %i iterations of gamble %i, participant %i.", gamble.numberOfSamples, PREDICTIONS_PER_GAMBLE, gamble.trigger, gamble.subject))
end

rm(HYPOTHESIS_3_OUTPUT_FILE_NAME, force=true);
CSV.write(HYPOTHESIS_3_OUTPUT_FILE_NAME, hypothesis3Data);

println("Run finished.")