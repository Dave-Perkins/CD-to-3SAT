#=
Standard modularity implementation for comparison
=#

function get_score_standard(g, edge_weights, node_info, node_color_indices)
    # Standard modularity: sum over ALL pairs (i,j)
    # Q = (1/2m) * Σ[A_ij - (k_i * k_j)/(2m)] * δ(c_i, c_j)
    
    n = nv(g)
    
    # Calculate total weight (2m) and weighted degrees
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
    
    # Standard approach: iterate over ALL pairs (i,j)
    modularity = 0.0
    
    for i in 1:n
        for j in 1:n  # ALL pairs, not just upper triangle
            if node_color_indices[i] == node_color_indices[j]
                # Get actual edge weight A_ij
                A_ij = 0.0
                if has_edge(g, i, j)
                    A_ij = get(edge_weights, (i, j), 1.0)
                end
                
                # Expected weight under null model
                expected_weight = (weighted_degrees[i] * weighted_degrees[j]) / two_m
                
                # Add contribution
                modularity += (A_ij - expected_weight)
            end
        end
    end
    
    # Normalize by 2m
    modularity = modularity / two_m
    
    return modularity
end
