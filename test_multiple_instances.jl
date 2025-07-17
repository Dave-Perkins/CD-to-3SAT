#!/usr/bin/env julia
# Test multiple SAT instances with our community-guided solver

println("🎯 Community-Guided SAT Solver - Multi-Instance Test")
println("="^60)

include("src/community_sat_solver_clean.jl")

# Test cases with their expected outcomes
test_cases = [
    ("research/research_3vars_5clauses_seed42.md", "research/research_3vars_5clauses_seed42.txt"),
    ("research/research_3vars_6clauses_seed123.md", "research/research_3vars_6clauses_seed123.txt"),
    ("research/research_3vars_7clauses_seed777.md", "research/research_3vars_7clauses_seed777.txt"),
    ("research/research_4vars_8clauses_seed888.md", "research/research_4vars_8clauses_seed888.txt"),
    ("research/research_4vars_10clauses_seed456.md", "research/research_4vars_10clauses_seed456.txt")
]

results = []
global successful_cases = 0
global total_cases = 0

for (md_file, graph_file) in test_cases
    if isfile(md_file) && isfile(graph_file)
        global total_cases += 1
        println("\n" * "="^60)
        println("🔍 Testing: $(basename(md_file))")
        println("="^60)
        
        try
            assignment, satisfied = test_community_sat_solver(md_file, graph_file, verbose=false)
            
            if satisfied
                println("✅ SUCCESS: Found satisfying assignment!")
                global successful_cases += 1
                push!(results, (basename(md_file), "✅ SOLVED", assignment))
            else
                println("❌ FAILED: No satisfying assignment found")
                push!(results, (basename(md_file), "❌ UNSOLVED", assignment))
            end
            
        catch e
            println("💥 ERROR: $e")
            push!(results, (basename(md_file), "💥 ERROR", nothing))
        end
    else
        println("⚠️ Skipping $(basename(md_file)) - files not found")
    end
end

# Summary report
println("\n" * "🏆" * "="^58 * "🏆")
println("📊 SUMMARY REPORT")
println("🏆" * "="^58 * "🏆")
println("📈 Success Rate: $successful_cases / $total_cases ($(round(100 * successful_cases / total_cases, digits=1))%)")
println()

for (file, status, assignment) in results
    println("  $status $file")
    if assignment !== nothing && status == "✅ SOLVED"
        vars = sort(collect(keys(assignment)))
        assignment_str = join(["$var=$(assignment[var] ? 1 : 0)" for var in vars], ", ")
        println("    📋 Assignment: $assignment_str")
    end
end

println("\n🎯 Algorithm Performance:")
if successful_cases == total_cases
    println("   🌟 Perfect! The community-guided approach solved all test cases!")
    println("   🧠 This suggests our implementation correctly follows the pseudocode")
elseif successful_cases > total_cases / 2
    println("   👍 Good! The algorithm solved most cases")
    println("   🔬 Some instances may be naturally harder or unsatisfiable")
else
    println("   🤔 Mixed results. The algorithm may need refinement")
    println("   💡 Consider improving the community detection or heuristics")
end

println("\n📝 Note: This demonstrates our implementation of the community-guided")
println("   3-SAT solving algorithm from the research pseudocode!")
