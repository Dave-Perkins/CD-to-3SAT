#!/usr/bin/env julia
# Understand why modularity is exactly -0.5

include("src/community_sat_solver_clean.jl")

graph_file = "test_extreme_modularity.txt"

println("🔬 Understanding Modularity = -0.5")
println("="^60)

# Load graph  
edge_list = read_edges(graph_file)
g, edge_weights = build_graph(edge_list)
println("📊 Graph: $(nv(g)) nodes, $(ne(g)) edges")

# Test communities
communities = [[1,2,5,6], [3,4,7,8]]

# Calculate total weight
total_weight = sum(values(edge_weights))
two_m = total_weight
println("🔢 Total weight (2m): $two_m")

# Community 1 analysis
community1 = [1,2,5,6]
println("\n📊 Community 1 Analysis: $community1")

# Count internal edges
global internal_weight = 0.0
for i in community1, j in community1
    if haskey(edge_weights, (i,j))
        weight = edge_weights[(i,j)]
        global internal_weight += weight
        println("   Edge ($i,$j): weight $weight")
    end
end
println("   Total internal weight: $internal_weight")

# Calculate node degrees
println("\n🔗 Node degrees:")
global total_degree_product = 0.0
for i in community1
    ki = get_node_edge_weight(edge_weights, i)
    println("   Node $i: degree $ki")
    for j in community1
        kj = get_node_edge_weight(edge_weights, j)
        expected = (ki * kj) / two_m
        global total_degree_product += expected
    end
end

println("   Sum of expected weights: $total_degree_product")
println("   Internal - Expected: $(internal_weight - total_degree_product)")
println("   Modularity = (Internal - Expected) / 2m = $((internal_weight - total_degree_product) / two_m)")

# The issue: in our calculation, we're treating this as a single community
# But modularity = -0.5 suggests each community has equal internal/external connectivity
println("\n💡 Analysis:")
println("   Modularity = -0.5 means each community is exactly as connected internally")
println("   as it would be under random connection (null model)")
println("   This happens when community structure isn't better than random!")

# Let's create a truly better structure
println("\n🎯 Let's try a star topology within communities...")

star_edges = Dict{Tuple{Int,Int}, Float64}()
# Community 1: star with node 1 at center
star_edges[(1,2)] = 10.0
star_edges[(2,1)] = 10.0
star_edges[(1,5)] = 10.0  
star_edges[(5,1)] = 10.0
star_edges[(1,6)] = 10.0
star_edges[(6,1)] = 10.0

# Community 2: star with node 3 at center  
star_edges[(3,4)] = 10.0
star_edges[(4,3)] = 10.0
star_edges[(3,7)] = 10.0
star_edges[(7,3)] = 10.0
star_edges[(3,8)] = 10.0
star_edges[(8,3)] = 10.0

println("🌟 Star topology modularity:")
mod1 = calculate_community_modularity(star_edges, [1,2,5,6])
mod2 = calculate_community_modularity(star_edges, [3,4,7,8])
println("   Community 1: $mod1")
println("   Community 2: $mod2")
