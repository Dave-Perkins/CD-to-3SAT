# Test the new Greedy Violation Repair (GVR) heuristic
using Pkg
Pkg.activate(".")

include("src/community_guided_sat.jl")
include("src/sat3_markdown_generator.jl")

println("🔧 GREEDY VIOLATION REPAIR HEURISTIC TEST")
println("=" ^ 60)
println("Testing variable flipping to repair violated clauses")
println()

# Test cases designed to trigger disagreements
test_cases = [
    (vars=5, clauses=12, seed=4001, name="Medium Challenge"),
    (vars=6, clauses=18, seed=4002, name="Hard Challenge"),
    (vars=4, clauses=10, seed=4003, name="Easy Challenge"),
    (vars=7, clauses=21, seed=4004, name="Very Hard Challenge")
]

repair_successes = 0
total_disagreements = 0
total_tests = 0
improvement_cases = 0

for (i, case) in enumerate(test_cases)
    println("🧪 Test $i: $(case.name) ($(case.vars) vars, $(case.clauses) clauses)")
    
    # Generate test instance
    local instance = generate_random_3sat(case.vars, case.clauses, seed=case.seed)
    test_file = "temp_gvr_$i.md"
    
    try
        # Save instance to markdown
        markdown_content = to_markdown(instance, case.name)
        write(test_file, markdown_content)
        
        # Test our solver WITH repair heuristic (verbose to see repair in action)
        println("   Running community-guided solver with GVR...")
        result = community_guided_sat_solve(test_file, use_v2_algorithm=true, verbose=true)
        
        if result !== nothing && result.traditional_sat_result !== nothing
            global total_tests += 1
            our_result = result.satisfiable
            traditional_result = result.traditional_sat_result.satisfiable
            
            println("\n   📊 FINAL RESULTS:")
            println("     Community-guided + GVR: $our_result")
            println("     Traditional SAT: $traditional_result")
            
            if our_result != traditional_result
                global total_disagreements += 1
                println("     ❌ Still disagrees with traditional SAT")
                
                if result.assignment_quality !== nothing
                    satisfaction_rate = result.assignment_quality.satisfaction_rate * 100
                    println("     📈 Final satisfaction: $(round(satisfaction_rate, digits=1))%")
                end
            else
                if result.assignment_quality !== nothing && result.assignment_quality.satisfaction_rate < 1.0
                    # This means GVR likely helped achieve agreement
                    global repair_successes += 1
                    println("     ✅ Agreement achieved! (GVR likely helped)")
                else
                    println("     ✅ Agreement (may not have needed GVR)")
                end
            end
            
            # Check for improvements even in disagreement cases
            if result.assignment_quality !== nothing
                satisfaction_rate = result.assignment_quality.satisfaction_rate
                if satisfaction_rate >= 0.85  # Very close
                    global improvement_cases += 1
                end
            end
        else
            println("   ❌ Failed to solve")
        end
        
        # Clean up
        rm(test_file, force=true)
        println("\n" * repeat("=", 25))
        
    catch e
        println("   ❌ Error: $e")
        rm(test_file, force=true)
        println("\n" * repeat("=", 25))
    end
end

println("\n" * "=" ^ 60)
println("🎯 GREEDY VIOLATION REPAIR (GVR) RESULTS:")
println("=" ^ 60)
println("Total tests completed: $total_tests")
println("Disagreements with traditional SAT: $total_disagreements")
println("Repair successes (likely GVR helped): $repair_successes")
println("High-quality results (≥85% satisfaction): $improvement_cases")

if total_tests > 0
    agreement_rate = ((total_tests - total_disagreements) / total_tests) * 100
    println("Overall agreement rate: $(round(agreement_rate, digits=1))%")
    
    if repair_successes > 0
        println("\n💡 GVR IMPACT:")
        println("• Repair heuristic likely helped in $repair_successes cases")
        println("• GVR shows promise for bridging the gap to satisfying solutions")
    end
    
    if improvement_cases > 0
        println("\n🎯 QUALITY ANALYSIS:")
        println("• $improvement_cases cases achieved ≥85% clause satisfaction")
        println("• This suggests strong foundational solving with fine-tuning potential")
    end
    
    if total_disagreements > 0
        remaining_gap = (total_disagreements / total_tests) * 100
        println("\n🔬 REMAINING CHALLENGES:")
        println("• $(round(remaining_gap, digits=1))% disagreement rate suggests room for:")
        println("  - More sophisticated repair strategies")
        println("  - Alternative assignment methods for hard cases")
        println("  - Hybrid approaches combining multiple techniques")
    end
else
    println("No tests completed successfully")
end
