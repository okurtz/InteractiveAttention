module generation_util
    using
        DataFrames,
        NamedArrays,
        OrderedCollections,
        StatsBase;

    include("transition_matrix_creator.jl");

    newSamplingPath = function(initialSize::Int64)
        return (subject = Array{Int64}(undef, initialSize),     # participant
                gamble = Array{Int64}(undef, initialSize),      # trigger
                path = Array{Int64}(undef, initialSize),        # path = sequence of sampling instances
                sample = Array{Int64}(undef, initialSize),      # index of a sampling instance in a path
                AOI = Array{String}(undef, initialSize));
    end

    newHypothesis3Data = function(initialSize::Int64)
        return (subject = Array{Int64}(undef, initialSize),     # participant
                gamble = Array{Int64}(undef, initialSize),      # trigger
                Av1 = Array{Float64}(undef, initialSize),
                Av2 = Array{Float64}(undef, initialSize),
                Bv1 = Array{Float64}(undef, initialSize),
                Bv2 = Array{Float64}(undef, initialSize));
    end

    simulate = function(transitionMatrix::NamedMatrix{Float64, Matrix{Float64}, Tuple{OrderedDict{String, Int64}, OrderedDict{String, Int64}}},
                        betas::DataFrameRow{DataFrame, DataFrames.SubIndex{DataFrames.Index, Vector{Int64}, Vector{Int64}}},
                        gamble::DataFrameRow{DataFrame, DataFrames.Index},
                        iterations::Int64)

        samplingPaths::NamedTuple{(:subject, :gamble, :path, :sample, :AOI), Tuple{Vector{Int64}, Vector{Int64}, Vector{Int64}, Vector{Int64}, Vector{String}}} = generation_util.newSamplingPath(gamble.numberOfSamples * iterations);
        currentState::String = "";

        for i in 0:iterations-1
            currentState = StatsBase.sample(transition_matrix_creator.TARGETS, Weights(transition_matrix_creator.get_starting_point_probabilities(betas[1], betas[2], betas[3])), 1)[1];
            map(x -> samplingPaths[x][1+i*gamble.numberOfSamples] = (gamble.subject, gamble.trigger, i+1, 1+i*gamble.numberOfSamples, currentState)[x], 1:5);
    
            for sample in 2:gamble.numberOfSamples
                currentState = StatsBase.sample(transition_matrix_creator.TARGETS, Weights(vec(transitionMatrix[currentState,:])), 1)[1];
                map(x -> samplingPaths[x][sample+i*gamble.numberOfSamples] = (gamble.subject, gamble.trigger, i+1, sample+i*gamble.numberOfSamples, currentState)[x], 1:5);
            end
        end

        return samplingPaths;
    end

    """ Hypothesis 3: The amount of fixations spent on an outcome increases with both is probability and the value of the outcome.
    # Arguments
    - samplingPath: An array of sampling sequences of a single participant in a single gamble
    # Returns
    - A NamedTuple containing the average percentage of fixations on an outcome across all sampling sequences
    """
    calculateHypothesis3 = function(samplingPath::NamedTuple{(:subject, :gamble, :path, :sample, :AOI), Tuple{Vector{Int64}, Vector{Int64}, Vector{Int64}, Vector{Int64}, Vector{String}}})
        numAOIs = countmap(samplingPath[:AOI]);
        numTotalSamples = length(samplingPath[1]);

        return (subject = samplingPath.subject[1],
                gamble = samplingPath.gamble[1],
                Av1 = (haskey(numAOIs, "Av1") ? numAOIs["Av1"] : 0) / numTotalSamples,
                Av2 = (haskey(numAOIs, "Av2") ? numAOIs["Av2"] : 0) / numTotalSamples,
                Bv1 = (haskey(numAOIs, "Bv1") ? numAOIs["Bv1"] : 0) / numTotalSamples,
                Bv2 = (haskey(numAOIs, "Bv2") ? numAOIs["Bv2"] : 0) / numTotalSamples);
    end
end