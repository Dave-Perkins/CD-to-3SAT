#!/usr/bin/env julia

include("src/community_sat_solver_clean.jl")

println("🔧 Testing Fixed Degree and Modularity Calculation")
println("=" ^ 60)

# Test with simple path graph: 1-2-3-4
test_edges = Dict{Tuple{Int,Int}, Float64}()
test_edges[(1,2)] = 1.0
test_edges[(2,1)] = 1.0
test_edges[(2,3)] = 1.0
test_edges[(3,2)] = 1.0
test_edges[(3,4)] = 1.0
test_edges[(4,3)] = 1.0

communities = [[1,2], [3,4]]

println("📊 Test graph (path 1-2-3-4):")
println("   Edges: $test_edges")
println("   Communities: $communities")
println()

println("🔧 Testing fixed degree calculation:")
for node in 1:4
    degree = get_node_edge_weight(test_edges, node)
    println("   Node $node degree: $degree")
end
println()

println("🎯 Expected degrees:")
println("   Node 1: 1.0, Node 2: 2.0, Node 3: 2.0, Node 4: 1.0")
println()

println("📊 Testing fixed modularity calculation:")
modularity = calculate_overall_modularity(test_edges, communities)
println("   Modularity: $(round(modularity, digits=4))")
println("   Expected range: [-0.5, 1.0]")

if modularity >= -0.5 && modularity <= 1.0
    println("   ✅ Within bounds!")
    println("   🎉 Bug fixed successfully!")
else
    println("   ❌ Still out of bounds")
end
println()

# Also test with our original problematic test case
println("🧪 Testing with original test case from debug script:")
edges2 = Dict{Tuple{Int,Int}, Float64}()
edges2[(1,2)] = 1.0
edges2[(2,1)] = 1.0
edges2[(2,3)] = 1.0
edges2[(3,2)] = 1.0
edges2[(3,4)] = 1.0
edges2[(4,3)] = 1.0

communities2 = [[1,2], [3,4]]
modularity2 = calculate_overall_modularity(edges2, communities2)
println("   Original test case modularity: $(round(modularity2, digits=4))")

if modularity2 >= -0.5 && modularity2 <= 1.0
    println("   ✅ Original case now within bounds!")
else
    println("   ❌ Original case still problematic")
end
