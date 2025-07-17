using Graphs

include("mini03.jl")

# Test the graph03.txt file after algorithm runs
println("=== DEBUGGING AFTER ALGORITHM ===")

edge_list = read_edges("graphs/graph03.txt")
g, edge_weights = build_graph(edge_list)

# Build node_info like in main function
node_info = Dict{Int, NodeInfo}()
for n in 1:nv(g)
    node_info[n] = NodeInfo(n, collect(neighbors(g, n)))
end

println("BEFORE algorithm:")
println("node_info keys: ", sort(collect(keys(node_info))))
println("node labels: ", [node_info[i].label for i in 1:nv(g)])

# Run the algorithm
println("\nRunning algorithm...")
our_algorithm(g, edge_weights, node_info)

println("\nAFTER algorithm:")
println("node_info keys: ", sort(collect(keys(node_info))))
println("node labels: ", [node_info[i].label for i in 1:nv(g)])

# Check if any labels are outside the valid range
labels = [node_info[i].label for i in 1:nv(g)]
unique_labels = unique(labels)
println("Unique labels: ", unique_labels)
println("Max label: ", maximum(unique_labels))
println("Min label: ", minimum(unique_labels))

# Test score calculation after algorithm
try
    score = get_score(g, edge_weights, node_info, labels)
    println("Score calculation successful: ", score)
catch e
    println("ERROR in get_score: ", e)
end
