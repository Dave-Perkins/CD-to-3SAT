#!/usr/bin/env julia
# Comprehensive test of the community-guided SAT solver

println("🧪 Community-Guided SAT Solver - Full Test")
println("="^50)

include("src/community_sat_solver_clean.jl")

# Test with an existing research instance
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
            println("   🔍 The algorithm successfully used community structure to guide variable assignments!")
        else
            println("   ❌ No satisfying assignment found with this approach")
            println("   📝 This could mean:")
            println("     - The instance is unsatisfiable")
            println("     - Our community-based heuristic didn't find the right assignment")
            println("     - The node-to-literal mapping needs refinement")
        end
        
    catch e
        println("❌ Error during testing: $e")
        println("\nStacktrace:")
        for frame in stacktrace(catch_backtrace())
            println("  $frame")
        end
    end
else
    println("❌ Test files not found:")
    println("   Looking for: $markdown_file")
    println("   Looking for: $graph_file")
    println("   Please check that these files exist")
end

println("\n📝 Note: This is the first full implementation test of our community-guided SAT solver!")
println("   The algorithm implements the pseudocode from pseudocode_CD_3SAT.md")
