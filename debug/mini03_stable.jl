#!/usr/bin/env julia

# Stable version of mini03.jl using CairoMakie instead of GLMakie
# This version avoids the "Evaluating" hang issue by using file-based output

using Printf

# Include the scoring function
include("scoring_stable.jl")

# Include the stable plotting function
include("plot_graph_stable.jl")

function read_edges(filename::String)
    """Read edges from file, supporting both weighted and unweighted formats."""
    edges = []
    edge_weights = Dict()
    
    if !isfile(filename)
        error("File not found: $filename")
    end
    
    open(filename, "r") do file
        for line in eachline(file)
            line = strip(line)
            if isempty(line) || startswith(line, "#")
                continue
            end
            
            parts = split(line)
            if length(parts) >= 2
                # Convert to integers for node IDs
                node1 = parse(Int, parts[1])
                node2 = parse(Int, parts[2])
                
                # Get weight (default to 1.0 if not specified)
                weight = length(parts) >= 3 ? parse(Float64, parts[3]) : 1.0
                
                push!(edges, (node1, node2))
                edge_weights[(node1, node2)] = weight
                edge_weights[(node2, node1)] = weight  # Undirected graph
            end
        end
    end
    
    return edges, edge_weights
end

function build_graph(edges)
    """Build adjacency list from edge list."""
    # Find all unique nodes
    nodes = Set{Int}()
    for (n1, n2) in edges
        push!(nodes, n1)
        push!(nodes, n2)
    end
    
    # Build adjacency list
    adj_list = Dict{Int, Vector{Int}}()
    for node in nodes
        adj_list[node] = Int[]
    end
    
    for (n1, n2) in edges
        push!(adj_list[n1], n2)
        push!(adj_list[n2], n1)
    end
    
    return adj_list, collect(nodes)
end

function simple_community_detection(adj_list, nodes)
    """Simple community detection using connected components and modularity optimization."""
    visited = Set{Int}()
    communities = Vector{Vector{Int}}()
    
    function dfs(node, current_community)
        if node in visited
            return
        end
        
        push!(visited, node)
        push!(current_community, node)
        
        for neighbor in adj_list[node]
            dfs(neighbor, current_community)
        end
    end
    
    # First pass: Find connected components
    for node in nodes
        if !(node in visited)
            community = Int[]
            dfs(node, community)
            push!(communities, sort(community))
        end
    end
    
    # If there's only one large connected component, try to split it
    # This is a very simple heuristic - in practice you'd use more sophisticated methods
    if length(communities) == 1 && length(communities[1]) > 4
        large_community = communities[1]
        
        # Try to split into roughly equal parts based on node IDs
        # (This is a naive approach, but works for demonstration)
        mid_point = div(length(large_community), 2)
        
        # Sort by node degree (more connections = higher degree)
        node_degrees = [(node, length(adj_list[node])) for node in large_community]
        sort!(node_degrees, by = x -> x[2], rev = true)
        
        # Split based on degree - put high-degree nodes in different communities
        comm1 = Int[]
        comm2 = Int[]
        
        for (i, (node, degree)) in enumerate(node_degrees)
            if i % 2 == 1
                push!(comm1, node)
            else
                push!(comm2, node)
            end
        end
        
        if !isempty(comm1) && !isempty(comm2)
            communities = [sort(comm1), sort(comm2)]
        end
    end
    
    return communities
end

function process_graph(filename::String, output_prefix::String="")
    """
    Process a graph file and create visualization.
    Uses stable CairoMakie backend that saves to PNG files.
    """
    
    println("🚀 Processing graph: $filename")
    println("="^50)
    
    try
        # Read the graph
        println("📖 Reading graph from file...")
        edges, edge_weights = read_edges(filename)
        adj_list, nodes = build_graph(edges)
        
        println("✅ Graph loaded successfully!")
        println("   📊 Nodes: $(length(nodes))")
        println("   🔗 Edges: $(length(edges))")
        println("   ⚖️  Weighted: $(any(w != 1.0 for w in values(edge_weights)))")
        
        # Detect communities
        println("🔍 Detecting communities...")
        communities = simple_community_detection(adj_list, nodes)
        
        println("✅ Communities detected:")
        for (i, community) in enumerate(communities)
            println("   Community $i: $(join(community, ", "))")
        end
        
        # Calculate modularity
        println("🧮 Calculating modularity score...")
        modularity_score = get_score(adj_list, communities, edge_weights)
        
        println("✅ Modularity score: $(round(modularity_score, digits=4))")
        
        # Interpret the score
        if modularity_score > 0.3
            println("   🟢 Excellent community structure")
        elseif modularity_score > 0.1
            println("   🟡 Good community structure")
        elseif modularity_score > 0.0
            println("   🟠 Weak community structure")
        else
            println("   🔴 Poor/No community structure")
        end
        
        # Create visualization
        println("🎨 Creating visualization...")
        
        # Determine output filename
        if isempty(output_prefix)
            base_name = replace(filename, ".txt" => "")
            # Remove path prefix to get just the filename
            base_name = replace(base_name, r"^.*/" => "")
            output_file = "graphs/$(base_name)_visualization.png"
        else
            output_file = "graphs/$(output_prefix)_visualization.png"
        end
        
        # Plot the graph
        plot_graph(filename, communities, modularity_score, output_file)
        
        println("="^50)
        println("✅ Graph processing complete!")
        println("📁 Visualization saved to: $output_file")
        println("📊 Final modularity score: $(round(modularity_score, digits=4))")
        
        return modularity_score, communities, output_file
        
    catch e
        println("❌ Error processing graph:")
        println("   $e")
        println("   📍 File: $filename")
        return nothing, nothing, nothing
    end
end

function run_stable_workflow(filename::String="graph_input.txt")
    """
    Run the complete workflow with stable visualization.
    No interactive windows, output saved to PNG files.
    """
    
    println("🌟 STABLE GRAPH ANALYSIS WORKFLOW")
    println("="^50)
    println("📄 Input file: $filename")
    println("🖼️  Output: PNG visualization file")
    println("🎯 Backend: CairoMakie (stable, non-interactive)")
    println()
    
    if !isfile(filename)
        println("❌ Error: File not found: $filename")
        println("📁 Available files:")
        for file in readdir(".")
            if endswith(file, ".txt")
                println("   - $file")
            end
        end
        return
    end
    
    # Process the graph
    result = process_graph(filename)
    
    if result[1] !== nothing
        modularity, communities, output_file = result
        println("🎉 SUCCESS! Check the output file: $output_file")
        println("💡 Tip: Open $output_file in any image viewer to see the graph")
    else
        println("💥 FAILED! Check the error messages above")
    end
    
    println("="^50)
    return result
end

function batch_process_graphs(graph_files::Vector{String})
    """
    Process multiple graphs in batch mode.
    Stable and won't hang on graphics issues.
    """
    
    println("📦 BATCH PROCESSING MODE")
    println("="^50)
    println("📋 Processing $(length(graph_files)) graph files")
    println()
    
    results = []
    
    for (i, filename) in enumerate(graph_files)
        println("🔄 Processing $i/$(length(graph_files)): $filename")
        
        if !isfile(filename)
            println("   ⚠️  Skipping (file not found)")
            continue
        end
        
        result = process_graph(filename, "batch_$(i)")
        push!(results, (filename, result))
        
        println("   ✅ Completed")
        println()
    end
    
    # Summary
    println("📋 BATCH PROCESSING SUMMARY")
    println("="^50)
    
    for (filename, result) in results
        if result[1] !== nothing
            modularity, communities, output_file = result
            println("✅ $filename → Modularity: $(round(modularity, digits=4)) → $output_file")
        else
            println("❌ $filename → FAILED")
        end
    end
    
    println("="^50)
    return results
end

function main()
    """Main function - processes graph_input.txt or command line argument."""
    
    # Check if filename provided as command line argument
    if length(ARGS) > 0
        filename = ARGS[1]
    else
        filename = "graph_input.txt"
    end
    
    run_stable_workflow(filename)
end

# Run main if this file is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
