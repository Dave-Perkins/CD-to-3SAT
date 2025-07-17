#!/usr/bin/env julia

# Stable plotting with CairoMakie (non-interactive but more reliable)
# Alternative to GLMakie for users experiencing persistent graphics issues

using CairoMakie
using Colors
using Printf

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

function plot_graph_cairo(filename::String, communities::Vector{Vector{Int}}, 
                         modularity_score::Float64, output_file::String="graph_output.png")
    """
    Plot graph using CairoMakie (saves to PNG file instead of showing window).
    More stable than GLMakie, especially for repeated use.
    """
    
    println("📊 Creating visualization with CairoMakie...")
    
    try
        # Read the graph
        edges, edge_weights = read_edges(filename)
        adj_list, nodes = build_graph(edges)
        
        # Create figure
        fig = Figure(size = (800, 600))
        ax = Axis(fig[1, 1], 
                 title = "Graph Communities (Modularity: $(round(modularity_score, digits=4)))",
                 aspect = DataAspect(),
                 xlabel = "X",
                 ylabel = "Y")
        
        # Simple circular layout for nodes
        n_nodes = length(nodes)
        node_positions = Dict{Int, Tuple{Float64, Float64}}()
        
        for (i, node) in enumerate(sort(nodes))
            angle = 2π * (i-1) / n_nodes
            x = cos(angle)
            y = sin(angle)
            node_positions[node] = (x, y)
        end
        
        # Plot edges
        for (n1, n2) in edges
            x1, y1 = node_positions[n1]
            x2, y2 = node_positions[n2]
            
            # Draw edge
            lines!(ax, [x1, x2], [y1, y2], color = :gray, linewidth = 1)
            
            # Add weight label at midpoint
            weight = edge_weights[(n1, n2)]
            if weight != 1.0  # Only show if not default weight
                mid_x = (x1 + x2) / 2
                mid_y = (y1 + y2) / 2
                text!(ax, mid_x, mid_y, text = string(weight), 
                     fontsize = 8, color = :red, align = (:center, :center))
            end
        end
        
        # Color palette for communities
        colors = [:red, :blue, :green, :orange, :purple, :brown, :pink, :gray]
        
        # Plot nodes with community colors
        for (i, community) in enumerate(communities)
            color = colors[((i-1) % length(colors)) + 1]
            
            for node in community
                x, y = node_positions[node]
                scatter!(ax, [x], [y], color = color, markersize = 20)
                text!(ax, x, y, text = string(node), 
                     color = :white, fontsize = 10, align = (:center, :center))
            end
        end
        
        # Add legend
        legend_elements = []
        for (i, community) in enumerate(communities)
            color = colors[((i-1) % length(colors)) + 1]
            push!(legend_elements, MarkerElement(color = color, marker = :circle))
        end
        
        community_labels = ["Community $i" for i in 1:length(communities)]
        axislegend(ax, legend_elements, community_labels, position = :rt)
        
        # Save to file
        save(output_file, fig)
        println("✅ Graph saved to: $output_file")
        println("📁 Open this file to view the graph visualization")
        
        return fig
        
    catch e
        println("❌ Error creating graph visualization:")
        println("   $e")
        return nothing
    end
end

function plot_graph_safe(filename::String, communities::Vector{Vector{Int}}, 
                        modularity_score::Float64, output_file::String="graph_output.png")
    """
    Safe wrapper that tries CairoMakie first, with fallback options.
    """
    
    println("🎨 Starting safe graph visualization...")
    
    # Try CairoMakie first (most stable)
    try
        return plot_graph_cairo(filename, communities, modularity_score, output_file)
    catch e
        println("⚠️  CairoMakie failed: $e")
    end
    
    # Fallback: create a text-based visualization
    println("📝 Creating text-based visualization as fallback...")
    
    try
        edges, edge_weights = read_edges(filename)
        adj_list, nodes = build_graph(edges)
        
        println("\n" * "="^50)
        println("GRAPH VISUALIZATION (Text Mode)")
        println("="^50)
        println("📊 Modularity Score: $(round(modularity_score, digits=4))")
        println("🔗 Total Edges: $(length(edges))")
        println("🔵 Total Nodes: $(length(nodes))")
        println()
        
        # Show communities
        for (i, community) in enumerate(communities)
            println("Community $i: $(join(community, ", "))")
        end
        
        println()
        println("Edge List (with weights):")
        for (n1, n2) in edges
            weight = edge_weights[(n1, n2)]
            if weight == 1.0
                println("  $n1 -- $n2")
            else
                println("  $n1 -- $n2 (weight: $weight)")
            end
        end
        
        println("="^50)
        
        return nothing
        
    catch e
        println("❌ Even text visualization failed: $e")
        return nothing
    end
end

# Export the main function
const plot_graph = plot_graph_safe

if abspath(PROGRAM_FILE) == @__FILE__
    println("This is a plotting utility module.")
    println("Usage: include(\"plot_graph_stable.jl\") then call plot_graph(...)")
end
