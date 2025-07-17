#!/usr/bin/env julia
# Test with CORRECT multi-community modularity calculation

include("src/community_sat_solver_clean.jl")

function calculate_correct_modularity(edge_weights, all_communities)
    """Calculate modularity for the entire partition (all communities together)"""
    
    # Calculate total weight
    total_weight = sum(values(edge_weights))
    two_m = total_weight
    
    if two_m == 0
        return 0.0
    end
    
    # Calculate modularity for the entire partition
    total_modularity = 0.0
    
    for community in all_communities
        community_modularity = 0.0
        
        for i in community
            for j in community
                # Get actual edge weight A_ij
                A_ij = get(edge_weights, (i, j), 0.0)
                
                # Expected weight under null model
                ki = get_node_edge_weight(edge_weights, i)
                kj = get_node_edge_weight(edge_weights, j)
                expected_weight = (ki * kj) / two_m
                
                # Add contribution
                community_modularity += (A_ij - expected_weight)
            end
        end
        
        total_modularity += community_modularity
    end
    
    # Normalize by 2m
    return total_modularity / two_m
end

function calculate_community_contribution(edge_weights, community, all_communities)
    """Calculate what one community contributes to overall modularity"""
    
    total_weight = sum(values(edge_weights))
    two_m = total_weight
    
    if two_m == 0
        return 0.0
    end
    
    community_modularity = 0.0
    
    for i in community
        for j in community
            # Get actual edge weight A_ij
            A_ij = get(edge_weights, (i, j), 0.0)
            
            # Expected weight under null model
            ki = get_node_edge_weight(edge_weights, i)
            kj = get_node_edge_weight(edge_weights, j)
            expected_weight = (ki * kj) / two_m
            
            # Add contribution
            community_modularity += (A_ij - expected_weight)
        end
    end
    
    # Return contribution (not normalized - that happens at the end)
    return community_modularity / two_m
end

println("🎯 CORRECT Modularity Calculation Test")
println("="^60)

# Test with our extreme graph
edge_list = read_edges("test_extreme_modularity.txt")
g, edge_weights = build_graph(edge_list)

communities = [[1,2,5,6], [3,4,7,8]]

println("📊 Graph: $(nv(g)) nodes, $(ne(g)) edges")
println("🏘️  Communities: $communities")

# Calculate overall modularity
overall_mod = calculate_correct_modularity(edge_weights, communities)
println("\n🌍 Overall modularity for partition: $(round(overall_mod, digits=4))")

# Calculate each community's contribution
println("\n📊 Individual community contributions:")
for (i, community) in enumerate(communities)
    contrib = calculate_community_contribution(edge_weights, community, communities)
    println("   Community $i: $(round(contrib, digits=4))")
end

if overall_mod > 0
    println("\n🎉 SUCCESS! Positive modularity achieved!")
    println("   This indicates good community structure!")
else
    println("\n🤔 Still negative modularity: $(round(overall_mod, digits=4))")
    println("   This suggests communities aren't better than random placement")
end

# Test completely disconnected communities
println("\n" * "="^60)
println("🔬 Testing Completely Disconnected Communities")

disconnected_edges = Dict{Tuple{Int,Int}, Float64}()
# Community 1: complete graph
for i in [1,2,5,6], j in [1,2,5,6]
    if i != j
        disconnected_edges[(i,j)] = 10.0
    end
end
# Community 2: complete graph  
for i in [3,4,7,8], j in [3,4,7,8]
    if i != j
        disconnected_edges[(i,j)] = 10.0
    end
end
# NO inter-community edges!

disconnected_mod = calculate_correct_modularity(disconnected_edges, communities)
println("🔗 Completely disconnected modularity: $(round(disconnected_mod, digits=4))")

if disconnected_mod > 0
    println("🎉 POSITIVE modularity with complete separation!")
else
    println("😞 Still negative even with complete separation")
end
