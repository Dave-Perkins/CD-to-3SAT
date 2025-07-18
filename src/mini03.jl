include("plot_graph.jl")
include("scoring.jl")
using Random
using StatsBase
using Colors
using Graphs
using Makie: distinguishable_colors

# Function to clear graphics state and restart GLMakie
function restart_graphics()
    try
        GLMakie.closeall()
        GLMakie.activate!()
        println("Graphics backend restarted successfully.")
    catch e
        println("Could not restart graphics backend: $e")
        println("Please restart Julia manually if issues persist.")
    end
end

mutable struct NodeInfo
    label::Int
    neighbors::Vector{Int}
end

# Leiden algorithm for community detection - improved version of label propagation
function leiden_algorithm(g, edge_weights, node_info; max_iterations=50, resolution=1.0)
    n_nodes = nv(g)
    current_partition = [node_info[k].label for k in 1:n_nodes]
    best_modularity = get_score(g, edge_weights, node_info, current_partition)
    
    iteration = 0
    improvement = true
    
    println("🔬 Starting Leiden algorithm (max $max_iterations iterations)...")
    
    while improvement && iteration < max_iterations
        iteration += 1
        improvement = false
        
        # Phase 1: Local moving phase
        shuffled_nodes = shuffle(1:n_nodes)
        
        for node in shuffled_nodes
            current_community = node_info[node].label
            best_community = current_community
            best_gain = 0.0
            
            # Test moving to neighbor communities
            neighbor_communities = Set{Int}()
            for neighbor in node_info[node].neighbors
                if neighbor <= n_nodes && neighbor >= 1  # Safety check
                    push!(neighbor_communities, node_info[neighbor].label)
                end
            end
            
            # Test each potential community
            for test_community in neighbor_communities
                if test_community != current_community
                    # Temporarily move node and calculate score change
                    old_label = node_info[node].label
                    node_info[node].label = test_community
                    
                    new_partition = [node_info[k].label for k in 1:n_nodes]
                    new_score = get_score(g, edge_weights, node_info, new_partition)
                    gain = new_score - best_modularity
                    
                    if gain > best_gain
                        best_gain = gain
                        best_community = test_community
                    end
                    
                    # Restore original label for now
                    node_info[node].label = old_label
                end
            end
            
            # Apply best move if improvement found
            if best_gain > 1e-8  # Small threshold for numerical stability
                node_info[node].label = best_community
                improvement = true
                best_modularity += best_gain
            end
        end
        
        if iteration % 10 == 0 || improvement
            current_partition = [node_info[k].label for k in 1:n_nodes]
            current_score = get_score(g, edge_weights, node_info, current_partition)
            
            # Calculate community sizes
            communities = unique(current_partition)
            community_sizes = [count(x -> x == c, current_partition) for c in communities]
            sorted_sizes = sort(community_sizes, rev=true)
            
            println("   Iteration $iteration: modularity = $(round(current_score, digits=6))")
            println("      🏘️  Communities: $(length(communities)), sizes: $(sorted_sizes[1:min(10, length(sorted_sizes))])$(length(sorted_sizes) > 10 ? "..." : "")")
        end
    end
    
    # Final score calculation
    final_partition = [node_info[k].label for k in 1:n_nodes]
    final_score = get_score(g, edge_weights, node_info, final_partition)
    
    # Final community analysis
    final_communities = unique(final_partition)
    final_community_sizes = [count(x -> x == c, final_partition) for c in final_communities]
    sorted_final_sizes = sort(final_community_sizes, rev=true)
    
    println("✅ Leiden completed after $iteration iterations")
    println("📊 Final modularity: $(round(final_score, digits=6))")
    println("🏘️  Final communities: $(length(final_communities))")
    println("📏 Community sizes: $(sorted_final_sizes)")
    
    # Show distribution statistics
    if length(sorted_final_sizes) > 1
        avg_size = sum(sorted_final_sizes) / length(sorted_final_sizes)
        largest_size = maximum(sorted_final_sizes)
        smallest_size = minimum(sorted_final_sizes)
        println("📈 Size stats: largest=$(largest_size), smallest=$(smallest_size), avg=$(round(avg_size, digits=1))")
    end
    
    return final_score
end

# Legacy function name for backward compatibility
function label_propagation_v2(g, edge_weights, node_info)
    return leiden_algorithm(g, edge_weights, node_info)
end

function label_propagation(g, node_info)
    label_changed = true
    while label_changed
        label_changed = false
        shuffled_nodes = shuffle(1:nv(g))

        for n in shuffled_nodes
            neighbor_labels = [node_info[j].label for j in node_info[n].neighbors]
            
            # Skip nodes with no neighbors (isolated nodes)
            if isempty(neighbor_labels)
                continue
            end
            
            most_common = findmax(countmap(neighbor_labels))[2]
            if node_info[n].label != most_common
                node_info[n].label = most_common
                label_changed = true
            end
        end
    end
end

function main(filename)
    println("Loading graph from $filename...")
    edge_list = read_edges(filename)
    g, edge_weights = build_graph(edge_list)

    # Build a dictionary mapping node indices to the node's info
    node_info = Dict{Int, NodeInfo}()
    for n in 1:nv(g)
        node_info[n] = NodeInfo(n, collect(neighbors(g, n)))
    end
    
    # println("Running label propagation algorithm...")
    # label_propagation(g, node_info)

    println("Running the improved label propagation v2 algorithm...")
    label_propagation_v2(g, edge_weights, node_info)

    # Use a fixed-size color palette for cycling, e.g., 16 colors
    palette_size = 16
    color_palette = distinguishable_colors(palette_size)

    # Assign initial color indices based on label AFTER running algorithms
    labels = unique([node.label for node in values(node_info)])
    label_to_color_index = Dict(labels[i] => mod1(i, palette_size) for i in eachindex(labels))
    node_color_indices = [label_to_color_index[node_info[n].label] for n in 1:nv(g)]
    node_colors = [color_palette[i] for i in node_color_indices]
    node_text_colors = [Colors.Lab(RGB(c)).l > 50 ? :black : :white for c in node_colors]

    println("🎨 Creating interactive visualization...")
    result = interactive_plot_graph(g, edge_weights, node_info, node_colors, node_text_colors, node_color_indices, color_palette, label_to_color_index)
    
    if result === nothing
        println("❌ Visualization failed. Try running: restart_graphics()")
    else
        println("✅ Visualization complete!")
    end
    
    return result
end

# Wrapper function for easy testing
function run_graph(filename)
    println("🚀 Starting graph analysis workflow...")
    println("📁 File: $filename")
    println("="^50)
    
    try
        result = main(filename)

        println("="^50)
        println("🎉 Workflow completed successfully!")
        return result
    catch e
        println("="^50)
        println("❌ Error occurred: $e")
        println("🔄 Trying to restart graphics backend...")
        restart_graphics()
        println("💡 Please try running the command again.")
        return nothing
    end
end

# Interactive function with more control
function run_graph_interactive(filename)
    println("🚀 Starting interactive graph analysis...")
    println("📁 File: $filename")
    println("="^50)
    
    try
        # Load and process the graph
        println("📖 Loading graph from $filename...")
        edge_list = read_edges(filename)
        g, edge_weights = build_graph(edge_list)

        # Build node info
        node_info = Dict{Int, NodeInfo}()
        for n in 1:nv(g)
            node_info[n] = NodeInfo(n, collect(neighbors(g, n)))
        end
        
        println("🔍 Running label propagation algorithm...")
        label_propagation(g, node_info)

        # Setup colors
        palette_size = 16
        color_palette = distinguishable_colors(palette_size)
        labels = unique([node.label for node in values(node_info)])
        label_to_color_index = Dict(labels[i] => mod1(i, palette_size) for i in eachindex(labels))
        node_color_indices = [label_to_color_index[node_info[n].label] for n in 1:nv(g)]
        node_colors = [color_palette[i] for i in node_color_indices]
        node_text_colors = [Colors.Lab(RGB(c)).l > 50 ? :black : :white for c in node_colors]

        # Show menu
        while true
            println("\n🎯 What would you like to do?")
            println("1. Open interactive visualization")
            println("2. Run optimization algorithm")
            println("3. Show current score")
            println("4. Exit")
            print("Enter choice (1-4): ")
            
            choice = strip(readline())
            
            if choice == "1"
                println("🎨 Opening interactive visualization...")
                interactive_plot_graph(g, edge_weights, node_info, node_colors, node_text_colors, node_color_indices, color_palette, label_to_color_index)

                # Update colors after interaction
                node_color_indices = [label_to_color_index[node_info[n].label] for n in 1:nv(g)]
                node_colors = [color_palette[i] for i in node_color_indices]
                node_text_colors = [Colors.Lab(RGB(c)).l > 50 ? :black : :white for c in node_colors]
                
            elseif choice == "2"
                println("🔄 Running label propagation v2 algorithm...")
                label_propagation_v2(g, edge_weights, node_info)
                
                # Update colors after optimization
                labels = unique([node.label for node in values(node_info)])
                label_to_color_index = Dict(labels[i] => mod1(i, palette_size) for i in eachindex(labels))
                node_color_indices = [label_to_color_index[node_info[n].label] for n in 1:nv(g)]
                node_colors = [color_palette[i] for i in node_color_indices]
                node_text_colors = [Colors.Lab(RGB(c)).l > 50 ? :black : :white for c in node_colors]
                
            elseif choice == "3"
                current_colors = [node_info[k].label for k in 1:nv(g)]
                score = get_score(g, edge_weights, node_info, current_colors)
                println("📊 Current modularity score: $(round(score, digits=4))")
                
            elseif choice == "4"
                println("👋 Goodbye!")
                break
                
            else
                println("❌ Invalid choice. Please enter 1-4.")
            end
        end
        
    catch e
        println("❌ Error occurred: $e")
        println("🔄 Trying to restart graphics backend...")
        restart_graphics()
        println("💡 Please try running the command again.")
    end
end

println("🌟 MINI03 INTERACTIVE GRAPH ANALYSIS")
println("="^50)
println("💡 Available functions:")
println("   • run_graph(filename) - Simple workflow")
println("   • run_graph_interactive(filename) - Interactive menu")
println("   • restart_graphics() - Fix graphics issues")
println()
println("🚀 Quick start:")
println("   julia> run_graph(\"graph03.txt\")")
println("   julia> run_graph_interactive(\"graph03.txt\")")
println()
# Commented out - no longer showing available graph files by default
# println("📁 Available graph files:")
# for file in readdir(".")
#     if endswith(file, ".txt") && startswith(file, "graph")
#         println("   • $file")
#     end
# end
println("="^50)
