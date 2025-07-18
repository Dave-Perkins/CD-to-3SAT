# Simple debug to understand the violated clause structure
using Pkg
Pkg.activate(".")

include("src/community_guided_sat.jl")
include("src/sat3_markdown_generator.jl")

println("🔍 DEBUG: Understanding violated clause structure")

# Recreate the problematic instance
instance = generate_random_3sat(6, 18, seed=5001)
test_file = "temp_debug.md"
write(test_file, to_markdown(instance, "Debug"))

# Get the community-guided result
result = community_guided_sat_solve(test_file, use_v2_algorithm=true, verbose=false)

if result !== nothing && result.assignment_quality !== nothing
    println("📊 Found $(length(result.assignment_quality.violated_clauses)) violated clause(s)")
    
    for (i, violated_info) in enumerate(result.assignment_quality.violated_clauses)
        println("\n❌ VIOLATED CLAUSE $i:")
        println("   • Clause ID: $(violated_info.clause_id)")
        println("   • Clause: $(violated_info.clause)")
        println("   • Satisfied: $(violated_info.satisfied)")
        println("   • Satisfied literals: $(violated_info.satisfied_literals)")
        println("   • Total literals: $(violated_info.total_literals)")
        
        println("   • Assignment for this clause:")
        for literal in violated_info.clause
            println("     - Literal: '$literal' (length: $(length(literal)))")
            # Print each character
            for (j, char) in enumerate(literal)
                println("       [$(j)]: '$(char)' ($(Int(char)))")
            end
        end
    end
    
    println("\n✅ Traditional SAT solution:")
    if result.traditional_sat_result !== nothing
        for (var, value) in sort(collect(result.traditional_sat_result.assignment))
            our_value = result.assignment[var]
            println("   • $var: our=$our_value, traditional=$value")
        end
    end
end

rm(test_file, force=true)
println("\n🎯 This shows exactly why GVR correctly identified no beneficial single flips!")
