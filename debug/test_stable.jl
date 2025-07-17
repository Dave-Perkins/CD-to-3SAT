#!/usr/bin/env julia

# Quick test of the stable workflow
# This should work without any graphics hangs

println("🧪 TESTING STABLE WORKFLOW")
println("="^50)

# Test if CairoMakie is available
try
    using CairoMakie
    println("✅ CairoMakie is available")
catch e
    println("❌ CairoMakie not available: $e")
    println("📦 Installing CairoMakie...")
    using Pkg
    Pkg.add("CairoMakie")
    using CairoMakie
    println("✅ CairoMakie installed and loaded")
end

# Include the stable version
include("mini03_stable.jl")

# Test graphs in order of complexity
test_graphs = [
    "graphs/graph03.txt",      # Simple test
    "graphs/graph05.txt",      # Triangle + Square
    "graphs/graph09.txt",      # Weighted communities
    "graphs/graph10.txt"       # Complete graph
]

println("\n🚀 Testing graphs...")
println("="^50)

for graph_file in test_graphs
    if isfile(graph_file)
        println("🔍 Testing: $graph_file")
        try
            result = process_graph(graph_file)
            if result[1] !== nothing
                modularity, communities, output_file = result
                println("   ✅ Success! Modularity: $(round(modularity, digits=4))")
                println("   📁 Output: $output_file")
            else
                println("   ❌ Failed")
            end
        catch e
            println("   💥 Error: $e")
        end
        println()
    else
        println("⚠️  Skipping $graph_file (not found)")
    end
end

println("🎉 Testing complete!")
println("💡 If you see PNG files created, the stable workflow is working!")
println("📁 Open the PNG files to view the visualizations")
println("="^50)
