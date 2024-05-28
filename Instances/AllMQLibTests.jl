using DataFrames, CSV, SparseArrays, LinearAlgebra, BenchmarkTools, JuMP, MQLib

include("../Code/Mixing/Mixing.jl")

dir = "../Datasets/MQLib/AllMQLibGraphs/"
files = filter(x-> occursin(r".*\.txt", x), readdir(dir))

output = "AllMQLibOutputs.csv"

CSV.write(output,[], writeheader=true, header=["Filename", "Time", "Cost", "MQLibTime", "MQLibCost"])

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
    return((t,Cost))

end

function MQLibpipelin(testinput)

    testmat = matrixFromFile(testinput)
    sparsetestmat=sparse(testmat)

    model = Model(MQLib.Optimizer)
    JuMP.set_optimizer_attribute(model, "heuristic", "ALKHAMIS1998")

    n,m = size(testmat)

    @variable(model, x[1:n], Bin)
    @objective(model, Min, 4 * (x.- 0.5)' * sparsetestmat *(x.- 0.5))

    time = @timed  optimize!(model)

    return time.time, objective_value(model)
end



function MQLibpipelin(testinput)

    testmat = matrixFromFile(testinput)
    sparsetestmat=sparse(testmat)

    model = Model(MQLib.Optimizer)
    JuMP.set_optimizer_attribute(model, "heuristic", "ALKHAMIS1998")

    n,m = size(testmat)

    @variable(model, x[1:n], Bin)
    @objective(model, Min, 4 * (x.- 0.5)' * sparsetestmat *(x.- 0.5))

    time = @timed  optimize!(model)

    return time.time, objective_value(model)
end



for file in files
    dirfile = dir * file

    filetest = CSV.read(dirfile
    , comment="#", DataFrame, delim=" ",  header=false);

    t,Cost = testpipeline(filetest)

    MQt, MQCost = MQLibpipelin(filetest)

    

    df = DataFrame(Filename=file, Time=t, Cost=Cost, MQLibTime = MQt, MQLibCost = MQCost)

    CSV.write(output, df, append=true)
end

