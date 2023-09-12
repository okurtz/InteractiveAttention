module mixed_model_util
    using
        CSV,
        DataFrames,
        Printf;

    STUDY::Int64 = 0;
    mixedModelInputDataAppendIndex::Int64 = 1;
    gambles::DataFrame = DataFrame();

    init = function(study::Int64)
        STUDY = study;
        global gambles = CSV.read(@sprintf("data/Study %i/Gambles_Fiedler_Glöckner_2012_Study_%i_standardized.csv", STUDY, STUDY), DataFrame);
    end

    new_mixed_model_input_data = function(initialSize::Int64)
        mixedModelInputDataAppendIndex = 1;
        return (
            subject = Vector{Int64}(undef, initialSize),
            gamble = Vector{Int64}(undef, initialSize),
            fixationRatio = Vector{Float64}(undef, initialSize),
            prob_z = Vector{Float64}(undef, initialSize),
            outcome_z = Vector{Float64}(undef, initialSize),
            target = Vector{Symbol}(undef, initialSize)
        );
    end

    generate_mixed_model_input_data = function(outcomeTarget::Symbol, fixationRatios::DataFrame)
        return (
            subject = fixationRatios.subject,
            gamble = fixationRatios.gamble,
            fixationRatio = fixationRatios[!, replace(String(outcomeTarget), "_z" => "")],
            prob_z = [gambles[gambles[!, :trigger] .=== row.gamble, replace(String(outcomeTarget), "v" => "p")][1] for row in eachrow(fixationRatios)],
            outcome_z = [gambles[gambles[!, :trigger] .=== row.gamble, outcomeTarget][1] for row in eachrow(fixationRatios)],
            target = fill(outcomeTarget, length(fixationRatios.subject))
        );
    end

    append_mixed_model_data = function(appendData::NamedTuple, mixedModelData::NamedTuple)
        append_column = function(col, name::Symbol, startIndex::Int64)
            for i in 0:length(col)-1
                mixedModelData[name][startIndex+i] = col[i+1];
            end
        end

        foreach(x -> append_column(appendData[x], x, mixedModelInputDataAppendIndex), keys(appendData));
        global mixedModelInputDataAppendIndex += length(appendData[1]);
    end
end