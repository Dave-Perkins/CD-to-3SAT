using Graphs

include("mini03.jl")

# Test the graph03.txt file to see what's happening
println("=== DEBUGGING GRAPH03.TXT ===")

edge_list = read_edges("graphs/graph03.txt")
g, edge_weights = build_graph(edge_list)

println("Number of vertices: ", nv(g))
println("Number of edges: ", ne(g))
println("Vertices: ", vertices(g))

# Build node_info like in main function
node_info = Dict{Int, NodeInfo}()
for n in 1:nv(g)
    node_info[n] = NodeInfo(n, collect(neighbors(g, n)))
end

println("node_info keys: ", sort(collect(keys(node_info))))
println("Length of node_info: ", length(node_info))

# Test creating color indices array
test_color_indices = [node_info[i].label for i in 1:nv(g)]
println("test_color_indices: ", test_color_indices)
println("Length of test_color_indices: ", length(test_color_indices))

# Test get_score function
try
    score = get_score(g, edge_weights, node_info, test_color_indices)
    println("Score calculation successful: ", score)
catch e
    println("ERROR in get_score: ", e)
    println("Type of error: ", typeof(e))
end
