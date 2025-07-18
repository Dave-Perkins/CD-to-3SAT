#!/usr/bin/env julia
# Interactive verbose tester - easily change which instance to test

include("src/community_sat_solver_clean.jl")

# 🔧 CHANGE THESE LINES TO TEST DIFFERENT INSTANCES:
markdown_file = "research/research_4vars_8clauses_seed888.md"  # ← Edit this
graph_file = "research/research_4vars_8clauses_seed888.txt"     # ← Edit this

# Available options (copy-paste the names above):
# research/research_3vars_5clauses_seed42.md  ✅ (this one works)
# research/research_3vars_7clauses_seed777.md ❌ (fails on clause 2)
# research/research_4vars_8clauses_seed888.md ❌ (fails)

println("🔍 VERBOSE TEST: $(basename(markdown_file))")
println("="^60)

if isfile(markdown_file) && isfile(graph_file)
    assignment, satisfied = test_community_sat_solver(markdown_file, graph_file, verbose=true)
    
    println("\n" * "🎯" * "="^58 * "🎯")
    println("FINAL ANALYSIS")
    println("🎯" * "="^58 * "🎯")
    
    if satisfied
        println("✅ SUCCESS!")
        vars = sort(collect(keys(assignment)))
        println("📋 Assignment: $(join(["$var=$(assignment[var] ? 1 : 0)" for var in vars], ", "))")
    else
        println("❌ FAILED!")
        println("🤔 The community-guided heuristic couldn't solve this instance")
        println("💡 This demonstrates the algorithm's limitations with certain formulas")
    end
else
    println("❌ Files not found! Update the file paths at the top of this script.")
end
