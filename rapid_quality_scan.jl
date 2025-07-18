# Quick diagnostic test to see more examples of how close we get
using Pkg
Pkg.activate(".")

include("src/community_guided_sat.jl")
include("src/sat3_markdown_generator.jl")

println("🔍 RAPID ASSIGNMENT QUALITY SCAN")
println("=" ^ 50)

disagreements = 0
close_misses = 0
total_tests = 0

# Test several instances quickly
for i in 1:8
    local instance = generate_random_3sat(5, 15, seed=3000+i)
    test_file = "temp_scan_$i.md"
    
    try
        write(test_file, to_markdown(instance, "Scan $i"))
        result = community_guided_sat_solve(test_file, use_v2_algorithm=true, verbose=false)
        
        if result !== nothing && result.traditional_sat_result !== nothing
            total_tests += 1
            our_result = result.satisfiable
            traditional_result = result.traditional_sat_result.satisfiable
            
            if our_result != traditional_result
                disagreements += 1
                if result.assignment_quality !== nothing
                    satisfaction_rate = result.assignment_quality.satisfaction_rate * 100
                    print("Test $i: $(round(satisfaction_rate, digits=0))% satisfaction ")
                    
                    if satisfaction_rate >= 80
                        close_misses += 1
                        print("🔥 CLOSE! ")
                    elseif satisfaction_rate >= 60
                        print("🎯 PARTIAL ")
                    else
                        print("📉 LOW ")
                    end
                    
                    violated = length(result.assignment_quality.violated_clauses)
                    total_clauses = result.assignment_quality.total_clauses
                    print("($violated/$total_clauses violated)")
                    println()
                end
            else
                print("Test $i: ✅ Agreement ")
                println()
            end
        end
        
        rm(test_file, force=true)
    catch e
        print("Test $i: ❌ Error ")
        rm(test_file, force=true)
        println()
    end
end

println("=" ^ 50)
println("📊 RAPID SCAN RESULTS:")
println("Total tests: $total_tests")
println("Disagreements: $disagreements")
println("Close misses (≥80%): $close_misses")

if disagreements > 0
    agreement_rate = ((total_tests - disagreements) / total_tests) * 100
    close_miss_rate = (close_misses / disagreements) * 100
    
    println("Agreement rate: $(round(agreement_rate, digits=1))%")
    println("Close miss rate: $(round(close_miss_rate, digits=1))% of disagreements")
    
    if close_miss_rate >= 50
        println("\n💡 KEY FINDING:")
        println("Our approach gets very close (≥80% clauses) in $(round(close_miss_rate, digits=0))% of disagreements!")
        println("This suggests variable flipping heuristics could significantly improve accuracy.")
    end
else
    println("Perfect agreement in this scan!")
end
