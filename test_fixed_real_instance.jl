#!/usr/bin/env julia

include("src/community_sat_solver_clean.jl")

println("🧪 Testing SAT Solver with Fixed Modularity - Real Instance")
println("=" ^ 70)

# Test with a real instance that we know works
md_file = "research/research_3vars_5clauses_seed42.md"
graph_file = "research/research_3vars_5clauses_seed42.txt"

if isfile(md_file) && isfile(graph_file)
    println("📝 Testing with: $(basename(md_file))")
    println()
    
    try
        # Use the existing test wrapper function
        assignment, satisfied = test_community_sat_solver(md_file, graph_file, verbose=true)
        
        println()
        println("🎯 RESULT:")
        if satisfied
            println("   ✅ SUCCESS! SAT solver working with fixed modularity!")
            vars = sort(collect(keys(assignment)))
            println("   📊 Assignment: $([(v, assignment[v]) for v in vars])")
        else
            println("   ❌ Failed to find satisfying assignment")
        end
        
    catch e
        println("❌ Error during execution: $e")
        println("   Stack trace:")
        for (exc, bt) in Base.catch_stack()
            showerror(stdout, exc, bt)
            println()
        end
    end
else
    println("❌ Test files not found:")
    println("   MD file exists: $(isfile(md_file))")
    println("   Graph file exists: $(isfile(graph_file))")
end
