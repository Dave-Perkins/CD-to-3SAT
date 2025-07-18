# Test the impact of changing node sorting from highest-to-lowest to lowest-to-highest
using Pkg
Pkg.activate(".")

include("src/community_guided_sat.jl")

# Test on a few instances to see the impact
test_instances = [
    "test/test_data/test_positive_modularity.md",
    "docs/positive_modularity_instance.md",
    "test_output/test_instance.md"
]

println("Testing Node Sorting Optimization:")
println("Changed from highest-to-lowest to lowest-to-highest weight processing")
println("=" ^ 60)

global total_tests = 0
global total_agreements = 0

for instance_file in test_instances
    if isfile(instance_file)
        println("\nTesting: $instance_file")
        
        try
            # Run with v2 algorithm (current best)
            result = community_guided_sat_solve(instance_file, use_v2_algorithm=true, verbose=false)
            
            if result !== nothing
                global total_tests += 1
                if result.satisfiable && result.ground_truth_satisfiable
                    global total_agreements += 1
                    println("  ✓ Agreement: Both SAT")
                elseif !result.satisfiable && !result.ground_truth_satisfiable
                    global total_agreements += 1
                    println("  ✓ Agreement: Both UNSAT")
                elseif result.satisfiable && !result.ground_truth_satisfiable
                    println("  ✗ Disagreement: Solver SAT, Truth UNSAT")
                else
                    println("  ✗ Disagreement: Solver UNSAT, Truth SAT")
                end
                
                println("    Communities: $(result.num_communities)")
                println("    Modularity: $(round(result.modularity, digits=3))")
                println("    Solve time: $(round(result.solve_time, digits=3))s")
            else
                println("  Failed to solve")
            end
        catch e
            println("  Error: $e")
        end
    else
        println("File not found: $instance_file")
    end
end

if total_tests > 0
    agreement_rate = (total_agreements / total_tests) * 100
    println("\n" * "=" ^ 60)
    println("OPTIMIZATION RESULTS:")
    println("Agreement Rate: $(round(agreement_rate, digits=1))% ($total_agreements/$total_tests)")
    println("Node Processing Order: Lowest-to-Highest Weight")
    println("\nPrevious baseline with v2 algorithm: ~27% agreement")
    
    if agreement_rate > 27
        println("🎉 IMPROVEMENT! (+$(round(agreement_rate - 27, digits=1))%)")
    elseif agreement_rate < 27
        println("📉 Regression (-$(round(27 - agreement_rate, digits=1))%)")
    else
        println("➡️  No significant change")
    end
else
    println("No valid tests completed")
end
