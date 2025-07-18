# Test assignment quality diagnostics
using Pkg
Pkg.activate(".")

include("src/community_guided_sat.jl")
include("src/sat3_markdown_generator.jl")

println("🔍 ASSIGNMENT QUALITY DIAGNOSTIC TEST")
println("=" ^ 60)
println("Testing how close our community-guided approach comes to")
println("satisfying instances, especially when disagreeing with traditional SAT")
println()

# Generate some test instances of varying difficulty
test_cases = [
    (vars=4, clauses=6, seed=1001, name="Easy Instance"),
    (vars=5, clauses=12, seed=1002, name="Medium Instance"), 
    (vars=6, clauses=18, seed=1003, name="Hard Instance")
]

total_close_misses = 0
total_disagreements = 0

for (i, case) in enumerate(test_cases)
    println("🧪 Test $i: $(case.name) ($(case.vars) vars, $(case.clauses) clauses)")
    
    # Generate test instance
    local instance = generate_random_3sat(case.vars, case.clauses, seed=case.seed)
    test_file = "temp_diagnostic_$i.md"
    
    try
        # Save instance to markdown
        markdown_content = to_markdown(instance, case.name)
        write(test_file, markdown_content)
        
        # Test our solver with verbose output
        println("   Running community-guided solver...")
        result = community_guided_sat_solve(test_file, use_v2_algorithm=true, verbose=false)
        
        if result !== nothing
            println("   📊 RESULTS:")
            println("     Community-guided: $(result.satisfiable)")
            
            if result.traditional_sat_result !== nothing
                traditional_sat = result.traditional_sat_result.satisfiable
                println("     Traditional SAT: $(traditional_sat)")
                
                # Check for disagreement
                if result.satisfiable != traditional_sat
                    global total_disagreements += 1
                    println("     ❌ DISAGREEMENT DETECTED!")
                    
                    if result.assignment_quality !== nothing
                        quality = result.assignment_quality
                        satisfaction_rate = quality.satisfaction_rate * 100
                        
                        println("     📈 Assignment Quality Analysis:")
                        println("       • Clause satisfaction: $(round(satisfaction_rate, digits=1))%")
                        println("       • Satisfied clauses: $(quality.satisfied_clauses)/$(quality.total_clauses)")
                        
                        if satisfaction_rate >= 80
                            global total_close_misses += 1
                            println("       🔥 VERY CLOSE TO SOLUTION! (≥80% clauses satisfied)")
                            println("       💡 Consider variable flipping heuristics")
                            
                            # Show violated clauses
                            if !isempty(quality.violated_clauses)
                                println("       ❌ Violated clauses:")
                                for clause_info in quality.violated_clauses[1:min(3, end)]
                                    println("         Clause $(clause_info.clause_id): $(join(clause_info.clause, " ∨ "))")
                                end
                                if length(quality.violated_clauses) > 3
                                    println("         ... and $(length(quality.violated_clauses) - 3) more")
                                end
                            end
                            
                        elseif satisfaction_rate >= 50
                            println("       🎯 PARTIAL SUCCESS (≥50% clauses satisfied)")
                        else
                            println("       📉 Low satisfaction rate")
                        end
                    end
                else
                    println("     ✅ Agreement with traditional SAT solver")
                end
            else
                println("     ⚠️  No traditional SAT result available")
            end
            
            println("     Communities: $(length(result.communities))")
            println("     Modularity: $(round(result.modularity_score, digits=3))")
            println("     Solve time: $(round(result.solve_time, digits=3))s")
        else
            println("   ❌ Failed to solve")
        end
        
        # Clean up
        rm(test_file, force=true)
        println()
        
    catch e
        println("   ❌ Error: $e")
        rm(test_file, force=true)
        println()
    end
end

println("=" ^ 60)
println("🎯 DIAGNOSTIC SUMMARY:")
println("Total disagreements with traditional SAT: $total_disagreements")
println("Close misses (≥80% clause satisfaction): $total_close_misses")

if total_close_misses > 0 && total_disagreements > 0
    close_miss_rate = (total_close_misses / total_disagreements) * 100
    println("Close miss rate: $(round(close_miss_rate, digits=1))% of disagreements")
    println()
    println("💡 INSIGHTS:")
    println("• Our community-guided approach often gets very close to solutions")
    println("• Variable flipping heuristics could potentially improve accuracy")
    println("• The community structure provides a good foundation, but assignment")
    println("  strategy may need refinement for the final satisfying assignment")
elseif total_disagreements == 0
    println("• Perfect agreement with traditional SAT solver in this test!")
else
    println("• Community-guided approach struggles with these instances")
    println("• May need algorithmic improvements beyond variable flipping")
end
