using
    CSV,
    DataFrames,
    Plots,
    Pipe,
    Printf,
    StatsBase;

cd("C:\\Users\\Oliver\\Documents\\Studium\\Psychologie\\Bachelorarbeit\\Skripte");
include("../hypothesis_tests/mixed_model_util.jl");

const STUDY = 1;

mixed_model_util.init(STUDY);
const OUTCOME_TARGETS = [:Av1_z, :Av2_z, :Bv1_z, :Bv2_z];
const OUTPUT_FILE_NAME = @sprintf("hypothesis_1_main_effects_study_%i.png", STUDY);
const fixationRatios = CSV.read(@sprintf("data/Study %i/hypothesis_3_aggregated_data.csv", STUDY), DataFrame);

mixedModelInputData::NamedTuple = NamedTuple();
mixedModelInputDataFragment::NamedTuple = NamedTuple();
df::DataFrame = DataFrame();
mixedModelInputData = mixed_model_util.new_mixed_model_input_data(@pipe OUTCOME_TARGETS |> map(target -> length(fixationRatios[!, replace(String(target), "_z" => "")]), _) |> reduce(+, _));

for target::Symbol in OUTCOME_TARGETS
    mixedModelInputDataFragment = mixed_model_util.generate_mixed_model_input_data(target, fixationRatios);
    mixed_model_util.append_mixed_model_data(mixedModelInputDataFragment, mixedModelInputData);
end

df = DataFrame(mixedModelInputData);
Statistics.normalize!(df[!, :fixationRatio]);
p = scatter(
    df[!, :prob_z],
    df[!, :fixationRatio],
    xlabel="Gewinnwahrscheinlichkeit",
    ylabel="Fixationshäufigkeit"
);