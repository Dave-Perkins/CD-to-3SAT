#!/usr/bin/env julia
# Debug modularity calculation to find the issue

include("src/community_sat_solver_clean.jl")

println("🔍 Debugging Modularity Calculation")
println("="^50)

# Test with a simple known case
simple_edges = Dict{Tuple{Int,Int}, Float64}()
# Two communities: [1,2] and [3,4]
# Community 1: one internal edge
simple_edges[(1,2)] = 1.0
simple_edges[(2,1)] = 1.0
# Community 2: one internal edge
simple_edges[(3,4)] = 1.0
simple_edges[(4,3)] = 1.0
# One inter-community edge
simple_edges[(2,3)] = 1.0
simple_edges[(3,2)] = 1.0

communities = [[1,2], [3,4]]

println("📊 Simple test case:")
println("   Communities: $communities")
println("   Edges: $simple_edges")

# Manual calculation
total_weight = sum(values(simple_edges))
two_m = total_weight
println("   Total weight (2m): $two_m")

# Calculate degrees
degrees = Dict{Int, Float64}()
for node in 1:4
    degrees[node] = get_node_edge_weight(simple_edges, node)
    println("   Node $node degree: $(degrees[node])")
end

# Manual modularity calculation
println("\n🧮 Manual modularity calculation:")
global total_modularity = 0.0

for (comm_idx, community) in enumerate(communities)
    println("   Community $comm_idx:")
    global community_contribution = 0.0
    
    for i in community
        for j in community
            A_ij = get(simple_edges, (i, j), 0.0)
            ki = degrees[i]
            kj = degrees[j]
            expected = (ki * kj) / two_m
            contribution = A_ij - expected
            global community_contribution += contribution
            
            println("     ($i,$j): A_ij=$A_ij, expected=$(round(expected, digits=3)), contrib=$(round(contribution, digits=3))")
        end
    end
    
    community_contribution_normalized = community_contribution / two_m
    global total_modularity += community_contribution_normalized
    println("     Community $comm_idx contribution: $(round(community_contribution_normalized, digits=3))")
end

println("   Manual total modularity: $(round(total_modularity, digits=4))")

# Compare with our function
our_modularity = calculate_overall_modularity(simple_edges, communities)
println("   Our function result: $(round(our_modularity, digits=4))")

println("\n🎯 Expected range: [-0.5, 1.0]")
if our_modularity < -0.5 || our_modularity > 1.0
    println("   ❌ OUT OF BOUNDS! Our calculation is incorrect.")
else
    println("   ✅ Within expected bounds.")
end

# Let's also check what happens with completely disconnected communities
println("\n" * "="^50)
println("🔬 Testing disconnected communities:")

disconnected_edges = Dict{Tuple{Int,Int}, Float64}()
# Community 1: internal edge
disconnected_edges[(1,2)] = 1.0
disconnected_edges[(2,1)] = 1.0
# Community 2: internal edge  
disconnected_edges[(3,4)] = 1.0
disconnected_edges[(4,3)] = 1.0
# NO inter-community edges

disconnected_mod = calculate_overall_modularity(disconnected_edges, communities)
println("   Disconnected modularity: $(round(disconnected_mod, digits=4))")

if disconnected_mod < -0.5
    println("   ❌ Still out of bounds! There's definitely an error in our calculation.")
else
    println("   ✅ This would be within bounds.")
end
