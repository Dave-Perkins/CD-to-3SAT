#!/usr/bin/env julia
# Run verbose test on a specific SAT instance

include("src/community_sat_solver_clean.jl")

# You can change these file paths to test any instance
markdown_file = "test_positive_modularity.md"
graph_file = "test_positive_modularity.txt"

println("🔍 Running Verbose Test on: $(basename(markdown_file))")
println("="^60)

if isfile(markdown_file) && isfile(graph_file)
    try
        assignment, satisfied = test_community_sat_solver(markdown_file, graph_file, verbose=true)
        
        println("\n🎯 DETAILED ANALYSIS:")
        if satisfied
            println("   ✅ SUCCESS: Found satisfying assignment!")
            vars = sort(collect(keys(assignment)))
            assignment_str = join(["$var=$(assignment[var] ? 1 : 0)" for var in vars], ", ")
            println("   📋 Final Assignment: $assignment_str")
        else
            println("   ❌ FAILED: No satisfying assignment found")
            println("   💡 This could mean:")
            println("     - The instance is unsatisfiable")
            println("     - Our heuristic didn't find the right path")
            println("     - Need better community detection")
        end
        
    catch e
        println("💥 Error: $e")
        for frame in stacktrace(catch_backtrace())
            println("  $frame")
        end
    end
else
    println("❌ Files not found:")
    println("   📄 Formula: $markdown_file ($(isfile(markdown_file) ? "✅" : "❌"))")
    println("   📊 Graph: $graph_file ($(isfile(graph_file) ? "✅" : "❌"))")
    
    # Show available files
    println("\n📁 Available test files:")
    for file in readdir("research")
        if endswith(file, ".md")
            corresponding_txt = replace(file, ".md" => ".txt")
            status = isfile("research/$corresponding_txt") ? "✅" : "❌"
            println("   $status research/$file")
        end
    end
end
