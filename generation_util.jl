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

    newSamplingPath = function(initialSize::Int64)
        return (subject = Array{Int64}(undef, initialSize),     # participant
                gamble = Array{Int64}(undef, initialSize),      # trigger
                path = Array{Int64}(undef, initialSize),        # path = sequence of sampling instances
                sample = Array{Int64}(undef, initialSize),      # index of a sampling instance in a path
                AOI = Array{String}(undef, initialSize));
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
        keys = vcat([:subject, :gamble, :optionChosen], [Symbol(string(i)*"%") for i in 10:10:100]);
        values = [fill([Array{Int64}(undef, initialSize)], 2)..., Array{Char}(undef, initialSize), fill([Array{Union{Float64, Missing}}(undef, initialSize)], 10)...];
        return namedtuple(keys, values);
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
    
            for sample::Int64 in 2:gamble.numberOfSamples
                currentState = StatsBase.sample(transition_matrix_creator.TARGETS, Weights(vec(transitionMatrix[currentState,:])), 1)[1];
                map(x -> samplingPaths[x][sample+i*gamble.numberOfSamples] = (gamble.subject, gamble.trigger, i+1, sample+i*gamble.numberOfSamples, currentState)[x], 1:5);
            end
        end

        return samplingPaths;
    end

    """ Hypothesis 3: The amount of fixations spent on an outcome increases with both is probability and the value of the outcome.
    # Arguments
    - samplingPaths: An array of sampling sequences of a single participant in a single gamble
    # Returns
    - A NamedTuple containing the average percentage of fixations on an outcome across all sampling sequences
    """
    calculateHypothesis3 = function(samplingPaths::NamedTuple{(:subject, :gamble, :path, :sample, :AOI), Tuple{Vector{Int64}, Vector{Int64}, Vector{Int64}, Vector{Int64}, Vector{String}}})
        numAOIs::Dict{String, Int64} = countmap(samplingPaths[:AOI]);
        numTotalSamples::Int64 = length(samplingPaths[1]);

        return (subject = samplingPaths.subject[1],
                gamble = samplingPaths.gamble[1],
                Av1 = (haskey(numAOIs, "Av1") ? numAOIs["Av1"] : 0) / numTotalSamples,
                Av2 = (haskey(numAOIs, "Av2") ? numAOIs["Av2"] : 0) / numTotalSamples,
                Bv1 = (haskey(numAOIs, "Bv1") ? numAOIs["Bv1"] : 0) / numTotalSamples,
                Bv2 = (haskey(numAOIs, "Bv2") ? numAOIs["Bv2"] : 0) / numTotalSamples);
    end

    """ Hypothesis 5: In the last third of a sampling process, there's a bias towards the ultimately chosen option (gaze-cascade effect).
    # Arguments
    - samplingPaths: An array of sampling sequences of a single participant in a single gamble
    # Returns
    """
    calculateHypothesis5 = function(samplingPaths::NamedTuple{(:subject, :gamble, :path, :sample, :AOI), Tuple{Vector{Int64}, Vector{Int64}, Vector{Int64}, Vector{Int64}, Vector{String}}},
                                    optionChosen::Char)
        calculateTargetOptionRatio = function(pathSegment::Array{String}, optionChosenTargets::Array{String})
            numAOIs::Dict{String, Int64} = countmap(pathSegment);
            return sum(map(target -> numAOIs[target], intersect(optionChosenTargets, OrderedCollections.keys(numAOIs)))) / length(pathSegment);
        end
        logger::FormatLogger = FormatLogger(open(LOGGING_OUTPUT_PATH, "w")) do io, args
            println(io, args.message);
        end
        samplingPathLength::Int64 = size(samplingPaths)[1];
        percentages::Array{Symbol} = [Symbol(string(i)*"%") for i in 10:10:100];
        keys::NTuple{13, Symbol} = Tuple(vcat([:subject, :gamble, :optionChosen], percentages));
        values::NTuple{13, Union{String, Missing}} = Tuple([samplingPaths[1,:subject], samplingPaths[1,:gamble], optionChosen, fill(missing, 10)...]);
        optionChosenPercentages = namedtuple(keys, values);

        if(samplingPathLength < 3)
            with_logger(logger) do 
                @info @sprintf("Subject %i showed less than three samples in gamble %i and will be excluded from testing hypothesis 5.", samplingPaths[1,:subject], samplingPaths[1, :gamble]);
            end
            return optionChosenPercentages;
        end
        
        numOfSegments::Int64 = 10;
        avgSegmentSize::Rational{Int64} = samplingPathLength // numOfSegments;
        pathSegments::Array{Array{String}} = [samplingPath[round(Int64, i*avgSegmentSize)+1:(i === numOfSegments-1 ? end : round(Int64, ((i+1)*avgSegmentSize)))] for i in 0:numOfSegments-1];
        optionChosenTargets::Array{String} = optionChosen === 'A' ? ["Ap1", "Ap2", "Av1", "Av2"]
                                           : optionChosen === 'B' ? ["Bp1", "Bp2", "Bv1", "Bv2"]
                                           : error(@sprintf("Expected 'A' or 'B' for option chosen, got '%s' instead.", optionChosen));
        # Achtung, hier kracht es, wenn ein PathSegment eingegeben wird, das weniger als 10 Elemente hat.
        targetOptionRatios::NTuple{10, Union{Float64, Missing}} = namedtuple(percentages, map(segment -> calculateTargetOptionRatio(segment, optionChosenTargets), pathSegments));
        foreach(percentage -> optionChosenPercentages[percentage] = targetOptionRatios[percentage], percentages);

        # kumuliert: Schritt n beinhaltet alle Fixationen von 0 bis Schritt n.
        # nicht-kumuliert: Schritt n beinhaltet alle Fixationen von Schritt n-1 bis Schritt n.

        # Wenn der Pfad weniger als 10 Samples lang ist, dann wird die Position jedes Wertes im Zeitablauf anteilig berechnet und gerundet.

        # Die Antwort auf diese Hypothese wird mglw. durch den grundsätzlichen Effekt verfälscht, dass Teilnehmer ca. im ersten Drittel bevorzugt Optionen auf der linken Seite anschauen.
    end
end