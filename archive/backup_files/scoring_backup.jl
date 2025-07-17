#=
Modularity score function for weighted graphs,
entirely written by Copilot + Claude Sonnet
=#

function get_score(g, edge_weights, node_info, node_color_indices; debug=false)
    # Calculate modularity score for weighted graphs
    # Q = (1/2m) * Σ[A_ij - (k_i * k_j)/(2m)] * δ(c_i, c_j)

    # m = total weight on all edges 
    # A_ij = weight of edge connecting nodes i and j 
    # k_i = sum of weights connected to node i  
    # k_j = sum of weights connected to node j 
    # δ(c_i, c_j) = 1 if nodes i, j are in the same community (else 0)
    
    n = nv(g)  # number of vertices
    
    # Calculate total weight (2m) and weighted degrees
    total_weight = 0.0
    weighted_degrees = zeros(Float64, n)
    
    # Get edge weights and calculate total weight and degrees
    for edge in edges(g)
        i, j = src(edge), dst(edge)
        # Get the actual weight from edge_weights dictionary
        weight = get(edge_weights, (i, j), 1.0)
        
        total_weight += weight
        weighted_degrees[i] += weight
        weighted_degrees[j] += weight
    end
    
    # For undirected graphs, each edge contributes twice to the degree sum
    # So 2m = 2 * total_weight (since total_weight counts each edge once)
    two_m = 2 * total_weight
    
    # We iterate over ALL pairs (i,j), but we need to be careful about normalization
    modularity = 0.0
    
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
                modularity += contribution
            end
        end
    end
    
    # Normalize by 2m
    modularity = modularity / two_m
    
    return modularity
end