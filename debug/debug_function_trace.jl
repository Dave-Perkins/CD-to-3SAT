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

println("Debugging our function step by step...")

# Test with all nodes in one community
node_color_indices = [1, 1, 1]

# Let's manually trace through our function
n = nv(g)  # number of vertices

# Calculate total weight (2m) and weighted degrees
global total_weight = 0.0
global weighted_degrees = zeros(Float64, n)

# Get edge weights and calculate total weight and degrees
for edge in edges(g)
    i, j = src(edge), dst(edge)
    # Get the actual weight from edge_weights dictionary
    weight = get(edge_weights, (i, j), 1.0)
    
    global total_weight += weight
    global weighted_degrees[i] += weight
    global weighted_degrees[j] += weight
end

println("Total weight calculated by function: ", total_weight)
println("Weighted degrees: ", weighted_degrees)

# For undirected graphs, we've double-counted, so 2m = total_weight
two_m = total_weight
println("two_m used by function: ", two_m)

# Calculate modularity
global modularity = 0.0

println("\nIterating through all pairs:")
for i in 1:n
    for j in 1:n
        # Check if nodes i and j are in the same community
        if node_color_indices[i] == node_color_indices[j]
            # Get actual edge weight A_ij
            A_ij = 0.0
            if has_edge(g, i, j)
                # Get the actual weight from edge_weights dictionary
                A_ij = get(edge_weights, (i, j), 1.0)
            end
            
            # Expected weight under null model
            expected_weight = (weighted_degrees[i] * weighted_degrees[j]) / two_m
            
            # Contribution to modularity
            contribution = A_ij - expected_weight
            
            println("($i,$j): A_ij=$A_ij, expected=$expected_weight, contribution=$contribution")
            global modularity += contribution
        end
    end
end

println("Sum before normalization: ", modularity)

# Normalize by 2m
modularity = modularity / two_m
println("Final modularity: ", modularity)

println("\nFunction result: ", get_score(g, edge_weights, nothing, node_color_indices))
