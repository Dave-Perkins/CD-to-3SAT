#= 
Written entirely by Copilot and GPT 4.1, this script reads a text file where 
each line is an edge ("x y") and then displays the graph using GraphMakie.
=#
using Graphs
using GraphMakie
using GLMakie
using GeometryBasics
using LinearAlgebra: norm

# Function to safely activate GLMakie
function safe_activate_glmakie()
    try
        GLMakie.activate!()
        return true
    catch e
        println("Warning: Could not activate GLMakie: $e")
        return false
    end
end
const Point2f0 = GeometryBasics.Point2f
import Graphs: edges

function read_edges(filename)
    edge_list = []
    open(filename, "r") do f
        for line in eachline(f)
            s = split(strip(line))
            # Skip comment lines
            if startswith(strip(line), "#") || isempty(strip(line))
                continue
            end
            # Handle both weighted (3 columns) and unweighted (2 columns) formats
            if length(s) == 2 && all(x -> occursin(r"^\d+$", x), s)
                # Unweighted edge, default weight = 1.0
                push!(edge_list, (parse(Int, s[1]), parse(Int, s[2]), 1.0))
            elseif length(s) == 3 && all(x -> occursin(r"^\d+$", x), s[1:2]) && occursin(r"^\d+(\.\d+)?$", s[3])
                # Weighted edge
                push!(edge_list, (parse(Int, s[1]), parse(Int, s[2]), parse(Float64, s[3])))
            end
        end
    end
    return edge_list
end

function build_graph(edges)
    if isempty(edges)
        println("No edges found in input file. Displaying an empty graph.")
        return SimpleGraph(0), Dict{Tuple{Int,Int}, Float64}()
    end
    nodes = unique(vcat([e[1] for e in edges], [e[2] for e in edges]))
    g = SimpleGraph(maximum(nodes))
    edge_weights = Dict{Tuple{Int,Int}, Float64}()
    
    for (u, v, weight) in edges
        add_edge!(g, u, v)
        # Store weights for both directions (undirected graph)
        edge_weights[(u, v)] = weight
        edge_weights[(v, u)] = weight
    end
    return g, edge_weights
end

function interactive_plot_graph(g, edge_weights, node_info, node_colors, node_text_colors, node_color_indices, color_palette, label_to_color_index)
    # Safely activate GLMakie backend
    if !safe_activate_glmakie()
        println("Failed to activate GLMakie backend. Please restart Julia.")
        return nothing
    end
    
    n = nv(g)
    edges = collect(Graphs.edges(g))
    width, height = 800, 600
    cx, cy = width/2, height/2
    radius = min(width, height) * 0.4
    positions = Observable([Point2f0(cx + radius * cos(2π*i/n), cy + radius * sin(2π*i/n)) for i in 1:n])

    # Use an Observable for node colors to allow interactive updates
    node_colors_obs = Observable(copy(node_colors))
    node_color_indices_obs = Observable(copy(node_color_indices))
    node_text_colors_obs = Observable(copy(node_text_colors))
    
    # Create reverse mapping from color index to label
    color_index_to_label = Dict(v => k for (k, v) in label_to_color_index)

    # Create a new figure and scene
    fig = Figure(size = (width, height))
    scene = fig.scene
    
    # Observable for score, initialize with the correct score
    initial_score = get_score(g, edge_weights, node_info, node_color_indices)
    score_obs = Observable(initial_score)
    # Display score in the plot window (top left)
    text!(scene, lift(s -> "Score: $(round(s, digits=3))", score_obs), position=Point2f0(20, height-30), align=(:left, :center), color=:black, fontsize=28)

    # Plot edges
    [lines!(scene, lift(pos -> [pos[src(e)], pos[dst(e)]], positions), color=:gray, linewidth=2) for e in edges]
    
    # Plot edge weights as text labels at the midpoint of each edge
    for e in edges
        src_node, dst_node = src(e), dst(e)
        weight = get(edge_weights, (src_node, dst_node), 1.0)
        # Calculate midpoint position between the two nodes
        midpoint_pos = lift(pos -> (pos[src_node] + pos[dst_node]) / 2, positions)
        # Add text label showing the weight
        text!(scene, string(weight), position=midpoint_pos, align=(:center, :center), 
              color=:red, fontsize=14, strokewidth=1, strokecolor=:white)
    end
    
    # Plot nodes as scatter, use node_colors_obs directly
    scatter!(scene, lift(pos -> first.(pos), positions), lift(pos -> last.(pos), positions),
        color=node_colors_obs, strokewidth=2, strokecolor=:black, markersize=60)
    # Plot labels, use node_text_colors_obs for each node
    [text!(scene, string(i), position=lift(pos -> pos[i], positions), align=(:center, :center), color=lift(_ -> node_text_colors_obs[][i], node_text_colors_obs), fontsize=18) for i in 1:n]

    # Dragging state
    dragging = Observable(false)
    drag_idx = Observable(0)
    last_mousepos = Observable(Point2f0(0, 0))
    mouse_down_pos = Observable(Point2f0(0, 0))
    mouse_down_node = Observable(0)
    moved = Observable(false)

    on(scene.events.mouseposition) do pos
        last_mousepos[] = Point2f0(pos[1], pos[2])
        if dragging[] && drag_idx[] > 0
            # Only start moving if the mouse has moved more than a threshold
            if !moved[] && norm(last_mousepos[] .- mouse_down_pos[]) > 5
                moved[] = true
            end
            if moved[]
                mousepos = last_mousepos[]
                newpos = copy(positions[])
                newpos[drag_idx[]] = mousepos
                positions[] = newpos
            end
        end
    end

    on(scene.events.mousebutton) do event
        if event.button == Mouse.left || event.button == Mouse.right
            if event.action == Mouse.press
                mousepos = last_mousepos[]
                for i in 1:n
                    if norm(mousepos .- positions[][i]) < 30  # 30 pixels for easier selection
                        dragging[] = true
                        drag_idx[] = i
                        mouse_down_pos[] = mousepos
                        mouse_down_node[] = i
                        moved[] = false
                        break
                    end
                end
            elseif event.action == Mouse.release
                if dragging[] && drag_idx[] > 0
                    # Only cycle color if not moved and press/release on same node
                    if !moved[] && mouse_down_node[] == drag_idx[]
                        idx = drag_idx[]
                        # Cycle the color index forward or backward
                        new_color_indices = copy(node_color_indices_obs[])
                        if event.button == Mouse.left
                            new_color_indices[idx] = mod1(new_color_indices[idx] + 1, length(color_palette))
                        elseif event.button == Mouse.right
                            new_color_indices[idx] = mod1(new_color_indices[idx] - 1, length(color_palette))
                        end
                        node_color_indices_obs[] = new_color_indices
                        # Update node colors from indices
                        new_colors = copy(node_colors_obs[])
                        new_colors[idx] = color_palette[new_color_indices[idx]]
                        node_colors_obs[] = new_colors
                        # Update node text color for this node
                        new_text_colors = copy(node_text_colors_obs[])
                        new_text_colors[idx] = Colors.Lab(RGB(new_colors[idx])).l > 50 ? :black : :white
                        node_text_colors_obs[] = new_text_colors
                        # Update the node_info label to match the actual label (not color index)
                        # If the color index doesn't exist in our mapping, create a new unique label
                        if haskey(color_index_to_label, new_color_indices[idx])
                            actual_label = color_index_to_label[new_color_indices[idx]]
                        else
                            # Create a new unique label for this color index
                            # Use a label that's unique and doesn't conflict with existing ones
                            existing_labels = Set([node_info[i].label for i in 1:nv(g)])
                            new_label = 1
                            while new_label in existing_labels
                                new_label += 1
                            end
                            actual_label = new_label
                            # Update the mapping for future use
                            color_index_to_label[new_color_indices[idx]] = actual_label
                        end
                        node_info[idx].label = actual_label
                        # Update score using the updated node_info
                        # Create current_color_indices array indexed by node number
                        current_color_indices = [node_info[i].label for i in 1:nv(g)]
                        score = get_score(g, edge_weights, node_info, current_color_indices)
                        score_obs[] = score
                    end
                end
                dragging[] = false
                drag_idx[] = 0
                mouse_down_node[] = 0
                moved[] = false
            end
        end
    end

    println("🎨 Interactive graph visualization is ready!")
    println("💡 Instructions:")
    println("   • Left-click nodes to cycle colors forward")
    println("   • Right-click nodes to cycle colors backward")
    println("   • Drag nodes to move them around")
    println("   • Score updates automatically when colors change")
    
    # Display the figure
    try
        display(fig)
        
        # Keep the window open - wait for user input
        println("\n📊 Graph window is now open and interactive!")
        println("Press Enter here in the terminal to close the graph window...")
        readline()
        
        # Clean up - just close all GLMakie windows
        GLMakie.closeall()
        println("✅ Graph window closed.")
        
    catch e
        println("❌ Display error: $e")
        println("Try restarting Julia if the issue persists.")
    end
    
    return fig
end