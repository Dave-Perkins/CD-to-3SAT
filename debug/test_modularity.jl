include("plot_graph.jl")
include("scoring.jl")

# Simple test to verify modularity calculation
using Graphs

# Create a simple triangle: 3 nodes, 3 edges
g = SimpleGraph(3)
add_edge!(g, 1, 2)
add_edge!(g, 2, 3) 
add_edge!(g, 1, 3)

edge_weights = Dict{Tuple{Int,Int}, Float64}()
edge_weights[(1,2)] = 1.0
edge_weights[(2,3)] = 1.0
edge_weights[(1,3)] = 1.0

mutable struct NodeInfo
    label::Int
    neighbors::Vector{Int}
end

node_info = Dict{Int, NodeInfo}()
for n in 1:3
    node_info[n] = NodeInfo(n, collect(neighbors(g, n)))
end

println("🔍 Testing Modularity on Triangle Graph")
println("Nodes: 3, Edges: 3, Each node degree: 2, Total degree (2m): 6")

# Case 1: All in one community
println("\n📊 Case 1: All nodes in one community")
one_community = [1, 1, 1]
score1 = get_score(g, edge_weights, node_info, one_community)
println("Modularity: $(round(score1, digits=4))")

# Manual calculation:
# Sum over all pairs in same community:
# (1,1): A_11 - (k_1*k_1)/(2m) = 0 - (2*2)/6 = -2/3
# (1,2): A_12 - (k_1*k_2)/(2m) = 1 - (2*2)/6 = 1 - 2/3 = 1/3  
# (1,3): A_13 - (k_1*k_3)/(2m) = 1 - (2*2)/6 = 1/3
# (2,2): A_22 - (k_2*k_2)/(2m) = 0 - (2*2)/6 = -2/3
# (2,3): A_23 - (k_2*k_3)/(2m) = 1 - (2*2)/6 = 1/3
# (3,3): A_33 - (k_3*k_3)/(2m) = 0 - (2*2)/6 = -2/3
# Sum = -2/3 + 1/3 + 1/3 - 2/3 + 1/3 - 2/3 = -3/3 = -1
# Modularity = (-1) / (2m) = -1/6 ≈ -0.167

manual_result = (-2/3 + 1/3 + 1/3 - 2/3 + 1/3 - 2/3) / 6
println("Expected (manual): $(round(manual_result, digits=4))")

# Case 2: All separate communities
println("\n📊 Case 2: All nodes in separate communities")
separate_communities = [1, 2, 3]
score2 = get_score(g, edge_weights, node_info, separate_communities)
println("Modularity: $(round(score2, digits=4))")

# Manual: Only diagonal terms
# (1,1): -2/3, (2,2): -2/3, (3,3): -2/3
# Sum = -2, Modularity = -2/6 = -1/3 ≈ -0.333
manual_result2 = (-2/3 - 2/3 - 2/3) / 6
println("Expected (manual): $(round(manual_result2, digits=4))")
