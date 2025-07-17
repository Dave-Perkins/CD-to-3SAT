using Graphs, Colors

include("scoring.jl")

# Create a simple triangle graph for testing
g = SimpleGraph(3)
add_edge!(g, 1, 2)
add_edge!(g, 2, 3)
add_edge!(g, 1, 3)

# Create edge weights (all edges weight 1)
edge_weights = Dict()
for edge in edges(g)
    edge_weights[(src(edge), dst(edge))] = 1.0
    edge_weights[(dst(edge), src(edge))] = 1.0  # Both directions for undirected
end

println("Triangle graph (3 nodes, 3 edges)")
println("Edge weights: ", edge_weights)

# Test with all nodes in one community
node_colors = [colorant"red", colorant"red", colorant"red"]

# Manual calculation for modularity
println("\n=== MANUAL CALCULATION ===")
# For undirected graph: m = 3 edges, so 2m = 6
m = 3
two_m = 6

# Degrees: each node has degree 2
degree = [2, 2, 2]

println("Number of edges (m): ", m)
println("2m: ", two_m)
println("Degrees: ", degree)

# For all nodes in same community, modularity should be:
# Q = (1/2m) * sum_{ij} [A_ij - (k_i * k_j)/(2m)] * δ(c_i, c_j)
# Since all nodes are in same community, δ(c_i, c_j) = 1 for all pairs

global modularity_manual = 0.0
println("\nCalculating modularity manually:")
for i in 1:3
    for j in 1:3
        A_ij = 0.0
        if i == j
            A_ij = 0.0  # No self-loops
        elseif (i == 1 && j == 2) || (i == 2 && j == 1) ||
               (i == 2 && j == 3) || (i == 3 && j == 2) ||
               (i == 1 && j == 3) || (i == 3 && j == 1)
            A_ij = 1.0
        end
        
        expected = (degree[i] * degree[j]) / two_m
        contribution = A_ij - expected
        
        println("($i,$j): A_ij=$A_ij, expected=$expected, contribution=$contribution")
        global modularity_manual += contribution
    end
end

modularity_manual = modularity_manual / two_m
println("Manual modularity: ", modularity_manual)

# Test with our function
println("\n=== FUNCTION CALCULATION ===")
node_color_indices = [1, 1, 1]  # All nodes in community 1
result = get_score(g, edge_weights, nothing, node_color_indices)
println("Function modularity: ", result)

# Test what happens if we only count upper triangle + diagonal
println("\n=== UPPER TRIANGLE CALCULATION ===")
global modularity_upper = 0.0
for i in 1:3
    for j in i:3  # Upper triangle including diagonal
        A_ij = 0.0
        if i == j
            A_ij = 0.0  # No self-loops
        elseif (i == 1 && j == 2) || (i == 2 && j == 3) || (i == 1 && j == 3)
            A_ij = 1.0
        end
        
        expected = (degree[i] * degree[j]) / two_m
        contribution = A_ij - expected
        
        # Apply multiplier
        multiplier = (i == j) ? 1.0 : 2.0
        contribution *= multiplier
        
        println("($i,$j): A_ij=$A_ij, expected=$expected, base_contribution=$(contribution/multiplier), multiplier=$multiplier, total_contribution=$contribution")
        global modularity_upper += contribution
    end
end

modularity_upper = modularity_upper / two_m
println("Upper triangle modularity: ", modularity_upper)
