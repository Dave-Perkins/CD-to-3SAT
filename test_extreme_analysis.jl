#!/usr/bin/env julia
# Test extreme community separation

include("src/community_sat_solver_clean.jl")

markdown_file = "test_positive_modularity.md"
graph_file = "test_extreme_modularity.txt"

println("🔬 Testing EXTREME Community Separation")
println("="^60)

if isfile(markdown_file) && isfile(graph_file)
    # Load graph  
    println("📊 Loading extremely separated communities graph")
    edge_list = read_edges(graph_file)
    g, edge_weights = build_graph(edge_list)
    println("   Nodes: $(nv(g)), Edges: $(ne(g))")
    
    # Test communities
    communities = [[1,2,5,6], [3,4,7,8]]
    
    println("\n🔍 Modularity Analysis:")
    for (i, community) in enumerate(communities)
        mod_score = calculate_community_modularity(edge_weights, community)
        println("   Community $i: modularity = $(round(mod_score, digits=4))")
        
        if mod_score > 0
            println("      🎉 POSITIVE modularity achieved!")
        else
            println("      😕 Still negative: $(round(mod_score, digits=4))")
        end
    end
    
    # Manual calculation to understand why
    println("\n🧮 Manual Analysis:")
    total_weight = sum(values(edge_weights))
    println("   Total graph weight: $total_weight")
    
    # Community 1 analysis
    community1 = [1,2,5,6]
    internal_edges = 0.0
    for i in community1, j in community1
        if haskey(edge_weights, (i,j))
            internal_edges += edge_weights[(i,j)]
        end
    end
    println("   Community 1 internal weight: $internal_edges")
    
    # Node degrees
    for node in community1
        degree = get_node_edge_weight(edge_weights, node)
        println("   Node $node degree: $degree")
    end
    
else
    println("❌ Files not found")
end
