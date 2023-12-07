module Mixing
begin
    #Load in Packages
	using BenchmarkTools, Statistics, LinearAlgebra, Random, JuMP, SCS, SparseArrays, Plots, CUDA

	BenchmarkTools.DEFAULT_PARAMETERS.seconds = 15.0
end
export randserial, randparallel, JuMPspeed, JuMPspeedn, assign100
begin
    n=200
    k=9
    c = Symmetric(round.(rand(n,n))) 
    C= (c  - I + abs.(c-I))/2 
end
function Cn(n)
	c = Symmetric(round.(rand(n,n))) 
    return (c  - I + abs.(c-I))/2 
end
begin
	function randserial(n,k,C,ϵ=1e-7)
	  #  Costs = []
	    V=rand(k,n)
	  #  counter=0
	  #  Vs = []
	    for i in 1:n
	        V[:,i] = mix(i,V,C)
	    end
	    for j=1:n*k*2*4
	            i=rand(1:n)
	            V[:,i] = mix(i,V,C)
	      #  push!(Costs,tr(V* C* V'))
	      #  push!(Vs, V'*V)
	    end
        return V
	 # tr(V*C*V')
	  #  Vs
	  #  print(Costs[end])
	  #  plot(Costs)
	end
	function randparallel(n,k,C,ϵ=1e-7)
	    Costs = []
	    V=rand(k,n)
	    counter=0
	    Vs = []
	
	    for i in 1:n
	        V[:,i] = mix(i,V,C)
	    end
	    
	    Threads.@threads for j=1: Int(n*k*2)*4
	     #   Threads.@threads for l=1:4
	            i=rand(1:n)
	            V[:,i] = mix(i,V,C)
	     #   end
	#        push!(Costs,tr(V* C* V'))
	#        push!(Vs, V'*V)
	    end
	#    Vs
	#    Costs
	#    print(Costs[end])
	tr(V*C*V')
	end
	function randGPU(n,k,C,ϵ=1e-7)
		Costs = []
	    V=CuArray(rand(k,n))
	    counter=0
	  #  Vs = []
	    for i in 1:n
	        V[:,i] = mix(i,V,C)
	    end
	    for j=1:n*k*2*4
	            i=rand(1:n)
	            V[:,i] = mix(i,V,C)
	    end
		print(tr(V*C*V'))
	end
	function mix(i,V,C)
        ans=-(V*C[i,:])
        ans/=norm(ans)
	    return ans
	end
end

function assign(V,C)
    k = length(V[:,1])
    r = rand(k)
    r/=norm(r)
    assignments = sign.(r' * V)
    .5 * sum(C[i,j] * (1-assignments[i] * assignments[j])/2 for i in 1:length(V[1,:]) for j in 1:length(V[1,:]))
end
function assign100(V,C)
    assignments = []
    for i in 1:100
        push!(assignments, assign(V,C))
    end
    return assignments
end

begin
	function JuMPspeed()
		model = Model(SCS.Optimizer)
		@variable(model, X[1:n,1:n], PSD)
		for i in 1:n
		@constraint(model, X[i,i] == 1)
		end
		@constraint(model, X ≥ 0, PSDCone())
		@objective(model, Min, sum(C.*X))
		optimize!(model)
		return value(X)
	end
end


begin
	function JuMPspeedn(n,C)
		model = Model(SCS.Optimizer)
		@variable(model, X[1:n,1:n], PSD)
		for i in 1:n
		@constraint(model, X[i,i] == 1)
		end
		@constraint(model, X ≥ 0, PSDCone())
		@objective(model, Min, sum(C.*X))
		optimize!(model)
		return value(X)
	end
end
end