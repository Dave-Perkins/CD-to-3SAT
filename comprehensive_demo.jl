#!/usr/bin/env julia

# Comprehensive Demo: Community-Guided SAT Solver with Interactive Visualization
include("src/community_sat_solver_clean.jl")

println("🎨 COMPREHENSIVE DEMO: Interactive Community-Guided SAT Solver")
println("=" ^ 80)
println("This demo shows how our SAT solver uses community detection to guide")
println("variable assignments, with beautiful interactive graph visualizations!")
println()

# Test cases to demonstrate
test_cases = [
    ("research/research_3vars_5clauses_seed42.md", "research/research_3vars_5clauses_seed42.txt", "3-variable easy instance"),
    ("research/research_3vars_7clauses_seed777.md", "research/research_3vars_7clauses_seed777.txt", "3-variable harder instance")
]

for (i, (md_file, graph_file, description)) in enumerate(test_cases)
    if isfile(md_file) && isfile(graph_file)
        println("📊 TEST CASE $i: $description")
        println("   Files: $(basename(md_file)) & $(basename(graph_file))")
        println("─" ^ 60)
        
        try
            # Run with visualization
            println("🎬 Running SAT solver with interactive visualization...")
            assignment, satisfied = test_community_sat_solver(md_file, graph_file, 
                                                            verbose=true, 
                                                            show_visualization=true)
            
            # Results summary
            println("\n📋 RESULTS FOR TEST CASE $i:")
            if satisfied
                println("   ✅ SAT SOLVING: SUCCESS!")
                println("   📊 Assignment: $assignment")
                println("   🎨 Graphs: Two interactive windows displayed")
            else
                println("   ❌ SAT SOLVING: No solution found")
            end
            
            if i < length(test_cases)
                println("\n" * "⏸️ " * "─" ^ 40 * " ⏸️")
                println("Interactive graphs are displayed. Close them to continue to next test case.")
                println("Press Enter when ready for the next test case...")
                readline()
                println()
            end
            
        catch e
            println("❌ Error in test case $i: $e")
        end
        
    else
        println("⚠️  Test case $i files not found:")
        println("   $(md_file): $(isfile(md_file))")
        println("   $(graph_file): $(isfile(graph_file))")
        println()
    end
end

println("\n🎉 DEMO COMPLETE!")
println("=" ^ 50)
println("What you saw:")
println("🔍 Graph Structure Analysis:")
println("   • Community detection divides nodes into groups")
println("   • Communities shown in different colors (red, blue, etc.)")
println("   • Modularity scores guide which communities to process first")
println()
println("🧠 SAT Solving Process:")
println("   • Algorithm prioritizes high-modularity communities")
println("   • Within each community, nodes sorted by edge weight")
println("   • Variable assignments propagate to satisfy formula")
println()
println("🎨 Visualization Features:")
println("   • Before: Communities highlighted by color")
println("   • After: Variable assignments shown (green=true, gray=false)")
println("   • Interactive: Drag nodes, zoom, explore the structure!")
println()
println("🔬 Technical Details:")
println("   • Fixed modularity calculation (now within bounds [-0.5, 1.0])")
println("   • Community-guided heuristic improves SAT solving efficiency")
println("   • Graph visualization helps understand the problem structure")
println()
println("💡 This demonstrates how graph theory and community detection")
println("   can be used to solve complex combinatorial problems like 3-SAT!")

# Optional: Show available files for further exploration
println("\n📁 Other test files available for exploration:")
for file in readdir(".")
    if (endswith(file, ".md") || endswith(file, ".txt")) && contains(file, "research")
        println("   $file")
    end
end
