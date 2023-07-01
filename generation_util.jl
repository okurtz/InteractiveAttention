module generation_util
    newSamplingPath = function(initialSize::Int64)
        return (subject = Array{Int32}(undef, initialSize),
                gamble = Array{Int32}(undef, initialSize),
                sample = Array{Int32}(undef, initialSize),
                AOI = Array{String}(undef, initialSize));
    end
end