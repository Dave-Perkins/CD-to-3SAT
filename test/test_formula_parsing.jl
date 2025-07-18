#!/usr/bin/env julia
# Test the formula parsing functionality

println("🧪 Formula Parsing Test")
println("="^30)

# Include the functions
include("src/community_sat_solver.jl")

# Test with a real file
markdown_file = "research/research_3vars_5clauses_seed42.md"

if isfile(markdown_file)
    println("📄 Testing file: $markdown_file")
    
    try
        formula = parse_formula_from_markdown(markdown_file)
        println("✅ Parsed successfully!")
        println("   Variables: $(formula.num_variables)")
        println("   Clauses: $(length(formula.clauses))")
        
        for (i, clause) in enumerate(formula.clauses)
            println("   Clause $i: $clause")
        end
        
    catch e
        println("❌ Error: $e")
        println("Stacktrace:")
        for frame in stacktrace(catch_backtrace())
            println("  $frame")
        end
    end
else
    println("❌ File not found: $markdown_file")
end
