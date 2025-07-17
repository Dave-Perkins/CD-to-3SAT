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
    
    if debug
        println("=== MODULARITY CALCULATION DEBUG ===")
        println("Graph has $n nodes")
        println("Edge weights dictionary: $edge_weights")
        println("Community assignments: $node_color_indices")
        println()
    end
    
    # Calculate total weight (2m) and weighted degrees
    total_weight = 0.0
    weighted_degrees = zeros(Float64, n)
    
    # Get edge weights and calculate total weight and degrees
    if debug
        println("--- Edge Weight Calculation ---")
    end
    
    for edge in edges(g)
        i, j = src(edge), dst(edge)
        # Get the actual weight from edge_weights dictionary
        weight = get(edge_weights, (i, j), 1.0)
        
        if debug
            println("Edge ($i,$j): weight = $weight")
        end
        
        total_weight += weight
        weighted_degrees[i] += weight
        weighted_degrees[j] += weight
    end
    
    # For undirected graphs, each edge contributes twice to the degree sum
    # So 2m = 2 * total_weight (since total_weight counts each edge once)
    two_m = 2 * total_weight
    
    if debug
        println("Total weight (m): $total_weight")
        println("Two_m (2m): $two_m")
        println("Weighted degrees: $weighted_degrees")
        println()
    end
    
    # We iterate over ALL pairs (i,j), but we need to be careful about normalization
    modularity = 0.0
    
    if debug
        println("--- Modularity Contribution Calculation ---")
    end
    
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
                
                if debug && (A_ij > 0 || abs(contribution) > 1e-6)
                    println("Nodes ($i,$j) in same community ($(node_color_indices[i])):")
                    println("  A_ij = $A_ij")
                    println("  Expected = $(weighted_degrees[i]) × $(weighted_degrees[j]) / $two_m = $expected_weight")
                    println("  Contribution = $A_ij - $expected_weight = $contribution")
                    println("  Running modularity = $modularity")
                    println()
                end
            end
        end
    end
    
    if debug
        println("--- Final Calculation ---")
        println("Raw modularity sum: $modularity")
        println("Normalizing by 2m: $modularity / $two_m")
    end
    
    # Normalize by 2m
    modularity = modularity / two_m
    
    if debug
        println("Final modularity score: $modularity")
        println("=== END DEBUG ===")
        println()
    end
    
    return modularity
end
