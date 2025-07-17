#=
Modularity score function for weighted graphs,
compatible with adjacency list representation
=#

function get_score(adj_list, communities, edge_weights)
    """
    Calculate modularity score for weighted graphs using adjacency list.
    
    Q = (1/2m) * Σ[A_ij - (k_i * k_j)/(2m)] * δ(c_i, c_j)
    
    Args:
        adj_list: Dict mapping node -> list of neighbors
        communities: Vector of vectors, each inner vector is a community
        edge_weights: Dict mapping (node1, node2) -> weight
    
    Returns:
        Float64: Modularity score
    """
    
    # Get all nodes
    all_nodes = collect(keys(adj_list))
    n = length(all_nodes)
    
    # Create community mapping: node -> community_index
    node_to_community = Dict{Int, Int}()
    for (comm_idx, community) in enumerate(communities)
        for node in community
            node_to_community[node] = comm_idx
        end
    end
    
    # Calculate total weight (2m) and weighted degrees
    total_weight = 0.0
    weighted_degrees = Dict{Int, Float64}()
    
    # Initialize degrees
    for node in all_nodes
        weighted_degrees[node] = 0.0
    end
    
    # Calculate degrees and total weight
    edges_seen = Set{Tuple{Int, Int}}()
    for node in all_nodes
        for neighbor in adj_list[node]
            # Avoid double counting edges
            edge_key = node < neighbor ? (node, neighbor) : (neighbor, node)
            if edge_key in edges_seen
                continue
            end
            push!(edges_seen, edge_key)
            
            # Get weight
            weight = get(edge_weights, (node, neighbor), 1.0)
            
            # Add to total weight and node degrees
            total_weight += weight
            weighted_degrees[node] += weight
            weighted_degrees[neighbor] += weight
        end
    end
    
    # For undirected graphs, 2m = total_weight
    two_m = total_weight
    
    if two_m == 0.0
        return 0.0  # No edges, modularity is 0
    end
    
    # Calculate modularity
    modularity = 0.0
    
    for i in all_nodes
        for j in all_nodes
            # Check if nodes i and j are in the same community
            comm_i = get(node_to_community, i, -1)
            comm_j = get(node_to_community, j, -1)
            
            if comm_i == comm_j && comm_i != -1
                # Get actual edge weight A_ij
                A_ij = 0.0
                if j in adj_list[i]
                    A_ij = get(edge_weights, (i, j), 1.0)
                end
                
                # Expected weight under null model
                expected_weight = (weighted_degrees[i] * weighted_degrees[j]) / two_m
                
                # Add contribution to modularity
                modularity += (A_ij - expected_weight)
            end
        end
    end
    
    # Normalize by 2m
    modularity = modularity / two_m
    
    return modularity
end
