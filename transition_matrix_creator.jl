# module transition_matrix_creator
    using 
        CSV,
        DataFrames,
        LinearAlgebra,
        Statistics;

    cd("C:\\Users\\Oliver\\Documents\\Studium\\Psychologie\\Bachelorarbeit\\Skripte");
    const GAMBLE_SOURCE_PATH = "data/Gambles_Fiedler_Glöckner_2012.csv";
    const GAMBLES = CSV.read(GAMBLE_SOURCE_PATH, DataFrame);
    const TARGETS = ["1.0", "2.0", "3.0", "4.0", "5.0", "6.0", "7.0", "8.0"];     # Do not change the order!
    const B_OPTN = hcat(repeat([1 1 0 0 1 1 0 0], 8));
    const B_ATTR = hcat(repeat([0 0 0 0 1 1 1 1], 8));
    const B_BRAN = hcat(repeat([1 0 1 0 1 0 1 0], 8));  # Assuming top-most option = 1st option, bottom-most option = 2nd option
    const I_OPTN = repeat(vcat(repeat([1 1 0 0 1 1 0 0], 2), 
                            repeat([0 0 1 1 0 0 1 1], 2)), 2);
    const I_ATTR = [j < 4 ? (i >= 4 ? 0 : 1) : (i >= 4 ? 1 : 0)  for i in 0:7, j in 0:7];
    const I_STAT = I;
    const I_P_BRAN = [i >= 4 ? 0 : i === j || (i+4)%8 === j ? 1 : 0 for i in 0:7, j in 0:7];
    const I_X_BRAN = [i < 4 ? 0 : i === j || (i+4)%8 === j ? 1 : 0 for i in 0:7, j in 0:7];

    """ Returns the probabilites that each target will be sampled first.
    # Arguments
    - beta1-3: beta1 to 3 as specified by He and Bhatia (2023)
    # Returns
    - A Dictionary containing (target,prob) pairs
    """
    function get_starting_point_probabilities(beta1::Number, beta2::Number, beta3::Number)
        return Dict(TARGETS .=> [beta1*B_OPTN[i,i] + beta2*B_ATTR[i,i] + beta3*B_BRAN[i,i] for i in 1:8]);
    end;

    function standardize_gamble_values!(gambles::DataFrame)
        all_outcomes_abs = Matrix(abs.(gambles[:,[:Av1, :Av2, :Bv1, :Bv2]]));
        all_probs = Matrix(gambles[:,[:Ap1, :Ap2, :Bp1, :Bp2]]);

        abs_outcomes_mean = mean(all_outcomes_abs);
        abs_outcomes_sd = std(all_outcomes_abs);

        probs_mean = mean(all_probs);
        probs_sd = std(all_probs);

        gambles[!,:Av1_z] = (abs.(gambles[:,:Av1].-abs_outcomes_mean)) ./ abs_outcomes_sd;
        gambles[!,:Av2_z] = (abs.(gambles[:,:Av2].-abs_outcomes_mean)) ./ abs_outcomes_sd;
        gambles[!,:Ap1_z] = (gambles[:,:Ap1].-probs_mean) ./ probs_sd;
        gambles[!,:Ap2_z] = (gambles[:,:Ap2].-probs_mean) ./ probs_sd;
        gambles[!,:Bv1_z] = (abs.(gambles[:,:Bv1].-abs_outcomes_mean)) ./ abs_outcomes_sd;
        gambles[!,:Bv2_z] = (abs.(gambles[:,:Bv2].-abs_outcomes_mean)) ./ abs_outcomes_sd;
        gambles[!,:Bp1_z] = (gambles[:,:Bp1].-probs_mean) ./ probs_sd;
        gambles[!,:Bp2_z] = (gambles[:,:Bp2].-probs_mean) ./ probs_sd;
    end;

    function logsumexp(v)
        y = maximum(v);
        return y + log(sum(exp.(v .- y)));
    end
    function softmax(x)
        return exp.(x .- logsumexp(x));
    end

    # Übergangsmatrizen der Teilnehmer für alle Gambles bestimmen
    # Für alle Teilnehmer die Beta-Parameter einlesen
    # Mit diesen Beta-Parameter die Modellimplementation aufrufen und die jeweilige Übergangsmatrix berechnen lassen

    # Diese Funktion wendet das Modell an, um die Übergangsmatrizen zu berechnen.
    """ Calculates the probabilities to transition to any state given the current state.
    This implementation does not consider a novelty parameter.
    # Arguments
    - currentTarget: Index of the current target as specified in TARGETS
    - gamble: Number of the gamble for which to calculate transition probabilities, referring to gambles.trigger
    - betas: beta1-10 as specified by He and Bhatia (2023)
    # Returns
    - A vector containing the transitioning probabilities with the array indices referring to the target indices
    """
    global function get_transition_probabilities(currentTarget::Number, gamble::Number, betas::Array{Number})

        return softmax(
            betas[1].*B_OPTN[currentTarget,:] +
            betas[2].*B_ATTR[currentTarget,:] +
            betas[3].*B_BRAN[currentTarget,:] +
            betas[4].*I_OPTN[currentTarget,:] +
            betas[5].*I_ATTR[currentTarget,:] +
            betas[6].*I_STAT[currentTarget,:] +
            betas[7].*I_P_BRAN[currentTarget,:] +
            betas[8].*I_X_BRAN[currentTarget,:] +
            betas[9].*I_P_BRAN[currentTarget,:]*z +
            betas[10].*I_X_BRAN[currentTarget,:]*z
        );
    end

    standardize_gamble_values!(GAMBLES);
# end