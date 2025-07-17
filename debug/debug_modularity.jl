include("mini03.jl")

# Debug our implementation step by step
edge_list = read_edges("graphs/graph03.txt")
g, edge_weights = build_graph(edge_list)

node_info = Dict{Int, NodeInfo}()
for n in 1:nv(g)
    node_info[n] = NodeInfo(n, collect(neighbors(g, n)))
end

# Test with all nodes in one community
one_community = fill(1, nv(g))

println("🔍 Debugging Our Implementation")
println()

n = nv(g)
total_weight = 0.0
weighted_degrees = zeros(Float64, n)

for edge in edges(g)
    i, j = src(edge), dst(edge)
    weight = get(edge_weights, (i, j), 1.0)
    total_weight += weight
    weighted_degrees[i] += weight
    weighted_degrees[j] += weight
end

two_m = total_weight
println("Total weight (2m): $two_m")
println("Weighted degrees: $(weighted_degrees[1:5])...")
println()

# Trace through our double loop
modularity = 0.0
contribution_count = 0

for i in 1:n
    for j in i:n
        if one_community[i] == one_community[j]  # Always true
            A_ij = 0.0
            if has_edge(g, i, j)
                A_ij = get(edge_weights, (i, j), 1.0)
            end
            
            expected_weight = (weighted_degrees[i] * weighted_degrees[j]) / two_m
            contribution = A_ij - expected_weight
            
            if i == j
                modularity += contribution
                multiplier = 1
            else
                modularity += 2 * contribution
                multiplier = 2
            end
            
            contribution_count += 1
            if contribution_count <= 10
                println("($i,$j): A_ij=$A_ij, expected=$(round(expected_weight,digits=3)), contrib=$(round(contribution,digits=3)), mult=$multiplier")
            end
        end
    end
end

println("...")
println("Total contributions: $contribution_count")
println("Raw sum: $(round(modularity, digits=4))")
modularity = modularity / two_m
println("Final modularity: $(round(modularity, digits=4))")
