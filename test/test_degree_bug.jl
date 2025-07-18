#!/usr/bin/env julia

include("src/community_sat_solver_clean.jl")

println("🔍 Testing degree calculation bug")
println("=" ^ 50)

# Create simple test graph: 1-2-3-4 (path)
test_edges = Dict{Tuple{Int,Int}, Float64}()
test_edges[(1,2)] = 1.0
test_edges[(2,1)] = 1.0
test_edges[(2,3)] = 1.0  
test_edges[(3,2)] = 1.0
test_edges[(3,4)] = 1.0
test_edges[(4,3)] = 1.0

println("📊 Test graph (path 1-2-3-4):")
println("   Edges: $test_edges")
println()

println("🧮 Using our get_node_edge_weight function:")
for node in 1:4
    degree = get_node_edge_weight(test_edges, node)
    println("   Node $node degree: $degree")
end
println()

println("🎯 Expected degrees for undirected path graph:")
println("   Node 1 degree: 1.0 (connected to 2)")
println("   Node 2 degree: 2.0 (connected to 1,3)")  
println("   Node 3 degree: 2.0 (connected to 2,4)")
println("   Node 4 degree: 1.0 (connected to 3)")
println()

println("❌ Problem: Our function double-counts because each undirected edge")
println("   appears twice in the dictionary as (i,j) and (j,i)")
println()

# Test the corrected calculation
println("✅ Corrected calculation:")
for node in 1:4
    corrected_degree = get_node_edge_weight(test_edges, node) / 2.0
    println("   Node $node corrected degree: $corrected_degree")
end
println()

# Test modularity with corrected degrees
communities = [[1,2], [3,4]]
println("🧪 Testing modularity with corrected degrees:")

total_weight = sum(values(test_edges))
two_m = total_weight
println("   Total weight (2m): $two_m")

total_modularity = 0.0
for community in communities
    community_sum = 0.0
    for i in community
        for j in community
            A_ij = get(test_edges, (i, j), 0.0)
            ki = get_node_edge_weight(test_edges, i) / 2.0  # Corrected degree
            kj = get_node_edge_weight(test_edges, j) / 2.0  # Corrected degree
            expected = (ki * kj) / two_m
            contribution = A_ij - expected
            community_sum += contribution
        end
    end
    total_modularity += community_sum / two_m
end

println("   Modularity with corrected degrees: $(round(total_modularity, digits=4))")
println("   Expected range: [-0.5, 1.0]")

if total_modularity >= -0.5 && total_modularity <= 1.0
    println("   ✅ Within bounds!")
else
    println("   ❌ Still out of bounds")
end
