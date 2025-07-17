using Graphs

include("mini03.jl")

# Test the color mapping after algorithm
println("=== DEBUGGING COLOR MAPPING ===")

edge_list = read_edges("graphs/graph03.txt")
g, edge_weights = build_graph(edge_list)

# Build node_info and run algorithm
node_info = Dict{Int, NodeInfo}()
for n in 1:nv(g)
    node_info[n] = NodeInfo(n, collect(neighbors(g, n)))
end

our_algorithm(g, edge_weights, node_info)

# Create color mapping like in main
palette_size = 16
labels = unique([node.label for node in values(node_info)])
println("Unique labels: ", labels)

label_to_color_index = Dict(labels[i] => mod1(i, palette_size) for i in eachindex(labels))
println("label_to_color_index: ", label_to_color_index)

# Create reverse mapping like in plot_graph
color_index_to_label = Dict(v => k for (k, v) in label_to_color_index)
println("color_index_to_label: ", color_index_to_label)

# Check if reverse mapping lost information
println("Number of labels: ", length(labels))
println("Number of entries in label_to_color_index: ", length(label_to_color_index))
println("Number of entries in color_index_to_label: ", length(color_index_to_label))

# Test accessing like in the plot function
for (i, label) in enumerate(labels)
    color_idx = label_to_color_index[label]
    reverse_label = get(color_index_to_label, color_idx, "MISSING")
    println("Label $label -> color_idx $color_idx -> reverse_label $reverse_label")
end

# Test the actual problematic line
node_color_indices = [label_to_color_index[node_info[n].label] for n in 1:nv(g)]
println("node_color_indices: ", node_color_indices)

# Test what happens when we try to access idx=16 in the plotting loop
idx = 16
if idx <= length(node_color_indices)
    new_color_idx = (node_color_indices[idx] % palette_size) + 1
    println("For idx=$idx, current color_idx=$(node_color_indices[idx]), new_color_idx=$new_color_idx")
    actual_label = get(color_index_to_label, new_color_idx, "NOT_FOUND")
    println("actual_label: $actual_label")
else
    println("idx=$idx is out of bounds for node_color_indices (length=$(length(node_color_indices)))")
end
