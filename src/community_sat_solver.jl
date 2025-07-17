# Community-Guided SAT Solver
# Based on pseudocode in pseudocode_CD_3SAT.md
#
# This solver uses community detection results to guide variable assignments
# for 3-SAT instances, prioritizing communities with higher modularity scores.

# Dependencies - include at the top
include("plot_graph.jl")  # For read_edges and build_graph functions

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
    community_sat_solve(formula, graph_data, communities)

Solve a 3-SAT instance using community detection guidance.

# Arguments
- `formula`: The 3-SAT formula (parsed from markdown)
- `graph_data`: Graph representation of the formula
- `communities`: Community detection results with modularity scores

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
function community_sat_solve(formula, graph_data, communities)
    println("🧠 Starting community-guided SAT solving...")
    
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
    
    println("📊 Node to literal mapping created: $(length(node_to_literal)) mappings")
    
    # Step 2: Use modularity to score each community separately
    println("🔍 Calculating modularity scores for communities...")
    community_scores = []
    
    for (idx, community) in enumerate(communities)
        modularity = calculate_community_modularity(graph_data, community)
        push!(community_scores, (modularity, idx, community))
        println("   Community $idx ($(length(community)) nodes): modularity = $(round(modularity, digits=4))")
    end
    
    # Step 3: Sort communities from high to low by modularity score
    sort!(community_scores, by=x->x[1], rev=true)
    println("📈 Communities sorted by modularity (highest first)")
    
    # Step 4: Loop through sorted communities
    for (modularity, comm_idx, community) in community_scores
        println("\n🎯 Processing community $comm_idx (modularity: $(round(modularity, digits=4)))")
        
        # Step 4a: Sort unassigned nodes in current community by total edge weight
        unassigned_nodes = [node for node in community if !(node in assigned_nodes)]
        
        if isempty(unassigned_nodes)
            println("   ⏭️  All nodes in community already assigned, skipping...")
            continue
        end
        
        node_weights = [(node, get_node_edge_weight(graph_data, node)) for node in unassigned_nodes]
        sort!(node_weights, by=x->x[2], rev=true)  # Sort by weight (highest first)
        
        println("   📊 Sorted $(length(node_weights)) unassigned nodes by edge weight")
        
        # Step 4b: Loop through sorted nodes
        for (node, weight) in node_weights
            if node in assigned_nodes
                continue  # Skip if already assigned
            end
            
            # Check if this node has a literal mapping
            if !haskey(node_to_literal, node)
                println("   ⚠️  Node $node has no literal mapping, skipping...")
                continue
            end
            
            literal = node_to_literal[node]
            println("   🎲 Processing node $node (literal: $literal, weight: $(round(weight, digits=2)))")
            
            # Step 4b.i: Assign current node to "true"
            if startswith(literal, "¬")
                # This is a negative literal ¬x_i, so setting it to true means x_i = false
                var_name = literal[nextind(literal, 1):end]  # Remove ¬ 
                assignment[var_name] = false
                println("      ✅ Assigned $var_name = false (satisfying $literal)")
            else
                # This is a positive literal x_i, so setting it to true means x_i = true
                assignment[literal] = true
                println("      ✅ Assigned $literal = true")
            end
            
            # Step 4b.ii: Assign its negation to "false" (no matter what community it is in)
            if startswith(literal, "¬")
                # Current literal is ¬x_i, its negation is x_i
                var_name = literal[nextind(literal, 1):end]
                pos_literal = var_name
                if haskey(literal_to_node, pos_literal)
                    neg_node = literal_to_node[pos_literal]
                    push!(assigned_nodes, neg_node)
                    println("      🚫 Marked positive literal $pos_literal (node $neg_node) as assigned")
                end
            else
                # Current literal is x_i, its negation is ¬x_i
                neg_literal = "¬$literal"
                if haskey(literal_to_node, neg_literal)
                    neg_node = literal_to_node[neg_literal]
                    push!(assigned_nodes, neg_node)
                    println("      🚫 Marked negative literal $neg_literal (node $neg_node) as assigned")
                end
            end
            
            # Mark current node as assigned
            push!(assigned_nodes, node)
        end
    end
    
    # Step 5: Check if resulting assignment satisfies the given Boolean formula
    println("\n🔍 Step 5: Evaluating final assignment...")
    println("📋 Final assignment: $assignment")
    
    satisfied = evaluate_assignment(formula, assignment)
    
    if satisfied
        println("✅ SUCCESS: Assignment satisfies the formula!")
    else
        println("❌ FAILURE: Assignment does not satisfy the formula")
    end
    
    return assignment, satisfied
end

"""
    parse_formula_from_markdown(markdown_file)

Parse a 3-SAT formula from a markdown file.

# Arguments
- `markdown_file`: Path to the markdown file containing the 3-SAT instance

# Returns
- Parsed formula structure suitable for evaluation
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
            clause = parse_clause_from_line(line)
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
    for (edge_pair, weight) in graph_data
        node1, node2 = edge_pair
        if node1 == node || node2 == node
            total_weight += weight
        end
    end
    
    return total_weight
end

# Dependencies - include at the top
include("plot_graph.jl")  # For read_edges and build_graph functions

"""
    test_community_sat_solver(markdown_file, graph_file)

Test function to verify the community-guided SAT solver works correctly.

# Arguments
- `markdown_file`: Path to a 3-SAT instance in markdown format
- `graph_file`: Path to the corresponding graph file

# Returns
- Nothing (prints results)
"""
function test_community_sat_solver(markdown_file, graph_file)
    println("🧪 Testing Community-Guided SAT Solver")
    println("="^50)
    
    # Parse the formula
    println("📖 Step 1: Parsing formula from $markdown_file")
    formula = parse_formula_from_markdown(markdown_file)
    println("   Variables: $(formula.num_variables)")
    println("   Clauses: $(length(formula.clauses))")
    
    # Load the graph
    println("\n📊 Step 2: Loading graph from $graph_file")
    edge_list = read_edges(graph_file)
    g, edge_weights = build_graph(edge_list)
    println("   Nodes: $(nv(g)), Edges: $(ne(g))")
    
    # Create dummy communities for testing (you can replace this with real community detection)
    # For now, just create 2 communities by splitting nodes roughly in half
    all_nodes = collect(1:nv(g))
    mid_point = div(length(all_nodes), 2)
    communities = [all_nodes[1:mid_point], all_nodes[mid_point+1:end]]
    
    println("\n🏘️  Step 3: Using dummy communities for testing")
    for (i, community) in enumerate(communities)
        println("   Community $i: $(length(community)) nodes")
    end
    
    # Run the solver
    println("\n🚀 Step 4: Running community-guided SAT solver")
    assignment, satisfied = community_sat_solve(formula, edge_weights, communities)
    
    # Results
    println("\n📋 RESULTS:")
    println("   Assignment: $assignment")
    println("   Satisfied: $satisfied")
    
    return assignment, satisfied
end

# Export main functions
export community_sat_solve, parse_formula_from_markdown, evaluate_assignment, test_community_sat_solver
