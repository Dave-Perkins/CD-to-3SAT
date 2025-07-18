#!/usr/bin/env julia
# Simple test for parsing functionality only

println("🧪 Simple Parse Test")
println("="^30)

# Include the function directly
include("src/community_sat_solver.jl")

# Test parsing a simple line
test_line = "1. (x2 ∨ ¬x2 ∨ ¬x3)"
println("Testing line: $test_line")

try
    result = parse_clause_from_line(test_line)
    println("✅ Parsed successfully: $result")
catch e
    println("❌ Error: $e")
    # Let's try to understand what's happening
    println("Available functions in module:")
    for name in names(@__MODULE__, all=true)
        if startswith(string(name), "parse")
            println("  - $name")
        end
    end
end
