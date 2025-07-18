#!/usr/bin/env julia
# Test the positive modularity instance

include("src/community_sat_solver_clean.jl")

println("🎯 Testing 3-SAT Instance Designed for Positive Modularity")
println("="^70)

markdown_file = "positive_modularity_instance.md"
graph_file = "positive_modularity_instance.txt"

if isfile(markdown_file) && isfile(graph_file)
    println("✅ Found custom positive modularity files")
    
    # Parse formula
    println("\n📖 Step 1: Parsing the designed formula")
    formula = parse_formula_from_markdown(markdown_file)
    println("   Variables: $(formula.num_variables)")
    println("   Clauses: $(length(formula.clauses))")
    
    # Load graph
    println("\n📊 Step 2: Loading the designed graph")
    edge_list = read_edges(graph_file)
    g, edge_weights = build_graph(edge_list)
    println("   Nodes: $(nv(g)), Edges: $(ne(g))")
    
    # Use the designed communities
    # Community 1: [1,2,3,7,8,9] = x1, x2, x3, ¬x1, ¬x2, ¬x3
    # Community 2: [4,5,6,10,11,12] = x4, x5, x6, ¬x4, ¬x5, ¬x6
    communities = [[1,2,3,7,8,9], [4,5,6,10,11,12]]
    
    println("\n🏘️  Step 3: Using designed communities")
    println("   Community 1: [1,2,3,7,8,9] = x1,x2,x3,¬x1,¬x2,¬x3")
    println("   Community 2: [4,5,6,10,11,12] = x4,x5,x6,¬x4,¬x5,¬x6")
    
    # Calculate modularity
    println("\n🔍 Step 4: Modularity Analysis")
    overall_mod = calculate_overall_modularity(edge_weights, communities)
    println("   Overall graph modularity: $(round(overall_mod, digits=4))")
    
    if overall_mod > 0
        println("   🎉 POSITIVE MODULARITY ACHIEVED!")
        println("   🌟 This indicates excellent community structure!")
    else
        println("   😞 Still negative: $(round(overall_mod, digits=4))")
        println("   🔧 May need to adjust inter-community connection strength")
    end
    
    # Calculate individual contributions
    println("\n📊 Individual community contributions:")
    for (i, community) in enumerate(communities)
        contrib = calculate_community_contribution_to_modularity(edge_weights, community, communities)
        println("   Community $i: $(round(contrib, digits=4))")
        
        if contrib > 0
            println("      ✨ Positive contribution!")
        else
            println("      📉 Negative contribution: $(round(contrib, digits=4))")
        end
    end
    
    # Test the solver
    println("\n🚀 Step 5: Testing SAT Solver")
    assignment, satisfied = community_sat_solve(formula, edge_weights, communities, verbose=true)
    
    println("\n🎯 FINAL RESULTS:")
    if satisfied
        println("   ✅ SUCCESS with $(overall_mod > 0 ? "POSITIVE" : "negative") modularity!")
        vars = sort(collect(keys(assignment)))
        assignment_str = join(["$var=$(assignment[var] ? 1 : 0)" for var in vars], ", ")
        println("   📋 Assignment: $assignment_str")
        
        if overall_mod > 0
            println("   🏆 ACHIEVEMENT UNLOCKED: SAT solved with positive modularity communities!")
        end
    else
        println("   ❌ Failed even with designed communities")
        println("   🤔 This suggests the instance may be unsatisfiable or need different design")
    end
    
else
    println("❌ Files not found!")
    println("   Looking for: $markdown_file")
    println("   Looking for: $graph_file")
end
