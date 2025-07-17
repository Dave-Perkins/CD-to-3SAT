#!/usr/bin/env julia

include("src/community_sat_solver_clean.jl")

println("🧪 Testing SAT Solver with Fixed Modularity")
println("=" ^ 60)

# Simple test case
formula = "(¬1 ∨ 2 ∨ 3) ∧ (1 ∨ ¬2 ∨ 4) ∧ (¬3 ∨ ¬4 ∨ 1)"

println("📝 Test formula: $formula")
println()

try
    result = community_sat_solve(formula, max_iterations=50, verbose=true, flip_probability=0.1)

    if result !== nothing
        assignment, final_modularity = result
        println()
        println("✅ Solution found!")
        println("   Assignment: $assignment")
        println("   Final modularity: $(round(final_modularity, digits=4))")
        
        if final_modularity >= -0.5 && final_modularity <= 1.0
            println("   ✅ Modularity within expected bounds [-0.5, 1.0]!")
        else
            println("   ❌ Modularity still out of bounds")
        end
    else
        println("❌ No solution found")
    end
catch e
    println("❌ Error during execution: $e")
end
