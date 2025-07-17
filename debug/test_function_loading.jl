#!/usr/bin/env julia

# Test script to isolate the MethodError issue

using Pkg
using Printf

println("🧪 Testing function loading...")

# Test 1: Load packages first
println("📦 Step 1: Loading CairoMakie and Colors...")
try
    using CairoMakie
    using Colors
    println("✅ Packages loaded successfully")
catch e
    println("❌ Failed to load packages: $e")
    exit(1)
end

# Test 2: Include the stable workflow
println("📄 Step 2: Including mini03_stable.jl...")
try
    include("mini03_stable.jl")
    println("✅ File included successfully")
catch e
    println("❌ Failed to include file: $e")
    exit(1)
end

# Test 3: Check function availability
println("🔍 Step 3: Checking function availability...")
println("isdefined(Main, :run_stable_workflow): ", isdefined(Main, :run_stable_workflow))

# Test 4: Try to call the function
println("🚀 Step 4: Testing function call...")
try
    run_stable_workflow("graph_input.txt")
    println("✅ Function call successful!")
catch e
    println("❌ Function call failed: $e")
    println("Type of error: ", typeof(e))
end
