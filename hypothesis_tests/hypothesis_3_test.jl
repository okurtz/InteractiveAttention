using
    CategoricalArrays,
    CSV,
    DataFrames,
    MixedModels,
    JLD2,
    Pipe,
    Printf,
    StatsModels;

cd("C:\\Users\\Oliver\\Documents\\Studium\\Psychologie\\Bachelorarbeit\\Skripte");
include("mixed_model_util.jl");

const STUDY = 2;
mixed_model_util.init(STUDY);
const OUTCOME_TARGETS = [:Av1_z, :Av2_z, :Bv1_z, :Bv2_z];
const OUTPUT_FILE_NAME = @sprintf("model_fit_hyp_3_study_%i", STUDY);
const fixationRatios = CSV.read(@sprintf("data/Study %i/hypothesis_3_aggregated_data.csv", STUDY), DataFrame);

# subject noch als Kategorievariable definieren
f = @formula(fixationRatio ~ 1 + outcome_z * prob_z + (1 + outcome_z * prob_z | subject));    # (1 | target) outcome_z und prob_z können auch zwischen den Teilnehmern variieren.
mixedModelInputData::NamedTuple = NamedTuple();
mixedModelInputDataFragment::NamedTuple = NamedTuple();
df::DataFrame = DataFrame();

mixedModelInputData = mixed_model_util.new_mixed_model_input_data(@pipe OUTCOME_TARGETS |> map(target -> length(fixationRatios[!, replace(String(target), "_z" => "")]), _) |> reduce(+, _));

for target in OUTCOME_TARGETS
    mixedModelInputDataFragment = mixed_model_util.generate_mixed_model_input_data(target, fixationRatios);
    mixed_model_util.append_mixed_model_data(mixedModelInputDataFragment, mixedModelInputData);
    mixed_model_util.mixedModelInputDataAppendIndex += length(mixedModelInputDataFragment[1]);
end
df = DataFrame(mixedModelInputData);
df.subject = categorical(df.subject);
modelFit = fit(MixedModel, f, df);
@save OUTPUT_FILE_NAME*".jld2" modelFit;
println("Run finished.")