# Simple test to extract modularity scores from community detection
# Using small research instances as requested

# Add src to load path
push!(LOAD_PATH, joinpath(@__DIR__, "src"))

# Include the community guided SAT solver directly
include("src/community_guided_sat.jl")

# Test on a small research instance
function test_modularity_extraction()
    println("🔬 Testing Modularity Score Extraction")
    println("=" ^ 50)
    
    # Use a small instance as requested
    test_file = "research/research_3vars_5clauses_seed42.md"
    
    if !isfile(test_file)
        println("❌ Test file not found: $test_file")
        return
    end
    
    println("📝 Testing file: $test_file")
    
    try
        # Use the community guided solver to get modularity
        result = community_guided_sat_solve(test_file, verbose=false)
        
        println("✅ Community-guided solving completed!")
        println("📊 Results:")
        println("   • Satisfiable: $(result.satisfiable)")
        println("   • Assignment found: $(result.assignment !== nothing)")
        println("   • 🎯 MODULARITY SCORE: $(result.modularity_score)")
        println("   • Communities found: $(length(result.communities))")
        println("   • Solve time: $(result.solve_time)s")
        
        if result.traditional_sat_result !== nothing
            println("   • Traditional SAT result available: Yes")
        end
        
        return result.modularity_score
        
    catch e
        println("❌ Error during community-guided solving:")
        println("   $e")
        return nothing
    end
end

# Run the test
if abspath(PROGRAM_FILE) == @__FILE__
    test_modularity_extraction()
end
