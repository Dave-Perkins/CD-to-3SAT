#!/usr/bin/env julia
# Test ultra-sparse design

include("src/community_sat_solver_clean.jl")

println("🔬 Ultra-Sparse Graph Test for Positive Modularity")
println("="^60)

markdown_file = "positive_modularity_instance.md"
graph_file = "ultra_sparse_positive.txt"

# Load graph
edge_list = read_edges(graph_file)
g, edge_weights = build_graph(edge_list)

communities = [[1,2,3,7,8,9], [4,5,6,10,11,12]]

println("📊 Ultra-sparse graph: $(nv(g)) nodes, $(ne(g)) edges")

# Test modularity
overall_mod = calculate_overall_modularity(edge_weights, communities)
println("🔍 Overall modularity: $(round(overall_mod, digits=4))")

if overall_mod > 0
    println("🎉 FINALLY! Positive modularity: $(round(overall_mod, digits=4))")
    
    # Test the solver
    println("\n🚀 Testing SAT solver with positive modularity!")
    formula = parse_formula_from_markdown(markdown_file)
    assignment, satisfied = community_sat_solve(formula, edge_weights, communities, verbose=true)
    
    if satisfied
        println("🏆 SUCCESS: SAT solved with POSITIVE modularity communities!")
    else
        println("❌ SAT failed despite positive modularity")
    end
    
else
    println("😞 Still negative: $(round(overall_mod, digits=4))")
    
    # Try even more extreme: completely disconnected communities
    println("\n🔬 Trying completely disconnected communities...")
    
    disconnected_edges = Dict{Tuple{Int,Int}, Float64}()
    # Community 1: single edge
    disconnected_edges[(1,2)] = 10.0
    disconnected_edges[(2,1)] = 10.0
    # Community 2: single edge
    disconnected_edges[(4,5)] = 10.0
    disconnected_edges[(5,4)] = 10.0
    # NO inter-community edges
    
    disconnected_mod = calculate_overall_modularity(disconnected_edges, communities)
    println("   Completely disconnected modularity: $(round(disconnected_mod, digits=4))")
    
    if disconnected_mod > 0
        println("🎉 Positive with complete separation!")
        
        # Save and test this
        open("completely_disconnected.txt", "w") do file
            for ((i,j), weight) in disconnected_edges
                println(file, "$i $j $weight")
            end
        end
        
        println("✅ Saved completely disconnected graph")
        println("🧪 Testing SAT solver...")
        
        formula = parse_formula_from_markdown(markdown_file)
        assignment, satisfied = community_sat_solve(formula, disconnected_edges, communities, verbose=false)
        
        println("📋 Result: $(satisfied ? "SUCCESS" : "FAILED")")
        if satisfied
            vars = sort(collect(keys(assignment)))
            assignment_str = join(["$var=$(assignment[var] ? 1 : 0)" for var in vars], ", ")
            println("🏆 POSITIVE MODULARITY SAT SOLUTION: $assignment_str")
        end
    else
        println("😞 Even complete separation gives negative modularity")
        println("💡 This suggests fundamental mathematical constraints in small graphs")
    end
end
