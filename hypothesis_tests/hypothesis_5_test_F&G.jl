using
    CSV,
    DataFrames,
    HypothesisTests,
    Pipe,
    StatsBase;

cd("C:\\Users\\Oliver\\Documents\\Studium\\Psychologie\\Bachelorarbeit\\Skripte");
include("../generation_util.jl");
const INPUT_FILE_NAME::String = "data/Study 1/Observations_Fiedler_Glöckner_2012_study_1_preprocessed.csv";
const AOI_DICT = Dict(
    1.0 => "Ap1", 
    2.0 => "Ap2",
    3.0 => "Bp1",
    4.0 => "Bp2",
    5.0 => "Av1",
    6.0 => "Av2",
    7.0 => "Bv1",
    8.0 => "Bv2"
);

originalData = @pipe CSV.read(INPUT_FILE_NAME, DataFrame, types=Dict([(:subject, Int64), (:trigger, Int64)]), silencewarnings=true) |> 
    _[!, [:subject, :trigger, :AOI, :dec_left]] |>
    rename!(_, :trigger => :gamble) |>
    sort!(_, [:subject, :gamble]);
originalData[!, :optionChosen] = [Bool(row.dec_left) ? "A" : "B" for row in eachrow(originalData)];
select!(originalData, Not(:dec_left));
originalData[!, :AOI] = [AOI_DICT[key] for key in originalData[!, :AOI]];
originalData[!, :path] = fill(1, size(originalData)[1]);
originalData[!, :sample] = fill(1, size(originalData)[1]);

hypothesis5Data = generation_util.newHypothesis5Data(length(unique(originalData.subject)) * length(unique(originalData.gamble)) - 4);
currentSamplingPath::DataFrame = DataFrame();
insertionIndex::Int64 = 1;

for subject::Int64 in unique(originalData.subject), gamble::Int64 in unique(originalData.gamble)
    currentSamplingPath = originalData[(originalData[!, :subject] .=== subject) .& (originalData[!, :gamble] .=== gamble), :];
    if size(currentSamplingPath)[1] === 0 continue end;
    currentHypothesis5Data = generation_util.calculateHypothesis5(currentSamplingPath, currentSamplingPath[1, :optionChosen][1]);
    foreach(x -> (global hypothesis5Data[x][insertionIndex] = currentHypothesis5Data[x]), keys(currentHypothesis5Data));
    insertionIndex += 1;
end
hypothesis5Data = DataFrame(hypothesis5Data)[4:13];

groupA = @pipe hypothesis5Data[:, 4:10] |> [mean(skipmissing(i)) for i in eachrow(_)];
groupB = @pipe hypothesis5Data[:, 11:13] |> [mean(skipmissing(i)) for i in eachrow(_)];
t_test = OneSampleTTest(groupA, groupB);
pvalue(t_test, tail = :right)
confint(t_test)
