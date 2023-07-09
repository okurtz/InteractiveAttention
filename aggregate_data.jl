using
    CSV,
    DataFrames,
    NamedArrays,
    Pipe,
    Printf;

cd("C:\\Users\\Oliver\\Documents\\Studium\\Psychologie\\Bachelorarbeit\\Skripte");

const INPUT_FILE_NAME::String = "data/Study 1/Observations_Fiedler_Glöckner_2012_study_1_preprocessed.csv";
const OUTPUT_FILE_NAME::String = "data/Study 1/Observations_Fiedler_Glöckner_2012_study_1_aggregated.csv";

# choice_left in Study 1
# choice_left in Study 2

GAMBLES::DataFrame = @pipe CSV.read(INPUT_FILE_NAME, DataFrame, types=Dict([(:subject, Int64), (:trigger, Int64)]), silencewarnings=true) |>
    _[!, [:subject, :trigger, :AOI, :choice_left]] |> groupby(_, [:subject, :trigger, :choice_left]) |> combine(_, nrow => :numberOfSamples, renamecols=false);
GAMBLES[!,:optionChosen] = [Bool(row.choice_left) ? "A" : "B" for row in eachrow(GAMBLES)];
select!(GAMBLES, Not(:choice_left));
CSV.write(OUTPUT_FILE_NAME, GAMBLES);
println("Run finished.")