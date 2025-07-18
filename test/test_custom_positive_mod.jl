#!/usr/bin/env julia
# Test our custom instance designed for positive modularity

include("src/community_sat_solver_clean.jl")

markdown_file = "test_positive_modularity.md"
graph_file = "test_positive_modularity.txt"

println("🧪 Testing Custom Instance for Positive Modularity")
println("="^60)

if isfile(markdown_file) && isfile(graph_file)
    println("✅ Found custom test files")
    
    # Parse formula
    println("\n📖 Step 1: Parsing custom formula")
    formula = parse_formula_from_markdown(markdown_file)
    println("   Variables: $(formula.num_variables)")
    println("   Clauses: $(length(formula.clauses))")
    
    # Load graph  
    println("\n📊 Step 2: Loading custom graph")
    edge_list = read_edges(graph_file)
    g, edge_weights = build_graph(edge_list)
    println("   Nodes: $(nv(g)), Edges: $(ne(g))")
    
    # Use the designed communities (instead of dummy split)
    # Community 1: [1,2,5,6] = x1, x2, ¬x1, ¬x2
    # Community 2: [3,4,7,8] = x3, x4, ¬x3, ¬x4
    communities = [[1,2,5,6], [3,4,7,8]]
    
    println("\n🏘️  Step 3: Using designed communities")
    println("   Community 1: [1,2,5,6] = x1, x2, ¬x1, ¬x2")
    println("   Community 2: [3,4,7,8] = x3, x4, ¬x3, ¬x4")
    
    # Calculate modularity for each community
    println("\n🔍 Modularity Analysis:")
    for (i, community) in enumerate(communities)
        mod_score = calculate_community_modularity(edge_weights, community)
        println("   Community $i: modularity = $(round(mod_score, digits=4))")
        
        if mod_score > 0
            println("      🎉 POSITIVE modularity! Strong community structure!")
        else
            println("      😕 Negative modularity. Not as cohesive as expected.")
        end
    end
    
    # Run solver
    println("\n🚀 Step 4: Running solver with custom communities")
    assignment, satisfied = community_sat_solve(formula, edge_weights, communities, verbose=true)
    
    println("\n🎯 RESULTS:")
    if satisfied
        println("   ✅ SUCCESS with positive modularity communities!")
        vars = sort(collect(keys(assignment)))
        assignment_str = join(["$var=$(assignment[var] ? 1 : 0)" for var in vars], ", ")
        println("   📋 Assignment: $assignment_str")
    else
        println("   ❌ Failed even with designed communities")
    end
    
else
    println("❌ Custom files not found - they should be in the current directory")
end
