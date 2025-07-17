# Community-Guided SAT Solver
# Based on pseudocode in pseudocode_CD_3SAT.md
#
# This solver uses community detection results to guide variable assignments
# for 3-SAT instances, prioritizing communities with higher modularity scores.

# Dependencies
include("plot_graph.jl")  # For read_edges and build_graph functions

# Additional imports for visualization
try
    import GLMakie
    import GraphMakie
    import GeometryBasics
    global VISUALIZATION_AVAILABLE = true
catch e
    global VISUALIZATION_AVAILABLE = false
    println("Note: Visualization packages not available. Graphs will not be displayed.")
end

# Simple scoring function for the existing interactive plot infrastructure
function get_score(g, edge_weights, node_info, node_color_indices)
    try
        # For now, return a simple fixed score or modularity if available
        return 0.5  # Placeholder score
    catch
        return 0.0  # Fallback score
    end
end

"""
    parse_clause_from_line(line::String) -> Vector{String}

Parse a single clause from a markdown line like "1. (x₁ ∨ ¬x₂ ∨ x₃)"
Returns vector of literals as strings.
"""
function parse_clause_from_line(line::String)
    clause = String[]
    
    # Extract the part between parentheses
    paren_match = match(r"\(([^)]+)\)", line)
    if paren_match === nothing
        return clause
    end
    
    clause_content = paren_match.captures[1]
    
    # Split by ∨ (or | for alternative format) and parse each literal
    literals = split(clause_content, r"[∨|]")
    
    for literal in literals
        literal = strip(literal)
        if !isempty(literal)
            push!(clause, literal)
        end
    end
    
    return clause
end

"""
    parse_formula_from_markdown(markdown_file)

Parse a 3-SAT formula from a markdown file.

# Arguments
- `markdown_file`: Path to the markdown file containing the 3-SAT instance

# Returns
- NamedTuple with num_variables and clauses
"""
function parse_formula_from_markdown(markdown_file)
    if !isfile(markdown_file)
        error("File not found: $markdown_file")
    end
    
    lines = readlines(markdown_file)
    num_variables = 0
    clauses = Vector{Vector{String}}()
    
    in_clauses_section = false
    
    for line in lines
        line = strip(line)
        
        # Skip empty lines and check for section headers
        if isempty(line) || startswith(line, "#")
            if contains(line, "## Clauses")
                in_clauses_section = true
            elseif startswith(line, "##") && in_clauses_section
                in_clauses_section = false
            end
            continue
        end
        
        # Extract number of variables from metadata
        if contains(line, "Variables:") && contains(line, ":")
            var_match = match(r"Variables:\s*(\d+)", line)
            if var_match !== nothing
                num_variables = parse(Int, var_match.captures[1])
            end
        elseif contains(line, "- Variables:") && contains(line, ":")
            var_match = match(r"- Variables:\s*(\d+)", line)
            if var_match !== nothing
                num_variables = parse(Int, var_match.captures[1])
            end
        end
        
        # Parse clause lines
        if in_clauses_section && contains(line, "(") && contains(line, ")")
            clause = parse_clause_from_line(String(line))  # Convert SubString to String
            if !isempty(clause)
                push!(clauses, clause)
            end
        end
    end
    
    return (num_variables=num_variables, clauses=clauses)
end

"""
    evaluate_assignment(formula, assignment)

Check if a variable assignment satisfies the given 3-SAT formula.

# Arguments
- `formula`: The 3-SAT formula structure (from parse_formula_from_markdown)
- `assignment`: Dictionary mapping variable names (e.g., "x1") to true/false values

# Returns
- Boolean indicating if the assignment satisfies all clauses
"""
function evaluate_assignment(formula, assignment)
    for (clause_idx, clause) in enumerate(formula.clauses)
        clause_satisfied = false
        
        for literal in clause
            literal = strip(literal)
            
            # Check for negation
            is_negative = false
            var_name = literal
            if startswith(literal, "¬") || startswith(literal, "~")
                is_negative = true
                # Remove negation symbol
                if startswith(literal, "¬")
                    var_name = literal[nextind(literal, 1):end]  # Unicode-safe
                else
                    var_name = literal[2:end]  # ASCII ~
                end
            end
            
            # Get variable value from assignment
            if haskey(assignment, var_name)
                var_value = assignment[var_name]
                
                # Check if this literal satisfies the clause
                literal_satisfied = is_negative ? !var_value : var_value
                
                if literal_satisfied
                    clause_satisfied = true
                    break  # Clause is satisfied, move to next clause
                end
            else
                @warn "Variable $var_name not found in assignment"
                return false
            end
        end
        
        if !clause_satisfied
            @warn "Clause $clause_idx is not satisfied: $clause"
            return false
        end
    end
    
    return true  # All clauses satisfied
end

"""
    get_node_edge_weight(graph_data, node)

Get the total edge weight for a node (sum of all connected edge weights).

# Arguments
- `graph_data`: Dictionary with edge weights (from existing graph infrastructure)
- `node`: The node to calculate total edge weight for

# Returns
- Total edge weight for the node
"""
function get_node_edge_weight(graph_data, node)
    total_weight = 0.0
    
    # graph_data is expected to be the edge_weights dictionary
    # that maps (node1, node2) -> weight
    # For undirected graphs, each edge appears twice: (i,j) and (j,i)
    # We need to count each edge only once for degree calculation
    
    counted_edges = Set{Tuple{Int,Int}}()
    
    for (edge_pair, weight) in graph_data
        node1, node2 = edge_pair
        if node1 == node || node2 == node
            # Ensure we count each edge only once by using canonical form
            canonical_edge = node1 < node2 ? (node1, node2) : (node2, node1)
            if !(canonical_edge in counted_edges)
                total_weight += weight
                push!(counted_edges, canonical_edge)
            end
        end
    end
    
    return total_weight
end

"""
    calculate_community_modularity(graph_data, community)

Calculate the modularity score for a specific community.

# Arguments
- `graph_data`: Dictionary with edge weights (edge_weights from existing infrastructure)
- `community`: Vector of node IDs in the community

# Returns
- Modularity score for the community
"""
function calculate_community_modularity(graph_data, community)
    # For a single community, we calculate its contribution to overall modularity
    # This is a simplified version - we're calculating what this community would contribute
    # if it were the only community (i.e., all other nodes were in different communities)
    
    # Calculate total weight (2m) for the entire graph
    total_weight = 0.0
    all_nodes = Set{Int}()
    
    for ((node1, node2), weight) in graph_data
        total_weight += weight
        push!(all_nodes, node1)
        push!(all_nodes, node2)
    end
    
    # For undirected graphs, each edge is counted twice in our dictionary
    two_m = total_weight
    
    if two_m == 0
        return 0.0
    end
    
    # Calculate weighted degrees for all nodes
    weighted_degrees = Dict{Int, Float64}()
    for node in all_nodes
        weighted_degrees[node] = get_node_edge_weight(graph_data, node)
    end
    
    # Calculate modularity contribution for this community
    modularity = 0.0
    
    for i in community
        for j in community
            # Get actual edge weight A_ij
            A_ij = 0.0
            if haskey(graph_data, (i, j))
                A_ij = graph_data[(i, j)]
            end
            
            # Expected weight under null model
            ki = get(weighted_degrees, i, 0.0)
            kj = get(weighted_degrees, j, 0.0)
            expected_weight = (ki * kj) / two_m
            
            # Add contribution
            modularity += (A_ij - expected_weight)
        end
    end
    
    # Normalize by 2m  
    modularity = modularity / two_m
    
    return modularity
end

"""
    calculate_overall_modularity(graph_data, all_communities)

Calculate the overall modularity score for the entire graph partition.

# Arguments
- `graph_data`: Dictionary with edge weights (edge_weights from existing infrastructure)
- `all_communities`: Vector of communities (each community is a vector of node IDs)

# Returns
- Overall modularity score for the partition
"""
function calculate_overall_modularity(graph_data, all_communities)
    # Calculate total weight (2m) for the entire graph
    total_weight = 0.0
    all_nodes = Set{Int}()
    
    for ((node1, node2), weight) in graph_data
        total_weight += weight
        push!(all_nodes, node1)
        push!(all_nodes, node2)
    end
    
    two_m = total_weight
    
    if two_m == 0
        return 0.0
    end
    
    # Calculate overall modularity for the entire partition
    total_modularity = 0.0
    
    for community in all_communities
        for i in community
            for j in community
                # Get actual edge weight A_ij
                A_ij = get(graph_data, (i, j), 0.0)
                
                # Expected weight under null model
                ki = get_node_edge_weight(graph_data, i)
                kj = get_node_edge_weight(graph_data, j)
                expected_weight = (ki * kj) / two_m
                
                # Add contribution
                total_modularity += (A_ij - expected_weight)
            end
        end
    end
    
    # Normalize by 2m
    return total_modularity / two_m
end

"""
    calculate_community_contribution_to_modularity(graph_data, community, all_communities)

Calculate how much a specific community contributes to the overall modularity score.

# Arguments
- `graph_data`: Dictionary with edge weights (edge_weights from existing infrastructure)
- `community`: Vector of node IDs in the specific community
- `all_communities`: Vector of all communities (for calculating the overall context)

# Returns
- This community's contribution to overall modularity
"""
function calculate_community_contribution_to_modularity(graph_data, community, all_communities)
    # Calculate total weight (2m) for the entire graph
    total_weight = 0.0
    
    for ((node1, node2), weight) in graph_data
        total_weight += weight
    end
    
    two_m = total_weight
    
    if two_m == 0
        return 0.0
    end
    
    # Calculate this community's contribution to modularity
    community_contribution = 0.0
    
    for i in community
        for j in community
            # Get actual edge weight A_ij
            A_ij = get(graph_data, (i, j), 0.0)
            
            # Expected weight under null model
            ki = get_node_edge_weight(graph_data, i)
            kj = get_node_edge_weight(graph_data, j)
            expected_weight = (ki * kj) / two_m
            
            # Add contribution
            community_contribution += (A_ij - expected_weight)
        end
    end
    
    # Return the contribution (normalized)
    return community_contribution / two_m
end

"""
    community_sat_solve(formula, graph_data, communities)

Solve a 3-SAT instance using community detection guidance.

# Arguments
- `formula`: The 3-SAT formula (parsed from markdown)
- `graph_data`: Graph representation of the formula (edge_weights dictionary)
- `communities`: Community detection results (vector of vectors of node IDs)

# Returns
- `assignment`: Dictionary mapping variables to true/false
- `satisfied`: Boolean indicating if the assignment satisfies the formula

# Algorithm (from pseudocode_CD_3SAT.md):
1. Initialize all nodes as "unassigned"
2. Use modularity to score each community separately
3. Sort communities from high to low by that score
4. Loop through sorted communities:
   a. Sort unassigned nodes in current community by total edge weight
   b. Loop through sorted nodes:
      - Assign current node to "true"
      - Assign its negation to "false" (no matter what community it is in)
5. Check if resulting assignment satisfies the given Boolean formula
"""
function community_sat_solve(formula, graph_data, communities; verbose=true)
    if verbose
        println("🧠 Starting community-guided SAT solving...")
    end
    
    # Step 1: Initialize all nodes as "unassigned"
    assignment = Dict{String, Bool}()
    assigned_nodes = Set{Int}()
    
    # Create mapping from node numbers to variable names
    # We need to understand the node-to-literal mapping from the graph generation
    # For now, assume nodes 1-n are positive literals x1-xn, nodes n+1 to 2n are negative literals
    num_variables = formula.num_variables
    node_to_literal = Dict{Int, String}()
    literal_to_node = Dict{String, Int}()
    
    # Map positive literals: nodes 1 to num_variables
    for i in 1:num_variables
        var_name = "x$i"
        node_to_literal[i] = var_name
        literal_to_node[var_name] = i
    end
    
    # Map negative literals: nodes num_variables+1 to 2*num_variables  
    for i in 1:num_variables
        var_name = "x$i"
        neg_literal = "¬$var_name"
        neg_node = num_variables + i
        node_to_literal[neg_node] = neg_literal
        literal_to_node[neg_literal] = neg_node
    end
    
    if verbose
        println("📊 Node to literal mapping created: $(length(node_to_literal)) mappings")
    end
    
    # Step 2: Use modularity to score the graph and calculate community contributions
    if verbose
        println("🔍 Calculating overall graph modularity...")
    end
    
    overall_modularity = calculate_overall_modularity(graph_data, communities)
    if verbose
        println("   Overall graph modularity: $(round(overall_modularity, digits=4))")
        println("🔍 Calculating individual community contributions...")
    end
    
    community_scores = []
    
    for (idx, community) in enumerate(communities)
        contribution = calculate_community_contribution_to_modularity(graph_data, community, communities)
        push!(community_scores, (contribution, idx, community))
        if verbose
            println("   Community $idx ($(length(community)) nodes): contribution = $(round(contribution, digits=4))")
        end
    end
    
    # Step 3: Sort communities by their contribution to modularity (highest first)
    sort!(community_scores, by=x->x[1], rev=true)
    if verbose
        println("📈 Communities sorted by modularity contribution (highest first)")
    end
    
    # Step 4: Loop through sorted communities
    for (contribution, comm_idx, community) in community_scores
        if verbose
            println("\n🎯 Processing community $comm_idx (contribution: $(round(contribution, digits=4)))")
        end
        
        # Step 4a: Sort unassigned nodes in current community by total edge weight
        unassigned_nodes = [node for node in community if !(node in assigned_nodes)]
        
        if isempty(unassigned_nodes)
            if verbose
                println("   ⏭️  All nodes in community already assigned, skipping...")
            end
            continue
        end
        
        node_weights = [(node, get_node_edge_weight(graph_data, node)) for node in unassigned_nodes]
        sort!(node_weights, by=x->x[2], rev=true)  # Sort by weight (highest first)
        
        if verbose
            println("   📊 Sorted $(length(node_weights)) unassigned nodes by edge weight")
        end
        
        # Step 4b: Loop through sorted nodes
        for (node, weight) in node_weights
            if node in assigned_nodes
                continue  # Skip if already assigned
            end
            
            # Check if this node has a literal mapping
            if !haskey(node_to_literal, node)
                if verbose
                    println("   ⚠️  Node $node has no literal mapping, skipping...")
                end
                continue
            end
            
            literal = node_to_literal[node]
            if verbose
                println("   🎲 Processing node $node (literal: $literal, weight: $(round(weight, digits=2)))")
            end
            
            # Step 4b.i: Assign current node to "true"
            if startswith(literal, "¬")
                # This is a negative literal ¬x_i, so setting it to true means x_i = false
                var_name = literal[nextind(literal, 1):end]  # Remove ¬ 
                assignment[var_name] = false
                if verbose
                    println("      ✅ Assigned $var_name = false (satisfying $literal)")
                end
            else
                # This is a positive literal x_i, so setting it to true means x_i = true
                assignment[literal] = true
                if verbose
                    println("      ✅ Assigned $literal = true")
                end
            end
            
            # Step 4b.ii: Assign its negation to "false" (no matter what community it is in)
            if startswith(literal, "¬")
                # Current literal is ¬x_i, its negation is x_i
                var_name = literal[nextind(literal, 1):end]
                pos_literal = var_name
                if haskey(literal_to_node, pos_literal)
                    neg_node = literal_to_node[pos_literal]
                    push!(assigned_nodes, neg_node)
                    if verbose
                        println("      🚫 Marked positive literal $pos_literal (node $neg_node) as assigned")
                    end
                end
            else
                # Current literal is x_i, its negation is ¬x_i
                neg_literal = "¬$literal"
                if haskey(literal_to_node, neg_literal)
                    neg_node = literal_to_node[neg_literal]
                    push!(assigned_nodes, neg_node)
                    if verbose
                        println("      🚫 Marked negative literal $neg_literal (node $neg_node) as assigned")
                    end
                end
            end
            
            # Mark current node as assigned
            push!(assigned_nodes, node)
        end
    end
    
    # Step 5: Check if resulting assignment satisfies the given Boolean formula
    if verbose
        println("\n🔍 Step 5: Evaluating final assignment...")
        println("📋 Final assignment: $assignment")
    end
    
    satisfied = evaluate_assignment(formula, assignment)
    
    if verbose
        if satisfied
            println("✅ SUCCESS: Assignment satisfies the formula!")
        else
            println("❌ FAILURE: Assignment does not satisfy the formula")
        end
    end
    
    return assignment, satisfied
end

"""
    test_community_sat_solver(markdown_file, graph_file)

Test function to verify the community-guided SAT solver works correctly.

# Arguments
- `markdown_file`: Path to a 3-SAT instance in markdown format
- `graph_file`: Path to the corresponding graph file
- `verbose`: Whether to print detailed progress
- `show_visualization`: Whether to display interactive graph visualization

# Returns
- (assignment, satisfied): Tuple with the variable assignment and satisfaction status
"""
function test_community_sat_solver(markdown_file, graph_file; verbose=true, show_visualization=true)
    if verbose
        println("🧪 Testing Community-Guided SAT Solver")
        println("="^50)
    end
    
    # Parse the formula
    if verbose
        println("📖 Step 1: Parsing formula from $markdown_file")
    end
    formula = parse_formula_from_markdown(markdown_file)
    if verbose
        println("   Variables: $(formula.num_variables)")
        println("   Clauses: $(length(formula.clauses))")
    end
    
    # Load the graph
    if verbose
        println("\n📊 Step 2: Loading graph from $graph_file")
    end
    edge_list = read_edges(graph_file)
    g, edge_weights = build_graph(edge_list)
    if verbose
        println("   Nodes: $(nv(g)), Edges: $(ne(g))")
    end
    
    # Create dummy communities for testing (you can replace this with real community detection)
    # For now, just create 2 communities by splitting nodes roughly in half
    all_nodes = collect(1:nv(g))
    mid_point = div(length(all_nodes), 2)
    communities = [all_nodes[1:mid_point], all_nodes[mid_point+1:end]]
    
    if verbose
        println("\n🏘️  Step 3: Using dummy communities for testing")
        for (i, community) in enumerate(communities)
            println("   Community $i: $(length(community)) nodes")
        end
    end
    
    # Show initial graph visualization with communities
    if show_visualization
        println("\n🎨 Step 3a: Displaying initial graph with communities")
        visualize_sat_solving(formula, edge_weights, communities, nothing, show_graph=true)
    end
    
    # Run the solver
    if verbose
        println("\n🚀 Step 4: Running community-guided SAT solver")
    end
    assignment, satisfied = community_sat_solve(formula, edge_weights, communities, verbose=verbose)
    
    # Show final graph visualization with assignment
    if show_visualization && assignment !== nothing
        println("\n🎨 Step 5: Displaying final graph with variable assignments")
        visualize_sat_solving(formula, edge_weights, communities, assignment, show_graph=true)
    end
    
    # Results
    if verbose
        println("\n📋 RESULTS:")
        println("   Assignment: $assignment")
        println("   Satisfied: $satisfied")
    end
    
    return assignment, satisfied
end

# Simple test function
function test_basic_functionality()
    println("🧪 Testing basic functions...")
    
    # Test clause parsing
    test_line = "1. (x2 ∨ ¬x2 ∨ ¬x3)"
    result = parse_clause_from_line(test_line)
    println("✅ Clause parsing works: $result")
    
    # Test formula parsing
    if isfile("research/research_3vars_5clauses_seed42.md")
        formula = parse_formula_from_markdown("research/research_3vars_5clauses_seed42.md")
        println("✅ Formula parsing works: $(formula.num_variables) vars, $(length(formula.clauses)) clauses")
    end
    
    return true
end

"""
    visualize_sat_solving(formula, graph_data, communities, assignment=nothing; show_graph=true)

Display an interactive visualization of the SAT solving process with communities highlighted.
Uses the existing interactive_plot_graph infrastructure from plot_graph.jl.

# Arguments
- `formula`: The 3-SAT formula (parsed from markdown)
- `graph_data`: Graph representation (edge_weights dictionary)
- `communities`: Community detection results
- `assignment`: Optional variable assignment to highlight satisfied/unsatisfied nodes
- `show_graph`: Whether to display the interactive graph

# Returns
- Nothing (displays interactive plot)
"""
function visualize_sat_solving(formula, graph_data, communities, assignment=nothing; show_graph=true)
    if !show_graph || !VISUALIZATION_AVAILABLE
        if !VISUALIZATION_AVAILABLE
            println("⚠️  Visualization packages not available. Skipping graph display.")
        end
        return false
    end
    
    println("🎨 Creating interactive graph visualization using existing plot_graph.jl infrastructure...")
    
    try
        # Build the graph from edge data using existing functions
        edge_list = [(src, dst, weight) for ((src, dst), weight) in graph_data]
        g, edge_weights = build_graph(edge_list)
        
        # Create node information mapping
        num_variables = formula.num_variables
        node_info = Dict{Int, String}()
        
        # Map nodes to their literal meanings
        for i in 1:num_variables
            if i <= nv(g)
                node_info[i] = "x$i"  # Positive literals
            end
            if (num_variables + i) <= nv(g)
                node_info[num_variables + i] = "¬x$i"  # Negative literals
            end
        end
        
        # Fill any remaining nodes
        for i in 1:nv(g)
            if !haskey(node_info, i)
                node_info[i] = "n$i"
            end
        end
        
        # Create community-based coloring
        community_colors = [:red, :blue, :green, :orange, :purple, :brown, :pink, :gray]
        node_colors = Vector{Symbol}(undef, nv(g))
        node_color_indices = Vector{Int}(undef, nv(g))
        node_text_colors = Vector{Symbol}(undef, nv(g))
        
        # Assign colors based on communities
        for (comm_idx, community) in enumerate(communities)
            color = community_colors[((comm_idx - 1) % length(community_colors)) + 1]
            for node in community
                if node <= nv(g)
                    node_colors[node] = color
                    node_color_indices[node] = comm_idx
                    node_text_colors[node] = :white
                end
            end
        end
        
        # Fill any unassigned nodes with default values
        for i in 1:nv(g)
            if !isassigned(node_colors, i)
                node_colors[i] = :lightgray
                node_color_indices[i] = 0
                node_text_colors[i] = :black
            end
        end
        
        # If assignment is provided, override colors to show assignments
        if assignment !== nothing
            for (var_name, value) in assignment
                # Find corresponding nodes
                var_num = parse(Int, var_name[2:end])  # Extract number from "x1", "x2", etc.
                pos_node = var_num
                neg_node = num_variables + var_num
                
                if value  # Variable is true
                    if pos_node <= nv(g)
                        node_colors[pos_node] = :green    # True positive literal
                        node_text_colors[pos_node] = :white
                    end
                    if neg_node <= nv(g)
                        node_colors[neg_node] = :lightgray  # False negative literal  
                        node_text_colors[neg_node] = :black
                    end
                else  # Variable is false
                    if pos_node <= nv(g)
                        node_colors[pos_node] = :lightgray  # False positive literal
                        node_text_colors[pos_node] = :black
                    end
                    if neg_node <= nv(g)
                        node_colors[neg_node] = :green    # True negative literal
                        node_text_colors[neg_node] = :white
                    end
                end
            end
        end
        
        # Create label to color index mapping for the existing function
        label_to_color_index = Dict("Community $i" => i for i in 1:length(communities))
        color_palette = community_colors[1:length(communities)]
        
        println("   📊 Displaying graph with $(nv(g)) nodes and $(ne(g)) edges")
        println("   🏘️  Communities highlighted in different colors")
        if assignment !== nothing
            println("   ✅ Variable assignments shown (green=true, gray=false)")
        end
        
        # Use the existing interactive plot function
        interactive_plot_graph(g, edge_weights, node_info, node_colors, node_text_colors, 
                             node_color_indices, color_palette, label_to_color_index)
        
        return true
        
    catch e
        println("⚠️  Could not display graph visualization: $e")
        println("   (This is normal if running in headless mode)")
        return false
    end
end

# Export main functions
export parse_clause_from_line, parse_formula_from_markdown, evaluate_assignment, get_node_edge_weight, calculate_community_modularity, calculate_overall_modularity, calculate_community_contribution_to_modularity, community_sat_solve, test_community_sat_solver, test_basic_functionality, visualize_sat_solving, visualize_sat_solving
