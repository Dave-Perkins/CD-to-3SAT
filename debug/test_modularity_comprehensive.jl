using Graphs, Colors

include("scoring.jl")

# Test case 1: Triangle graph - all nodes in same community (should be ≈ 0)
println("=== TEST 1: Triangle graph, all same community ===")
g1 = SimpleGraph(3)
add_edge!(g1, 1, 2)
add_edge!(g1, 2, 3)
add_edge!(g1, 1, 3)

edge_weights1 = Dict()
for edge in edges(g1)
    edge_weights1[(src(edge), dst(edge))] = 1.0
    edge_weights1[(dst(edge), src(edge))] = 1.0
end

node_color_indices1 = [1, 1, 1]  # All same community
result1 = get_score(g1, edge_weights1, nothing, node_color_indices1)
println("Modularity (all same): ", result1)
println("Expected: ≈ 0.0")

# Test case 2: Triangle graph - each node in different community (should be negative)
println("\n=== TEST 2: Triangle graph, all different communities ===")
node_color_indices2 = [1, 2, 3]  # All different communities
result2 = get_score(g1, edge_weights1, nothing, node_color_indices2)
println("Modularity (all different): ", result2)
println("Expected: negative (around -0.5)")

# Test case 3: Simple path graph - optimal split
println("\n=== TEST 3: Path graph with optimal split ===")
g3 = SimpleGraph(4)
add_edge!(g3, 1, 2)
add_edge!(g3, 2, 3)
add_edge!(g3, 3, 4)

edge_weights3 = Dict()
for edge in edges(g3)
    edge_weights3[(src(edge), dst(edge))] = 1.0
    edge_weights3[(dst(edge), src(edge))] = 1.0
end

# Split into two communities: {1,2} and {3,4}
node_color_indices3 = [1, 1, 2, 2]
result3 = get_score(g3, edge_weights3, nothing, node_color_indices3)
println("Modularity (optimal split): ", result3)
println("Expected: positive")

# Test case 4: Disconnected graph
println("\n=== TEST 4: Disconnected graph ===")
g4 = SimpleGraph(4)
add_edge!(g4, 1, 2)  # One component
add_edge!(g4, 3, 4)  # Another component

edge_weights4 = Dict()
for edge in edges(g4)
    edge_weights4[(src(edge), dst(edge))] = 1.0
    edge_weights4[(dst(edge), src(edge))] = 1.0
end

# Each component in its own community
node_color_indices4 = [1, 1, 2, 2]
result4 = get_score(g4, edge_weights4, nothing, node_color_indices4)
println("Modularity (perfect communities): ", result4)
println("Expected: 0.5")

println("\n=== SUMMARY ===")
println("Test 1 (triangle, all same): ", result1, " (should ≈ 0)")
println("Test 2 (triangle, all diff): ", result2, " (should be negative)")
println("Test 3 (path, optimal): ", result3, " (should be positive)")
println("Test 4 (disconnected, perfect): ", result4, " (should = 0.5)")
