using DataFrames, CSV, SparseArrays, LinearAlgebra, BenchmarkTools, Plots

include("../Code/Mixing/Mixing.jl")

allres = CSV.read("2016res.csv", DataFrame)

dir = "../Datasets/MQLib/"
files = filter(x-> occursin(r".*\.txt", x), ARGS)

#output = "AllMQLibOutputs.csv"

#CSV.write(output,[], writeheader=true, header=["Filename", "Time", "Cost"])


function matrixFromFile(readfile)
    M = zeros(readfile[1,1], readfile[1,1])
    for i in 2:nrow(readfile)
        M[readfile[i,1], readfile[i,2]] = -readfile[i,3]
        M[readfile[i,2], readfile[i,1]] = -readfile[i,3]
    end
    toRemove = findall(x->x==0, sum(abs.((M)), dims=1))
    toRemove = [el[2] for el in toRemove]
    M = M[1:end .∉ [toRemove], 1:end .∉ [toRemove]]
    return M
end

function testpipeline(testinput)
    testmat = matrixFromFile(testinput)
    sparsetestmat=sparse(testmat)
    (V, t) = @timed Mixing.randserial(length(sparsetestmat[1,:]), 20, sparsetestmat)
    Cost = tr(V* testmat* V')
    return((t,V))

end

function results2016(file)
    objs = allres[[allres[!,"graphname"].==replace(file, ".txt" => ".zip")][1], 6]
    return objs
end


for file in files
    dirfile = dir * file
    res2016 = results2016(file)
    filetest = CSV.read(dirfile
    , comment="#", DataFrame, delim=" ",  header=false);

    t,V = testpipeline(filetest)
    assns = Mixing.assign100(V, matrixFromFile(filetest))

    histogram(res2016, label="2016CSV")
    histogram!(-assns, label= "Mixing100")

    savefig("histogram.png")
    

    #CSV.write(output, df, append=true)
end

