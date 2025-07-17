include("plot_graph.jl")
include("scoring.jl")
using Random
using StatsBase
using Colors
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

function our_algorithm(g, edge_weights, node_info)
    current_colors = [node_info[k].label for k in 1:nv(g)]
    current_score = get_score(g, edge_weights, node_info, current_colors)
    changes_made = 0
    label_changed = true

    while label_changed
        shuffled_nodes = shuffle(1:nv(g))
        label_changed = false
        for n in shuffled_nodes
            score_changes = Dict{Int, Float64}()  # Changed to Float64 for score values
            
            for nbr in node_info[n].neighbors
                # Create a temporary copy of node_info to test the change
                temp_node_info = deepcopy(node_info)
                temp_node_info[n].label = node_info[nbr].label
                temp_colors = [temp_node_info[k].label for k in 1:nv(g)]
                score_changes[node_info[nbr].label] = get_score(g, edge_weights, temp_node_info, temp_colors) - current_score
            end
            
            if !isempty(score_changes)
                max_change = maximum(values(score_changes))
                if max_change > 0
                    keys_at_max = [key for (key, value) in score_changes if value == max_change]
                    best_label = rand(keys_at_max)
                    old_label = node_info[n].label
                    node_info[n].label = best_label
                    changes_made += 1
                    label_changed = true
                    println("Node $n: $old_label -> $best_label (score change: $max_change)")
                    # Update current_score for next iteration
                    current_colors = [node_info[k].label for k in 1:nv(g)]
                    current_score = get_score(g, edge_weights, node_info, current_colors)
                end
            end
        end
        println("Total changes made: $changes_made")
    end
end

function label_propagation(g, node_info)
    label_changed = true
    while label_changed
        label_changed = false
        shuffled_nodes = shuffle(1:nv(g))

        for n in shuffled_nodes
            neighbor_labels = [node_info[j].label for j in node_info[n].neighbors]
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

    # println("Running the updated algorithm...")
    our_algorithm(g, edge_weights, node_info)

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
                println("🔄 Running optimization algorithm...")
                our_algorithm(g, edge_weights, node_info)
                
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
