#!/usr/bin/env julia
# Test the improved community-guided SAT solver

include("src/community_sat_solver_clean.jl")

println("🚀 Testing IMPROVED Community-Guided SAT Solver")
println("   Now using community CONTRIBUTIONS to overall modularity!")
println("="^70)

# Test with multiple instances
test_cases = [
    ("research/research_3vars_5clauses_seed42.md", "research/research_3vars_5clauses_seed42.txt", "Easy instance"),
    ("research/research_3vars_7clauses_seed777.md", "research/research_3vars_7clauses_seed777.txt", "Harder instance"),
    ("test_positive_modularity.md", "test_extreme_modularity.txt", "Custom instance")
]

for (md_file, graph_file, description) in test_cases
    if isfile(md_file) && isfile(graph_file)
        println("\n" * "🔍" * "="^60 * "🔍")
        println("Testing: $description")
        println("Files: $(basename(md_file)) & $(basename(graph_file))")
        println("🔍" * "="^60 * "🔍")
        
        try
            assignment, satisfied = test_community_sat_solver(md_file, graph_file, verbose=true)
            
            println("\n🎯 RESULT:")
            if satisfied
                println("   ✅ SUCCESS with improved algorithm!")
                vars = sort(collect(keys(assignment)))
                assignment_str = join(["$var=$(assignment[var] ? 1 : 0)" for var in vars], ", ")
                println("   📋 Assignment: $assignment_str")
            else
                println("   ❌ Failed with improved algorithm")
                println("   💭 The instance may be unsatisfiable or require different heuristics")
            end
            
        catch e
            println("💥 Error: $e")
        end
    else
        println("\n⚠️ Skipping $description - files not found")
    end
end

println("\n" * "🎉" * "="^60 * "🎉")
println("IMPROVED ALGORITHM SUMMARY")
println("🎉" * "="^60 * "🎉")
println("✅ Now calculates OVERALL graph modularity")
println("✅ Sorts communities by their CONTRIBUTION to overall modularity")
println("✅ Processes highest contributing communities first")
println("📚 This follows the corrected pseudocode approach!")
println("🔬 Much more principled than scoring communities in isolation")
