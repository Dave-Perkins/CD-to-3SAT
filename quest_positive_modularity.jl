#!/usr/bin/env julia
# Finally achieve positive modularity with proper community sizes

include("src/community_sat_solver_clean.jl")

function test_small_communities()
    # Create a 6-node graph with 2 tight communities of size 3 each
    edges = Dict{Tuple{Int,Int}, Float64}()
    
    # Community 1: nodes [1,2,3] - triangle
    edges[(1,2)] = 10.0
    edges[(2,1)] = 10.0
    edges[(2,3)] = 10.0  
    edges[(3,2)] = 10.0
    edges[(1,3)] = 10.0
    edges[(3,1)] = 10.0
    
    # Community 2: nodes [4,5,6] - triangle
    edges[(4,5)] = 10.0
    edges[(5,4)] = 10.0
    edges[(5,6)] = 10.0
    edges[(6,5)] = 10.0
    edges[(4,6)] = 10.0
    edges[(6,4)] = 10.0
    
    # Weak inter-community connection
    edges[(3,4)] = 1.0
    edges[(4,3)] = 1.0
    
    communities = [[1,2,3], [4,5,6]]
    
    # Calculate modularity
    total_weight = sum(values(edges))
    two_m = total_weight
    
    total_modularity = 0.0
    
    for community in communities
        for i in community
            for j in community
                A_ij = get(edges, (i, j), 0.0)
                ki = sum(weight for ((n1,n2), weight) in edges if n1 == i || n2 == i)
                kj = sum(weight for ((n1,n2), weight) in edges if n1 == j || n2 == j)
                expected = (ki * kj) / two_m
                total_modularity += (A_ij - expected)
            end
        end
    end
    
    modularity = total_modularity / two_m
    
    println("🔬 Small Communities Test:")
    println("   6 nodes, 2 communities of 3 nodes each")
    println("   Total edges: $(length(edges))")
    println("   Modularity: $(round(modularity, digits=4))")
    
    return modularity > 0, edges, communities
end

function test_really_simple()
    # 4 nodes, 2 communities of 2 nodes each
    edges = Dict{Tuple{Int,Int}, Float64}()
    
    # Community 1: nodes [1,2] 
    edges[(1,2)] = 10.0
    edges[(2,1)] = 10.0
    
    # Community 2: nodes [3,4]
    edges[(3,4)] = 10.0  
    edges[(4,3)] = 10.0
    
    # Weak inter-community connection
    edges[(2,3)] = 1.0
    edges[(3,2)] = 1.0
    
    communities = [[1,2], [3,4]]
    
    # Calculate modularity
    total_weight = sum(values(edges))
    two_m = total_weight
    
    total_modularity = 0.0
    
    for community in communities
        for i in community
            for j in community
                A_ij = get(edges, (i, j), 0.0)
                ki = sum(weight for ((n1,n2), weight) in edges if n1 == i || n2 == i)
                kj = sum(weight for ((n1,n2), weight) in edges if n1 == j || n2 == j)
                expected = (ki * kj) / two_m
                total_modularity += (A_ij - expected)
            end
        end
    end
    
    modularity = total_modularity / two_m
    
    println("🔬 Really Simple Test:")
    println("   4 nodes, 2 communities of 2 nodes each")
    println("   Total edges: $(length(edges))")
    println("   Modularity: $(round(modularity, digits=4))")
    
    return modularity > 0, edges, communities
end

println("🎯 Quest for Positive Modularity")
println("="^50)

# Try small communities
success1, edges1, comms1 = test_small_communities()

# Try really simple
success2, edges2, comms2 = test_really_simple()

if success1
    println("\n🎉 SUCCESS with small communities!")
    
    # Save this as a test file
    open("positive_modularity_6node.txt", "w") do file
        for ((i,j), weight) in edges1
            println(file, "$i $j $weight")
        end
    end
    println("✅ Saved as positive_modularity_6node.txt")
    
elseif success2
    println("\n🎉 SUCCESS with really simple communities!")
    
    # Save this as a test file
    open("positive_modularity_4node.txt", "w") do file
        for ((i,j), weight) in edges2
            println(file, "$i $j $weight")
        end
    end
    println("✅ Saved as positive_modularity_4node.txt")
    
else
    println("\n😞 No positive modularity achieved")
    println("💡 This suggests that equal-sized communities may inherently have negative modularity")
    println("   in small graphs due to the mathematics of the modularity formula")
end
