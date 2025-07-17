#!/usr/bin/env julia

# Interactive SAT Solver with Graph Visualization Demo
include("src/community_sat_solver_clean.jl")

println("🎨 Community-Guided SAT Solver with Interactive Visualization")
println("=" ^ 70)

# Test with a real instance
md_file = "research/research_3vars_5clauses_seed42.md"
graph_file = "research/research_3vars_5clauses_seed42.txt"

if isfile(md_file) && isfile(graph_file)
    println("📝 Testing with: $(basename(md_file))")
    println("📊 Graph file: $(basename(graph_file))")
    println()
    
    try
        println("🎬 Starting interactive demo...")
        println("   👀 Two graph windows will appear:")
        println("   1️⃣  Initial graph showing communities in different colors")
        println("   2️⃣  Final graph showing variable assignments (green=true, gray=false)")
        println()
        
        # Run the solver with visualization enabled
        assignment, satisfied = test_community_sat_solver(md_file, graph_file, 
                                                        verbose=true, 
                                                        show_visualization=true)
        
        println()
        println("🎯 FINAL RESULTS:")
        println("   ✅ Visualization: Interactive graphs displayed")
        if satisfied
            println("   ✅ SAT Solving: SUCCESS!")
            vars = sort(collect(keys(assignment)))
            for var in vars
                status = assignment[var] ? "TRUE" : "FALSE"
                println("      $var = $status")
            end
        else
            println("   ❌ SAT Solving: No solution found")
        end
        
        println()
        println("📚 Graph Legend:")
        println("   🔴 Red nodes: Community 1")
        println("   🔵 Blue nodes: Community 2") 
        println("   🟢 Green nodes: Variables assigned TRUE")
        println("   ⚪ Gray nodes: Variables assigned FALSE")
        println("   📊 Edge weights show relationships between literals")
        
        println()
        println("💡 Tip: The graph windows are interactive!")
        println("   - Drag nodes to rearrange the layout")
        println("   - Zoom in/out with mouse wheel")
        println("   - Close windows when you're done exploring")
        
    catch e
        println("❌ Error during execution: $e")
        
        # Check if it's a visualization-related error
        if contains(string(e), "GLMakie") || contains(string(e), "display")
            println()
            println("💡 It looks like there might be a display issue.")
            println("   This is normal if running in:")
            println("   - SSH session without X11 forwarding")
            println("   - Headless environment")
            println("   - Terminal without graphics support")
            println()
            println("🔄 Running solver without visualization...")
            
            try
                assignment, satisfied = test_community_sat_solver(md_file, graph_file, 
                                                                verbose=true, 
                                                                show_visualization=false)
                if satisfied
                    println("   ✅ SAT solver still works without visualization!")
                end
            catch e2
                println("   ❌ Additional error: $e2")
            end
        end
    end
else
    println("❌ Test files not found:")
    println("   MD file exists: $(isfile(md_file))")
    println("   Graph file exists: $(isfile(graph_file))")
    println()
    println("📁 Available files:")
    for file in readdir(".")
        if endswith(file, ".md") || endswith(file, ".txt")
            println("   $file")
        end
    end
end
