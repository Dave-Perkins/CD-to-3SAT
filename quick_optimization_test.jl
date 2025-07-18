# Quick test for node sorting optimization using the generated example
using Pkg
Pkg.activate(".")

include("src/community_guided_sat.jl")

println("Testing Node Sorting Optimization:")
println("Changed from highest-to-lowest to lowest-to-highest weight processing")
println("=" ^ 60)

# Test on the generated example
test_file = "examples/example_3sat.md"

if isfile(test_file)
    println("\nTesting: $test_file")
    
    try
        # Run with v2 algorithm (current best)
        result = community_guided_sat_solve(test_file, use_v2_algorithm=true, verbose=true)
        
        if result !== nothing
            # Check if traditional SAT result is available
            traditional_satisfiable = false
            if result.traditional_sat_result !== nothing
                traditional_satisfiable = result.traditional_sat_result.satisfiable
            end
            
            println("\n🔍 OPTIMIZATION TEST RESULTS:")
            println("   Community-guided: $(result.satisfiable)")
            println("   Traditional SAT: $(traditional_satisfiable)")
            println("   Communities: $(length(result.communities))")
            println("   Modularity: $(round(result.modularity_score, digits=3))")
            println("   Solve time: $(round(result.solve_time, digits=3))s")
            
            if result.satisfiable && traditional_satisfiable
                println("   ✅ Both SAT - Agreement!")
            elseif !result.satisfiable && !traditional_satisfiable
                println("   ✅ Both UNSAT - Agreement!")
            else
                println("   ❌ Disagreement - Community-guided: $(result.satisfiable), Traditional: $(traditional_satisfiable)")
            end
        else
            println("  ❌ Failed to solve")
        end
    catch e
        println("  ❌ Error: $e")
        @show e
    end
else
    println("❌ Test file not found: $test_file")
end

println("\n" * "=" ^ 60)
println("Node processing order changed to: Lowest-to-Highest Weight")
println("This should theoretically help by processing less constrained nodes first")
