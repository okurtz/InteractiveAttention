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

    insert = function(samplingPath::NamedTuple{(:subject, :gamble, :path, :sample, :AOI), Tuple{Vector{Int64}, Vector{Int64}, Vector{Int64}, Vector{Int64}, Vector{String}}},
                      subject::Int64, gamble::Int64, path::Int64, sample::Int64, AOI::String)
        samplingPath.subject[sample] = subject;
        samplingPath.gamble[sample] = gamble;
        samplingPath.path[sample] = path;
        samplingPath.sample[sample] = sample;
        samplingPath.AOI[sample] = AOI;
    end

    simulate = function(transitionMatrix::NamedMatrix{Float64, Matrix{Float64}, Tuple{OrderedDict{String, Int64}, OrderedDict{String, Int64}}},
                        betas::DataFrameRow{DataFrame, DataFrames.SubIndex{DataFrames.Index, Vector{Int64}, Vector{Int64}}},
                        gamble::DataFrameRow{DataFrame, DataFrames.Index},
                        iterations::Int64)

        samplingPaths::NamedTuple{(:subject, :gamble, :path, :sample, :AOI), Tuple{Vector{Int64}, Vector{Int64}, Vector{Int64}, Vector{Int64}, Vector{String}}} = generation_util.newSamplingPath(gamble.numberOfSamples * iterations);
        currentState::String = "";

        for i in 0:iterations-1
            currentState = StatsBase.sample(transition_matrix_creator.TARGETS, Weights(transition_matrix_creator.get_starting_point_probabilities(betas[1], betas[2], betas[3])), 1)[1];
            generation_util.insert(samplingPaths, gamble.subject, gamble.trigger, i, 1 + i * gamble.numberOfSamples, currentState);
    
            for sample in 2:gamble.numberOfSamples
                currentState = StatsBase.sample(transition_matrix_creator.TARGETS, Weights(vec(transitionMatrix[currentState,:])), 1)[1];
                generation_util.insert(samplingPaths, gamble.subject, gamble.trigger, i, sample + i * gamble.numberOfSamples, currentState);
            end
        end

        return samplingPaths;
    end
end