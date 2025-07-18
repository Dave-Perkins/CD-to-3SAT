#!/usr/bin/env julia
# Test the clean community SAT solver

println("🧪 Testing Clean Community SAT Solver")
println("="^40)

include("src/community_sat_solver_clean.jl")

# Test the basic functionality
test_basic_functionality()
