include("mini03.jl")

edge_list = read_edges("graphs/graph03.txt")
g, edge_weights = build_graph(edge_list)

node_info = Dict{Int, NodeInfo}()
for n in 1:nv(g)
    node_info[n] = NodeInfo(n, collect(neighbors(g, n)))
end

one_community = fill(1, nv(g))

println("🔍 Testing Reverted Implementation")
score = get_score(g, edge_weights, node_info, one_community)
println("Result: $score")
println("Expected: 0.0")
