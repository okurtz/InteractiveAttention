using
    CSV,
    DataFrames,
    JLD2,
    NamedArrays,
    Pipe,
    Printf,
    StatsBase;

cd("C:\\Users\\Oliver\\Documents\\Studium\\Psychologie\\Bachelorarbeit\\Skripte");
include("transition_matrix_creator.jl");
include("generation_util.jl");

println("Startup completed. Loading data...")

const PREDICTIONS_PER_GAMBLE::Int32 = 1;
const SOURCE_FILE_NAME::String = "data/Study 2/Fiedler_Glöckner_2012_Exp2_transition_matrices";
const OUTPUT_FILE_NAME::String = "data/model_forecasts_per_participant.csv";
const GAMBLES::DataFrame = @pipe CSV.read("data/Study 1/Observations_Fiedler_Glöckner_2012_study_1_preprocessed.csv", DataFrame, types=Dict([(:subject, Int32), (:trigger, Int32)]), silencewarnings=false) |>
    _[!, [:subject, :trigger, :AOI]] |> groupby(_, [:subject, :trigger]) |> combine(_, nrow => :numberOfSamples, renamecols=false);
const SAMPLES::DataFrame = CSV.read("data/Study 1/Observations_Fiedler_Glöckner_2012_study_1_preprocessed.csv", DataFrame);
const BETAS::DataFrame = CSV.read("data/Study 1/parameters_10_FiedlerGloeckner2012_EXP1.csv", DataFrame);

currentState::String = "";
currentBetas::Array{Float64} = [];
samplingPath::Tuple{Int32, Int32, String};

@load SOURCE_FILE_NAME*".jld2" transitionMatrices;  # first index: subject, second index: gamble

println(@sprintf("Starting model data computation using %i threads", Threads.nthreads()));

Threads.@threads for gamble::DataFrameRow{DataFrame, DataFrames.Index} in eachrow(GAMBLES)
    currentBetas = BETAS[BETAS[!, :subject] .== gamble.subject][1, Not(:subject)];
    currentMatrix = transitionMatrices

    for prediction in 1:PREDICTIONS_PER_GAMBLE
        currentState = sample(transition_matrix_creator.TARGETS, Weights(transition_matrix_creator.get_starting_point_probabilities(currentBetas[1], currentBetas[2], currentBetas[3])), 1);
        samplingPath = generation_util.newSamplingPath(gamble.numberOfSamples);
        # currentState in samplingPath einfügen

        for sample in 2:gamble.numberOfSamples
            
            # Dann die Übergangsmatrix des aktuellen Teilnehmers und des aktuellen Gambles number_of_samples-mal verwenden
            # Ergebnis: Ein simulierter Aufmerksamkeitspfad.
            
        end
        # Ich muss die simulierten Daten irgendwie mitteln. Wie mache ich das?
    end
    println(@sprintf("Simulated %i samples of gamble %i, participant %i.", gamble.numberOfSamples, gamble.trigger, gamble.subject))
end

println("Run finished.")