#!/usr/bin/env julia

# Test the visualization function directly
include("src/community_sat_solver_clean.jl")

println("🧪 Testing Graph Visualization Function")
println("=" ^ 50)

# Test with a simple case
md_file = "research/research_3vars_5clauses_seed42.md"
graph_file = "research/research_3vars_5clauses_seed42.txt"

if isfile(md_file) && isfile(graph_file)
    println("📝 Loading test data...")
    
    # Parse formula
    formula = parse_formula_from_markdown(md_file)
    println("   Variables: $(formula.num_variables)")
    println("   Clauses: $(length(formula.clauses))")
    
    # Load graph
    edge_list = read_edges(graph_file)
    g, edge_weights = build_graph(edge_list)
    println("   Nodes: $(nv(g)), Edges: $(ne(g))")
    
    # Create dummy communities
    all_nodes = collect(1:nv(g))
    mid_point = div(length(all_nodes), 2)
    communities = [all_nodes[1:mid_point], all_nodes[mid_point+1:end]]
    println("   Communities: $(length(communities))")
    
    println()
    println("🎨 Testing visualization function...")
    
    try
        # Test without assignment
        println("   📊 Showing graph with communities only...")
        result1 = visualize_sat_solving(formula, edge_weights, communities, nothing, show_graph=true)
        
        if result1
            println("   ✅ Community visualization successful!")
            
            # Test with dummy assignment  
            println("   📊 Showing graph with variable assignment...")
            dummy_assignment = Dict("x1" => true, "x2" => false, "x3" => true)
            result2 = visualize_sat_solving(formula, edge_weights, communities, dummy_assignment, show_graph=true)
            
            if result2
                println("   ✅ Assignment visualization successful!")
                println()
                println("🎉 All visualization tests passed!")
                println("   Two interactive windows should be displayed.")
            else
                println("   ⚠️  Assignment visualization failed")
            end
        else
            println("   ⚠️  Community visualization failed")
        end
        
    catch e
        println("   ❌ Visualization error: $e")
        println("   This is expected in headless environments")
    end
    
else
    println("❌ Test files not found")
end
