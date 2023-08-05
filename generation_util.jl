module generation_util
    using
        DataFrames,
        Logging,
        LoggingExtras,
        NamedArrays,
        NamedTupleTools,
        OrderedCollections,
        Printf,
        StatsBase;

    include("transition_matrix_creator.jl");
    const LOGGING_OUTPUT_PATH::String = "simulation.log";
    rm(LOGGING_OUTPUT_PATH, force = true);
    loggingLock::ReentrantLock = Threads.ReentrantLock();
    logger::FormatLogger = FormatLogger(LOGGING_OUTPUT_PATH, append = true) do io, args
        println(io, args.message);
    end

    newSamplingPath = function(initialSize::Int64)
        return (Array{Int64}(undef, initialSize),   # subject
                Array{Int64}(undef, initialSize),   # trigger
                Array{Int64}(undef, initialSize),   # path number
                Array{Int64}(undef, initialSize),   # sample number within current path
                Array{String}(undef, initialSize)); # AOI
    end

    newHypothesis3Data = function(initialSize::Int64)
        return (subject = Array{Int64}(undef, initialSize),
                gamble = Array{Int64}(undef, initialSize),
                Av1 = Array{Float64}(undef, initialSize),
                Av2 = Array{Float64}(undef, initialSize),
                Bv1 = Array{Float64}(undef, initialSize),
                Bv2 = Array{Float64}(undef, initialSize));
    end

    newHypothesis5Data = function(initialSize::Int64)
        keys = vcat([:subject, :gamble, :optionChosen], [Symbol(string(i)*"%") for i::Int64 in 10:10:100]);
        values = [Array{Int64}(undef, initialSize), Array{Int64}(undef, initialSize), Array{Char}(undef, initialSize), [Array{Union{Float64, Missing}}(undef, initialSize) for i::Int64 in 1:10]...];
        return (namedtuple(keys, values));
    end

    newHypothesis6Data = function(initialSize::Int64)
        keys = vcat([:subject, :gamble], [Symbol(string(i)*"%") for i::Int64 in 20:20:100]);
        values = [Array{Int64}(undef, initialSize), Array{Int64}(undef, initialSize), [Array{Union{Float64, Missing}}(undef, initialSize) for i::Int64 in 1:5]...];
        return (namedtuple(keys, values));
    end

    newHypothesis7Data = function(initialSize::Int64)
        return (subject = Array{Int64}(undef, initialSize),
                gamble = Array{Int64}(undef, initialSize),
                fixWithinLottery = Array{Float64}(undef, initialSize));
    end

    simulate = function(transitionMatrix::NamedMatrix{Float64, Matrix{Float64}, Tuple{OrderedDict{String, Int64}, OrderedDict{String, Int64}}},
                        betas::DataFrameRow{DataFrame, DataFrames.SubIndex{DataFrames.Index, Vector{Int64}, Vector{Int64}}},
                        gamble::DataFrameRow{DataFrame, DataFrames.Index},
                        iterations::Int64)

        samplingPaths::Tuple{Array{Int64}, Array{Int64}, Array{Int64}, Array{Int64}, Array{String}} = generation_util.newSamplingPath(gamble.numberOfSamples * iterations);
        currentState::String = "";

        for i::Int64 in 0:iterations-1
            currentState = StatsBase.sample(transition_matrix_creator.TARGETS, Weights(transition_matrix_creator.get_starting_point_probabilities(betas[1], betas[2], betas[3])), 1)[1];
            foreach(x -> samplingPaths[x][1+i*gamble.numberOfSamples] = (gamble.subject, gamble.trigger, i+1, 1+i*gamble.numberOfSamples, currentState)[x], 1:5);

            for sample::Int64 in 2:gamble.numberOfSamples
                currentState = StatsBase.sample(transition_matrix_creator.TARGETS, Weights(vec(transitionMatrix[currentState,:])), 1)[1];
                foreach(x -> samplingPaths[x][sample+i*gamble.numberOfSamples] = (gamble.subject, gamble.trigger, i+1, sample+i*gamble.numberOfSamples, currentState)[x], 1:5);
            end
        end
        return DataFrame(subject = samplingPaths[1], gamble = samplingPaths[2], path = samplingPaths[3], sample = samplingPaths[4], AOI = samplingPaths[5], copycols=false);
    end

    """ Hypothesis 3: The amount of fixations spent on an outcome increases with both is probability and the value of the outcome.
    # Arguments
    - samplingPaths: A DataFrame of sampling sequences of a single participant in a single gamble
    # Returns
    - A NamedTuple containing the average percentage of fixations on an outcome across all sampling sequences
    """
    calculateHypothesis3 = function(samplingPaths::DataFrame)
        numAOIs::Dict{String, Int64} = countmap(samplingPaths[:, :AOI]);
        numTotalSamples::Int64 = size(samplingPaths)[1];

        return DataFrame(subject = samplingPaths[1, :subject],
                gamble = samplingPaths[1, :gamble],
                Av1 = (haskey(numAOIs, "Av1") ? numAOIs["Av1"] : 0) / numTotalSamples,
                Av2 = (haskey(numAOIs, "Av2") ? numAOIs["Av2"] : 0) / numTotalSamples,
                Bv1 = (haskey(numAOIs, "Bv1") ? numAOIs["Bv1"] : 0) / numTotalSamples,
                Bv2 = (haskey(numAOIs, "Bv2") ? numAOIs["Bv2"] : 0) / numTotalSamples, copycols = false)[1, :];
    end

    """ Hypothesis 5: In the last third of a sampling process, there's a bias towards the ultimately chosen option (gaze-cascade effect).
    # Arguments
    - samplingPaths: A DataFrame of one or more sampling sequences of a single participant in a single gamble
    - optionChosen: The option the participant has ultimately chosen, either 'A' or 'B'
    # Returns
    - A DataFrameRow containing the percentage of fixations of the ultimately chosen option in ten-percent steps of the total sampling duration
    """
    calculateHypothesis5 = function(samplingPaths::DataFrame, optionChosen::Char)

        calculateTargetOptionRatio = function(pathSegment::Array{String}, optionChosenTargets::Array{String})
            numAOIs::Dict{String, Int64} = countmap(pathSegment);
            return sum(map(target -> numAOIs[target], intersect(optionChosenTargets, OrderedCollections.keys(numAOIs)))) / length(pathSegment);
        end

        samplingPathNumbers::Array{Int64} = unique(samplingPaths[:, :path]);
        samplingPathLength::Int64 = size(samplingPaths)[1] / size(samplingPathNumbers)[1];
        percentages::Array{Symbol} = [Symbol(string(i)*"%") for i::Int64 in 10:10:100];
        averageTargetSamplingRatio::DataFrame = DataFrame(
            subject = Array{Int64}([samplingPaths[1, :subject]]),
            gamble = Array{Int64}([samplingPaths[1, :gamble]]),
            optionChosen = Array{Char}([optionChosen]),
            copycols = false
        );
        foreach(column -> (averageTargetSamplingRatio[:, column] = Array{Union{Float64, Missing}}(missing, 1)), percentages);

        if(samplingPathLength < 3)
            lock(loggingLock)
                with_logger(logger) do 
                    @info @sprintf("Subject %i showed less than three samples in gamble %i and will be excluded from testing hypothesis 5.", samplingPaths[1,:subject], samplingPaths[1, :gamble]);
                end
            unlock(loggingLock)
            return averageTargetSamplingRatio[1, :];
        end
        
        currentSamplingPath::Array{String} = [];
        numOfSegments::Int64 = 10;
        avgSegmentSize::Rational{Int64} = samplingPathLength // numOfSegments;
        targetSamplingRatio = Matrix{Union{Float64, Missing}}(missing, size(samplingPathNumbers)[1], numOfSegments);
        pathSegments::Array{Array{String}} = [];
        optionChosenTargets::Array{String} = [];

        for samplingPathNumber::Int64 in samplingPathNumbers
            currentSamplingPath = samplingPaths[samplingPaths[!, :path] .=== samplingPathNumber, :][!, :AOI];
            pathSegments = [currentSamplingPath[round(Int64, i*avgSegmentSize)+1:(i === numOfSegments-1 ? end : round(Int64, ((i+1)*avgSegmentSize)))] for i::Int64 in 0:numOfSegments-1];
            optionChosenTargets = optionChosen === 'A' ? ["Ap1", "Ap2", "Av1", "Av2"] :
                                  optionChosen === 'B' ? ["Bp1", "Bp2", "Bv1", "Bv2"] :
                                  error(@sprintf("Expected 'A' or 'B' for option chosen, got '%s' instead.", optionChosen));
            
            for i::Int64 in eachindex(pathSegments)
                if(!isempty(pathSegments[i]))
                    targetSamplingRatio[samplingPathNumber, i] = calculateTargetOptionRatio(pathSegments[i], optionChosenTargets);
                end
            end
        end

        for i::Int64 in 1:numOfSegments
            averageTargetSamplingRatio[1, percentages[i]] = ismissing(targetSamplingRatio[1, i]) ? missing : mean(targetSamplingRatio[:, i]);
        end
        return averageTargetSamplingRatio[1, :];
    end

    """ Hypothesis 6: In the first 20% of a sampling process, participants preferrably sample probability targets and increasing outcome targets afterwards.
    # Arguments
    - samplingPaths: A DataFrame of one or more sampling sequences of a single participant in a single gamble
    # Returns
    - A DataFrameRow containing the percentage of fixations of probability targets in twenty-percent steps of the total sampling duration
    """
    calculateHypothesis6 = function(samplingPaths::DataFrame)
        calculateProbabilitySamplingRatio = function(pathSegment::Array{String})
            probabilityTargets = ["Ap1", "Ap2", "Bp1", "Bp2"];
            numAOIs::Dict{String, Int64} = countmap(pathSegment);
            return sum(map(target -> numAOIs[target], intersect(probabilityTargets, OrderedCollections.keys(numAOIs)))) / length(pathSegment);
        end

        samplingPathNumbers::Array{Int64} = unique(samplingPaths[:, :path]);
        samplingPathLength::Int64 = size(samplingPaths)[1] / size(samplingPathNumbers)[1];
        percentages::Array{Symbol} = [Symbol(string(i)*"%") for i::Int64 in 20:20:100];
        averageProbabilitySamplingRatio::DataFrame = DataFrame(
            subject = Array{Int64}([samplingPaths[1, :subject]]),
            gamble = Array{Int64}([samplingPaths[1, :gamble]]),
            copycols = false
        );
        foreach(column -> (averageProbabilitySamplingRatio[:, column] = Array{Union{Float64, Missing}}(missing, 1)), percentages);

        if(samplingPathLength < 5)
            lock(loggingLock)
                with_logger(logger) do 
                    @info @sprintf("Subject %i showed less than five samples in gamble %i and will be excluded from testing hypothesis 6.", samplingPaths[1,:subject], samplingPaths[1, :gamble]);
                end
            unlock(loggingLock)
            return averageProbabilitySamplingRatio[1, :];
        end

        currentSamplingPath::Array{String} = [];
        numOfSegments::Int64 = 5;
        avgSegmentSize::Rational{Int64} = samplingPathLength // numOfSegments;
        probabilitySamplingRatio = Matrix{Union{Float64, Missing}}(missing, size(samplingPathNumbers)[1], numOfSegments);
        pathSegments::Array{Array{String}} = [];

        for samplingPathNumber::Int64 in samplingPathNumbers
            currentSamplingPath = samplingPaths[samplingPaths[!, :path] .=== samplingPathNumber, :][!, :AOI];
            pathSegments = [currentSamplingPath[round(Int64, i*avgSegmentSize)+1:(i === numOfSegments-1 ? end : round(Int64, ((i+1)*avgSegmentSize)))] for i::Int64 in 0:numOfSegments-1];
            
            for i::Int64 in eachindex(pathSegments)
                if(!isempty(pathSegments[i]))
                    probabilitySamplingRatio[samplingPathNumber, i] = calculateProbabilitySamplingRatio(pathSegments[i]);
                end
            end
        end

        for i::Int64 in 1:numOfSegments
            averageProbabilitySamplingRatio[1, percentages[i]] = ismissing(probabilitySamplingRatio[1, i]) ? missing : mean(probabilitySamplingRatio[:, i]);
        end
        return averageProbabilitySamplingRatio[1, :];
    end

    """ Hypothesis 7: More fixation transitions occur between lotteries than within lotteries.
    # Arguments
    - samplingPaths: A DataFrame of one or more sampling sequences of a single participant in a single gamble
    # Returns
    - A DataFrame containing the fixation transitions within a lottery for each participant and each gamble
    """
    calculateHypothesis7 = function(samplingPaths::DataFrame)
        calculateFixationTransitionRatioWithinLottery = function(samplingPath::Array{String})
            transitionsWithin::Int64 = 0;
            currentLottery::Char = samplingPath[1][1];
            followingLottery::Char = ' ';

            for i::Int64 in eachindex(samplingPath)
                if(i === length(samplingPath))
                    return transitionsWithin / (length(samplingPath)-1);
                end
                followingLottery = samplingPath[i+1][1];

                if(followingLottery === currentLottery)
                    transitionsWithin += 1;
                else
                    currentLottery = followingLottery;
                end
            end
        end

        samplingPathNumbers::Array{Int64} = unique(samplingPaths[:, :path]);
        fixationTransitionRatios::Array{Float64} = [calculateFixationTransitionRatioWithinLottery(samplingPaths[samplingPaths[!, :path] .=== samplingPathNumber, :][!, :AOI]) for samplingPathNumber in samplingPathNumbers];

        return DataFrame(
            subject = samplingPaths[:, :subject],
            gamble = samplingPaths[:, :gamble],
            fixWithinLottery = mean(fixationTransitionRatios),
            copycols = false
        )[1, :];
    end
end