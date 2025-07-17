#!/usr/bin/env julia

# Check the modularity formula implementation
println("🔍 Checking Modularity Formula Implementation")
println("=" ^ 60)

# The standard modularity formula is:
# Q = (1/2m) * Σ_ij [A_ij - (k_i * k_j)/(2m)] * δ(c_i, c_j)
# Where δ(c_i, c_j) = 1 if nodes i and j are in same community, 0 otherwise

# Let's check what the correct bounds should be
println("📚 Modularity Formula Check:")
println("   Q = (1/2m) * Σ_ij [A_ij - (k_i * k_j)/(2m)] * δ(c_i, c_j)")
println("   Expected range: [-0.5, 1.0]")
println()

# Test case: Simple 4-node graph
println("🧪 Test case verification:")
println("   Nodes: 1, 2, 3, 4")
println("   Edges: (1,2), (2,3), (3,4) - forming a path")
println("   Communities: [[1,2], [3,4]]")
println()

# Create the edges correctly
edges = Dict{Tuple{Int,Int}, Float64}()
# Path: 1-2-3-4
edges[(1,2)] = 1.0
edges[(2,1)] = 1.0  # Undirected
edges[(2,3)] = 1.0  
edges[(3,2)] = 1.0  # Undirected
edges[(3,4)] = 1.0
edges[(4,3)] = 1.0  # Undirected

total_weight = sum(values(edges))
two_m = total_weight

println("📊 Graph structure:")
println("   Edges: $edges")
println("   Total weight (2m): $two_m")
println()

# Calculate degrees
degrees = Dict{Int, Float64}()
for node in 1:4
    degrees[node] = 0.0
    for ((i, j), weight) in edges
        if i == node
            degrees[node] += weight
        end
    end
end

println("📐 Node degrees:")
for (node, degree) in sort(collect(degrees))
    println("   Node $node: degree = $degree")
end
println()

# Communities
communities = [[1, 2], [3, 4]]

# Manual calculation with detailed steps
println("🧮 Step-by-step modularity calculation:")
global total_modularity = 0.0

for (comm_idx, community) in enumerate(communities)
    println("   Community $comm_idx: $community")
    global community_sum = 0.0
    
    for i in community
        for j in community
            A_ij = get(edges, (i, j), 0.0)
            ki = degrees[i]
            kj = degrees[j]
            expected = (ki * kj) / two_m
            contribution = A_ij - expected
            global community_sum += contribution
            
            println("     ($i,$j): A_ij=$A_ij, k_i=$ki, k_j=$kj")
            println("           expected=(k_i*k_j)/2m = $(ki)*$(kj)/$two_m = $(round(expected, digits=4))")
            println("           contribution = $A_ij - $(round(expected, digits=4)) = $(round(contribution, digits=4))")
        end
    end
    
    community_contribution = community_sum / two_m
    global total_modularity += community_contribution
    println("   Community $comm_idx total: $(round(community_sum, digits=4)) / $two_m = $(round(community_contribution, digits=4))")
    println()
end

println("🎯 Final modularity: $(round(total_modularity, digits=4))")
println("   Expected range: [-0.5, 1.0]")

if total_modularity < -0.5 || total_modularity > 1.0
    println("   ❌ OUT OF BOUNDS!")
    println()
    println("🤔 Let's check if we're missing something...")
    println("   The modularity formula should be:")
    println("   Q = (1/2m) * Σ_ij [A_ij - (k_i * k_j)/(2m)] * δ(c_i, c_j)")
    println()
    println("   Wait... let me check the Newman-Girvan paper...")
    println("   Maybe we need to look at the exact definition again...")
else
    println("   ✅ Within expected bounds!")
end
