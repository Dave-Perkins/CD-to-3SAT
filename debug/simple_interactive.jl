#!/usr/bin/env julia

# Simple Interactive Graph Launcher
# Just runs the graph and exits

println("📊 SIMPLE INTERACTIVE GRAPH LAUNCHER")

if length(ARGS) == 0
    println("Usage: julia simple_interactive.jl <filename>")
    exit(1)
end

filename = ARGS[1]
if !isfile(filename)
    println("❌ File not found: $filename")
    exit(1)
end

println("🚀 Loading interactive workflow...")
include("mini03.jl")

println("🚀 Processing $filename...")
try
    # Just run the simple version instead of the interactive one
    run_graph(filename)
    println("✅ Done!")
catch e
    println("❌ Error: $e")
end
