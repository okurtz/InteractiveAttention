using 
    CSV,
    DataFrames,
    Pipe,
    Printf,
    StatsBase;

cd("C:\\Users\\Oliver\\Documents\\Studium\\Psychologie\\Bachelorarbeit\\Skripte");

const STUDY::Int8 = 2;
const EMPIRICAL_DATA_FILE_NAME::String = @sprintf("data/Study %i/Observations_Fiedler_Glöckner_2012_study_%i_preprocessed.csv", STUDY, STUDY);
const GAMBLE_DATA_FILE_NAME::String = @sprintf("data/Study %i/Gambles_Fiedler_Glöckner_2012_Study_%i_standardized.csv", STUDY, STUDY);
const CHOICE_COLUMN = STUDY === 1 ? :choice_left : :dec_left;

empiricalData::DataFrame = @pipe CSV.read(EMPIRICAL_DATA_FILE_NAME, DataFrame, types=Dict([(:subject, Int64), (:trigger, Int64)]), silencewarnings=true) |>
    _[!, [:subject, :trigger, :AOI, CHOICE_COLUMN]] |>
    groupby(_, [:subject, :trigger, CHOICE_COLUMN]) |>
    combine(_, nrow => :numberOfSamples, renamecols=false);
gambles::DataFrame = @pipe CSV.read(GAMBLE_DATA_FILE_NAME, DataFrame) |> _[!, [:trigger, :Av1, :Ap1, :Av2, :Ap2, :Bv1, :Bp1, :Bv2, :Bp2]];
empiricalData = innerjoin(empiricalData, gambles, on = :trigger);
empiricalData.EV_A = empiricalData.Av1 .* empiricalData.Ap1 .+ empiricalData.Av2 .* empiricalData.Ap2;
empiricalData.EV_B = empiricalData.Bv1 .* empiricalData.Bp1 .+ empiricalData.Bv2 .* empiricalData.Bp2;
empiricalData.higherEVOption = [row.EV_A > row.EV_B ? "A" : row.EV_B > row.EV_A ? "B" : "none" for row in eachrow(empiricalData)];
empiricalData.optionChosen = [Bool(row[CHOICE_COLUMN]) ? "A" : "B" for row in eachrow(empiricalData)];
empiricalData.higherEVOptionChosen = [Bool(row.higherEVOption === row.optionChosen) for row in eachrow(empiricalData)];
select!(empiricalData, [:subject, :trigger, :numberOfSamples, :higherEVOptionChosen]);
sort!(empiricalData, [:subject, :trigger]);

m = countmap(empiricalData.higherEVOptionChosen)
m[true]/length(empiricalData.higherEVOptionChosen)
mean(empiricalData.numberOfSamples)