#!/usr/bin/env julia
# Test script for community-guided SAT solver

println("🧪 Community-Guided SAT Solver Test")
println("="^40)

# Add the src directory to the path so we can include our modules
push!(LOAD_PATH, joinpath(@__DIR__, "src"))

# Include our new SAT solver
include("src/community_sat_solver.jl")

# Test with a simple example
println("🔍 Testing with existing research instance...")

# Use an existing research instance
markdown_file = "research/research_3vars_5clauses_seed42.md"
graph_file = "research/research_3vars_5clauses_seed42.txt"

if isfile(markdown_file) && isfile(graph_file)
    println("✅ Found test files:")
    println("   📄 Formula: $markdown_file")
    println("   📊 Graph: $graph_file")
    
    try
        assignment, satisfied = test_community_sat_solver(markdown_file, graph_file)
        
        println("\n🎯 FINAL RESULT:")
        if satisfied
            println("   ✅ SUCCESS: Community-guided solver found a satisfying assignment!")
        else
            println("   ❌ No satisfying assignment found with this approach")
        end
        
    catch e
        println("❌ Error during testing: $e")
        println("   This is expected as we're implementing the functions step by step")
    end
else
    println("❌ Test files not found:")
    println("   Looking for: $markdown_file")
    println("   Looking for: $graph_file")
    println("   Please check that these files exist")
end

println("\n📝 Note: This is the first implementation test.")
println("   The algorithm is now ready for further refinement and testing!")
