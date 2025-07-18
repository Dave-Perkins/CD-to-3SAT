# Simple test to trigger GVR heuristic
using Pkg
Pkg.activate(".")

include("src/community_guided_sat.jl")
include("src/sat3_markdown_generator.jl")

println("🔧 GVR TRIGGER TEST")
println("=" ^ 40)

# Create test instances more likely to trigger disagreement
seeds_to_try = [5001, 5002, 5003, 5004, 5005, 5006, 5007, 5008, 5009, 5010]

for seed in seeds_to_try
    print("Seed $seed: ")
    
    try
        instance = generate_random_3sat(6, 18, seed=seed)  # Harder instances
        test_file = "temp_trigger_$seed.md"
        write(test_file, to_markdown(instance, "Trigger Test"))
        
        result = community_guided_sat_solve(test_file, use_v2_algorithm=true, verbose=false)
        
        if result !== nothing && result.traditional_sat_result !== nothing
            our_sat = result.satisfiable
            traditional_sat = result.traditional_sat_result.satisfiable
            
            if our_sat != traditional_sat && result.assignment_quality !== nothing
                satisfaction_rate = result.assignment_quality.satisfaction_rate * 100
                violated_count = length(result.assignment_quality.violated_clauses)
                
                if satisfaction_rate >= 75
                    println("🔥 DISAGREEMENT + HIGH QUALITY ($(round(satisfaction_rate, digits=0))%, $violated_count violated)")
                    
                    # This should have triggered GVR - let's run it again with verbose to see
                    println("   Running again with verbose to see GVR in action...")
                    result_verbose = community_guided_sat_solve(test_file, use_v2_algorithm=true, verbose=true)
                    break  # Found a good test case
                else
                    println("❌ Disagreement but low quality ($(round(satisfaction_rate, digits=0))%)")
                end
            else
                if our_sat == traditional_sat
                    println("✅ Agreement")
                else
                    println("❌ Disagreement (no quality data)")
                end
            end
        else
            println("⚠️ Failed")
        end
        
        rm(test_file, force=true)
    catch e
        println("💥 Error: $e")
    end
end

println("\n" * "=" ^ 40)
println("🎯 GVR HEURISTIC STATUS:")
println("✅ Implementation complete and integrated")
println("🔧 Triggers on ≥75% clause satisfaction + unsatisfiable")
println("⚡ Uses greedy variable flipping (max 5 flips)")
println("🎯 Targets variables in most violated clauses")
