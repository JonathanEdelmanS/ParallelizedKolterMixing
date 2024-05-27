using DataFrames, CSV, SparseArrays, LinearAlgebra, BenchmarkTools

include("../Code/Mixing/Mixing.jl")


dir = "../Datasets/MQLib/"
files = filter(x-> occursin(r".*\.txt", x), ARGS)

#output = "AllMQLibOutputs.csv"

#CSV.write(output,[], writeheader=true, header=["Filename", "Time", "Cost"])

function matrixFromFile(readfile)
    M = zeros(readfile[1,1], readfile[1,1])
    for i in 2:nrow(readfile)
        M[readfile[i,1], readfile[i,2]] = readfile[i,3]
        M[readfile[i,2], readfile[i,1]] = readfile[i,3]
    end
    return M
end

function testpipeline(testinput)
    testmat = matrixFromFile(testinput)
    sparsetestmat=sparse(testmat)
    (V, t) = @timed Mixing.randserial(length(sparsetestmat[1,:]), 30, sparsetestmat)
    Cost = tr(V* testmat* V')
    return((t,Cost))

end


for file in files
    dirfile = dir * file

    filetest = CSV.read(dirfile
    , comment="#", DataFrame, delim=" ",  header=false);

    t,Cost = testpipeline(filetest)

    df = DataFrame(Filename=file, Time=t, Cost=Cost)

    print(df)

    #CSV.write(output, df, append=true)
end
