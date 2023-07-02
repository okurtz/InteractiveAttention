using
    CSV,
    DataFrames,
    JLD2,
    NamedArrays,
    OrderedCollections,
    Pipe,
    Printf,
    StatsBase;

cd("C:\\Users\\Oliver\\Documents\\Studium\\Psychologie\\Bachelorarbeit\\Skripte");
include("generation_util.jl");

println("Startup completed. Loading data...")

const PREDICTIONS_PER_GAMBLE::Int64 = 1;
const SOURCE_FILE_NAME::String = "data/Study 1/Fiedler_Glöckner_2012_Exp1_transition_matrices";
const OUTPUT_FILE_NAME::String = "data/Study 1/model_forecasts_per_participant.csv";
const GAMBLES::DataFrame = @pipe CSV.read("data/Study 1/Observations_Fiedler_Glöckner_2012_study_1_preprocessed.csv", DataFrame, types=Dict([(:subject, Int64), (:trigger, Int64)]), silencewarnings=false) |>
    _[!, [:subject, :trigger, :AOI]] |> groupby(_, [:subject, :trigger]) |> combine(_, nrow => :numberOfSamples, renamecols=false);
const BETAS::DataFrame = CSV.read("data/Study 1/parameters_10_FiedlerGloeckner2012_EXP1.csv", DataFrame);

allSamplingPaths::DataFrame = DataFrame(generation_util.newSamplingPath(0));
@load SOURCE_FILE_NAME*".jld2" transitionMatrices;  # first index: subject, second index: gamble

println(@sprintf("Starting model data computation using %i threads.", Threads.nthreads()));

for gamble::DataFrameRow{DataFrame, DataFrames.Index} in eachrow(GAMBLES)
    currentBetas::DataFrameRow{DataFrame, DataFrames.SubIndex{DataFrames.Index, Vector{Int64}, Vector{Int64}}} = BETAS[BETAS[!, :subject] .== gamble.subject,:][1, Not(:subject)];
    currentMatrix::NamedMatrix{Float64, Matrix{Float64}, Tuple{OrderedDict{String, Int64}, OrderedDict{String, Int64}}} = transitionMatrices[gamble.subject, gamble.trigger];

    currentSamplingPaths = generation_util.simulate(currentMatrix, currentBetas, gamble, PREDICTIONS_PER_GAMBLE);
    append!(allSamplingPaths, DataFrame(currentSamplingPaths));
    # Hier liegen alle Sampling-Pfade des gegenwärtigen Teilnehmers für das gegenwärtige Spiel vor.

    # Hypothese 3: Durchschnittliche Anzahl der Fixationen pro AOI
    # Hypothese 5: Anteil letztlich gewählten Option in den ersten zwei Dritteln und im letzten Drittel
    # Hypothese 6: Anteil der Samples auf ein Wahrscheinlichkeitsattribut im ersten Fünftel und in den übrigen vier Fünfteln
    # Hypothese 7: Durchschnittliche Anzahl der Fixationsübergänge innerhalb einer Option u. zwischen den Optionen
    println(@sprintf("Simulated %i samples of gamble %i, participant %i.", gamble.numberOfSamples, gamble.trigger, gamble.subject))
end

CSV.write(OUTPUT_FILE_NAME, allSamplingPaths);

println("Run finished.")