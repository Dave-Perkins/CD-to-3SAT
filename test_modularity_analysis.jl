#!/usr/bin/env julia
# Test to verify modularity calculation behavior with external edges

include("src/community_sat_solver_clean.jl")

println("🔬 Modularity Calculation Analysis")
println("="^50)

# Create a simple test graph to understand the behavior
# Let's manually create edge data to see what happens
test_graph_data = Dict{Tuple{Int,Int}, Float64}()

# Community 1: nodes [1, 2]  
# Community 2: nodes [3, 4]
# Internal edges (within communities)
test_graph_data[(1, 2)] = 10.0  # Within community 1
test_graph_data[(2, 1)] = 10.0  # Symmetric
test_graph_data[(3, 4)] = 8.0   # Within community 2  
test_graph_data[(4, 3)] = 8.0   # Symmetric

# External edges (between communities)
test_graph_data[(2, 3)] = 5.0   # Between communities
test_graph_data[(3, 2)] = 5.0   # Symmetric
test_graph_data[(1, 4)] = 3.0   # Between communities
test_graph_data[(4, 1)] = 3.0   # Symmetric

println("📊 Test Graph Structure:")
println("   Community 1: [1, 2] with internal edge weight 10")
println("   Community 2: [3, 4] with internal edge weight 8") 
println("   External edges: (2,3)=5, (1,4)=3")
println()

# Calculate degrees for each node
for node in 1:4
    degree = get_node_edge_weight(test_graph_data, node)
    println("   Node $node degree: $degree")
end

println()

# Calculate modularity for each community
community1 = [1, 2]
community2 = [3, 4]

mod1 = calculate_community_modularity(test_graph_data, community1)
mod2 = calculate_community_modularity(test_graph_data, community2)

println("🔍 Modularity Results:")
println("   Community 1 [1,2]: $mod1")
println("   Community 2 [3,4]: $mod2")

println("\n💡 Analysis:")
println("   - Node degrees include ALL edges (internal + external)")
println("   - Modularity calculation only counts internal edges")
println("   - This is the CORRECT standard modularity formula!")
println("   - Higher external connectivity → lower modularity score")

# Manual verification for community 1
total_weight = sum(values(test_graph_data))
two_m = total_weight
println("\n🧮 Manual verification for Community 1:")
println("   Total graph weight (2m): $two_m")

# Internal edges in community 1
A_11 = get(test_graph_data, (1,1), 0.0)
A_12 = get(test_graph_data, (1,2), 0.0) 
A_21 = get(test_graph_data, (2,1), 0.0)
A_22 = get(test_graph_data, (2,2), 0.0)

println("   Internal edges: A_11=$A_11, A_12=$A_12, A_21=$A_21, A_22=$A_22")

k1 = get_node_edge_weight(test_graph_data, 1)
k2 = get_node_edge_weight(test_graph_data, 2)
println("   Node degrees: k1=$k1, k2=$k2")

expected_11 = (k1 * k1) / two_m
expected_12 = (k1 * k2) / two_m  
expected_21 = (k2 * k1) / two_m
expected_22 = (k2 * k2) / two_m

println("   Expected weights: E_11=$expected_11, E_12=$expected_12, E_21=$expected_21, E_22=$expected_22")

manual_mod = ((A_11 - expected_11) + (A_12 - expected_12) + (A_21 - expected_21) + (A_22 - expected_22)) / two_m
println("   Manual calculation: $manual_mod")
println("   Function result: $mod1")
println("   Match: $(abs(manual_mod - mod1) < 1e-10)")
