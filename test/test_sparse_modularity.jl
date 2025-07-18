#!/usr/bin/env julia
# Create a graph that SHOULD have positive modularity

include("src/community_sat_solver_clean.jl")

# Create a "path" topology within communities instead of complete graphs
sparse_edges = Dict{Tuple{Int,Int}, Float64}()

# Community 1: simple path 1-2-5-6
sparse_edges[(1,2)] = 10.0
sparse_edges[(2,1)] = 10.0
sparse_edges[(2,5)] = 10.0  
sparse_edges[(5,2)] = 10.0
sparse_edges[(5,6)] = 10.0
sparse_edges[(6,5)] = 10.0

# Community 2: simple path 3-4-7-8
sparse_edges[(3,4)] = 10.0
sparse_edges[(4,3)] = 10.0
sparse_edges[(4,7)] = 10.0
sparse_edges[(7,4)] = 10.0
sparse_edges[(7,8)] = 10.0
sparse_edges[(8,7)] = 10.0

# One weak inter-community edge
sparse_edges[(2,3)] = 1.0
sparse_edges[(3,2)] = 1.0

communities = [[1,2,5,6], [3,4,7,8]]

function calculate_full_modularity(edge_weights, all_communities)
    total_weight = sum(values(edge_weights))
    two_m = total_weight
    
    if two_m == 0
        return 0.0
    end
    
    total_modularity = 0.0
    
    for community in all_communities
        for i in community
            for j in community
                A_ij = get(edge_weights, (i, j), 0.0)
                ki = get_node_edge_weight(edge_weights, i)
                kj = get_node_edge_weight(edge_weights, j)
                expected = (ki * kj) / two_m
                total_modularity += (A_ij - expected)
            end
        end
    end
    
    return total_modularity / two_m
end

println("🎯 Testing SPARSE Community Structure")
println("="^60)

overall_mod = calculate_full_modularity(sparse_edges, communities)
println("🌍 Modularity with sparse internal structure: $(round(overall_mod, digits=4))")

if overall_mod > 0
    println("🎉 FINALLY! Positive modularity achieved!")
    
    # Now test our SAT solver with this structure
    println("\n🚀 Testing SAT solver with positive modularity!")
    
    # Create the graph file
    open("test_sparse_positive.txt", "w") do file
        for ((i,j), weight) in sparse_edges
            println(file, "$i $j $weight")
        end
    end
    
    # Test it
    markdown_file = "test_positive_modularity.md"
    graph_file = "test_sparse_positive.txt"
    
    formula = parse_formula_from_markdown(markdown_file)
    edge_list = read_edges(graph_file)
    g, edge_weights = build_graph(edge_list)
    
    println("\n📊 Testing with SAT solver:")
    assignment, satisfied = community_sat_solve(formula, edge_weights, communities, verbose=true)
    
    if satisfied
        println("\n🎉 SUCCESS with positive modularity communities!")
    else
        println("\n❌ Failed even with positive modularity")
    end
    
else
    println("😞 Still negative: $(round(overall_mod, digits=4))")
    
    # Try even sparser
    println("\n🔬 Trying MINIMAL connectivity...")
    minimal_edges = Dict{Tuple{Int,Int}, Float64}()
    
    # Community 1: just one edge
    minimal_edges[(1,2)] = 10.0
    minimal_edges[(2,1)] = 10.0
    
    # Community 2: just one edge
    minimal_edges[(3,4)] = 10.0  
    minimal_edges[(4,3)] = 10.0
    
    minimal_mod = calculate_full_modularity(minimal_edges, communities)
    println("🔗 Minimal connectivity modularity: $(round(minimal_mod, digits=4))")
    
    if minimal_mod > 0
        println("🎉 Positive with minimal connectivity!")
    end
end
