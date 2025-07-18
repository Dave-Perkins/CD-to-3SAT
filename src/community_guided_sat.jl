"""
Community-Guided SAT Solving Module

Implements the community detection guided SAT solving algorithm as described in pseudocode_CD_3SAT.md.
Uses community structure from graph analysis to guide variable assignments for 3-SAT instances.
"""

using Random
using Graphs

include("sat3_markdown_generator.jl")
include("plot_graph.jl")
include("scoring.jl")

# Include mini03 for NodeInfo and label_propagation
include("mini03.jl")

# Include SAT solver for parsing functions
try
    include("sat_solver.jl")
catch e
    println("Warning: Could not load sat_solver.jl - some functions may not be available")
end

"""
    parse_3sat_instance_from_markdown(filename::String)

Parse a 3-SAT instance from markdown format and return a SAT3Instance structure.
"""
function parse_3sat_instance_from_markdown(filename::String)
    if !isfile(filename)
        error("File not found: $filename")
    end
    
    lines = readlines(filename)
    variables = String[]
    clauses = Vector{String}[]
    metadata = Dict{String, Any}()
    
    in_variables_section = false
    in_clauses_section = false
    in_metadata_section = false
    
    for line in lines
        line = strip(line)
        if isempty(line) || startswith(line, "#")
            # Check for section headers
            if contains(line, "## Variables")
                in_variables_section = true
                in_clauses_section = false
                in_metadata_section = false
            elseif contains(line, "## Clauses")
                in_variables_section = false
                in_clauses_section = true
                in_metadata_section = false
            elseif contains(line, "## Metadata")
                in_variables_section = false
                in_clauses_section = false
                in_metadata_section = true
            elseif startswith(line, "##")
                in_variables_section = false
                in_clauses_section = false
                in_metadata_section = false
            end
            continue
        end
        
        if in_variables_section && startswith(line, "-")
            # Parse variables: "- x1, x2, x3" or "- x1"
            var_text = strip(line[2:end])  # Remove "- "
            if contains(var_text, ",")
                vars = [strip(v) for v in split(var_text, ",")]
                append!(variables, vars)
            else
                push!(variables, var_text)
            end
        elseif in_clauses_section && match(r"^\d+\.", line) !== nothing
            # Parse clause: "1. (x₁ ∨ ¬x₂ ∨ x₃)"
            clause_match = match(r"^\d+\.\s*\((.*)\)", line)
            if clause_match !== nothing
                clause_text = clause_match.captures[1]
                # Split by ∨ and clean up
                literals = [strip(lit) for lit in split(clause_text, "∨")]
                # Convert subscripts to regular notation
                literals = [replace_subscripts(String(lit)) for lit in literals]
                push!(clauses, literals)
            end
        elseif in_metadata_section && contains(line, ":")
            # Parse metadata: "- Variables: 4"
            if startswith(line, "-")
                meta_text = strip(line[2:end])
                parts = split(meta_text, ":")
                if length(parts) == 2
                    key = strip(parts[1])
                    value = strip(parts[2])
                    # Try to parse as number
                    if occursin(r"^\d+$", value)
                        metadata[key] = parse(Int, value)
                    elseif occursin(r"^\d+\.\d+$", value)
                        metadata[key] = parse(Float64, value)
                    else
                        metadata[key] = value
                    end
                end
            end
        end
    end
    
    return SAT3Instance(variables, clauses, metadata)
end

"""
    replace_subscripts(text::String)

Convert subscripted variables (x₁, x₂) to regular notation (x1, x2).
"""
function replace_subscripts(text::String)
    subscript_map = Dict(
        '₀' => '0', '₁' => '1', '₂' => '2', '₃' => '3', '₄' => '4',
        '₅' => '5', '₆' => '6', '₇' => '7', '₈' => '8', '₉' => '9'
    )
    
    result = text
    for (sub, reg) in subscript_map
        result = replace(result, sub => reg)
    end
    return result
end

"""
    CommunityGuidedResult

Structure to hold results from community-guided SAT solving.
"""
struct CommunityGuidedResult
    assignment::Dict{String, Bool}
    satisfiable::Bool
    communities::Vector{Vector{Int}}
    modularity_score::Float64
    assignment_strategy::Vector{String}
    solve_time::Float64
    traditional_sat_result::Union{Nothing, Any}
    assignment_quality::Union{Nothing, NamedTuple}
end

"""
    find_violated_clauses(instance, assignment)

Find all clauses that are not satisfied by the current assignment.
"""
function find_violated_clauses(instance, assignment)
    violated_clauses = []
    
    for (i, clause) in enumerate(instance.clauses)
        clause_satisfied = false
        
        for literal in clause
            var_name = get_variable_name(literal)
            var_value = get(assignment, var_name, false)
            literal_satisfied = is_negated(literal) ? !var_value : var_value
            
            if literal_satisfied
                clause_satisfied = true
                break
            end
        end
        
        if !clause_satisfied
            push!(violated_clauses, (clause_id=i, clause=clause))
        end
    end
    
    return violated_clauses
end

"""
    count_variable_violations(violated_clauses)

Count how many violated clauses each variable appears in.
"""
function count_variable_violations(violated_clauses)
    violation_count = Dict{String, Int}()
    
    for violated_clause in violated_clauses
        for literal in violated_clause.clause
            var_name = get_variable_name(literal)
            violation_count[var_name] = get(violation_count, var_name, 0) + 1
        end
    end
    
    return violation_count
end

"""
    calculate_flip_benefit(instance, assignment, variable)

Calculate the net benefit of flipping a variable (clauses satisfied - clauses broken).
"""
function calculate_flip_benefit(instance, assignment, variable)
    current_value = assignment[variable]
    test_assignment = copy(assignment)
    test_assignment[variable] = !current_value
    
    # Count satisfied clauses before and after flip
    before_satisfied = count_satisfied_clauses(instance, assignment)
    after_satisfied = count_satisfied_clauses(instance, test_assignment)
    
    return after_satisfied - before_satisfied
end

"""
    count_satisfied_clauses(instance, assignment)

Count the total number of satisfied clauses in the instance.
"""
function count_satisfied_clauses(instance, assignment)
    satisfied_count = 0
    
    for clause in instance.clauses
        for literal in clause
            var_name = get_variable_name(literal)
            var_value = get(assignment, var_name, false)
            literal_satisfied = is_negated(literal) ? !var_value : var_value
            
            if literal_satisfied
                satisfied_count += 1
                break  # Clause is satisfied, move to next
            end
        end
    end
    
    return satisfied_count
end

"""
    greedy_violation_repair(instance, assignment, verbose, max_flips=5)

Apply greedy violation repair heuristic to try to satisfy violated clauses.
Targets variables that appear most frequently in violated clauses.
"""
function greedy_violation_repair(instance, assignment, verbose=false, max_flips=5)
    repaired_assignment = copy(assignment)
    flips_made = 0
    
    for flip_round in 1:max_flips
        violated_clauses = find_violated_clauses(instance, repaired_assignment)
        
        if isempty(violated_clauses)
            if verbose
                println("     • All clauses satisfied after $flips_made flips!")
            end
            break
        end
        
        # Count variable frequency in violated clauses
        violation_freq = count_variable_violations(violated_clauses)
        
        if isempty(violation_freq)
            break
        end
        
        # Find variable that appears in most violated clauses
        best_var = ""
        max_violations = 0
        for (var, count) in violation_freq
            if count > max_violations
                max_violations = count
                best_var = var
            end
        end
        
        if best_var == ""
            break
        end
        
        # Test flip impact
        flip_benefit = calculate_flip_benefit(instance, repaired_assignment, best_var)
        
        if flip_benefit > 0
            old_value = repaired_assignment[best_var]
            repaired_assignment[best_var] = !old_value
            flips_made += 1
            
            if verbose
                println("     • Flip $flips_made: $best_var: $old_value → $(!old_value) (benefit: +$flip_benefit clauses)")
            end
        else
            if verbose
                println("     • No beneficial flips found (best candidate: $best_var, benefit: $flip_benefit)")
            end
            break
        end
    end
    
    if verbose && flips_made > 0
        final_violated = find_violated_clauses(instance, repaired_assignment)
        println("     • Repair complete: $flips_made flips made, $(length(final_violated)) clauses still violated")
    end
    
    return repaired_assignment
end

"""
    community_guided_sat_solve(markdown_file::String; compare_traditional=true, verbose=true, use_v2_algorithm=true)

Main function implementing community-guided SAT solving algorithm.

Algorithm steps (from pseudocode_CD_3SAT.md):
1. Initialize all nodes as "unassigned"
2. Use modularity to score the graph
3. Sort communities by modularity contribution (lowest to highest)
4. Loop through sorted communities:
   - Sort unassigned nodes by total edge weight
   - For each node: assign to "true", assign negation to "false"
5. Check if assignment satisfies the Boolean formula

Parameters:
- use_v2_algorithm: If true, uses label_propagation_v2 (score-based), if false uses basic label_propagation

Returns CommunityGuidedResult with assignment, satisfiability, and analysis details.
"""
function community_guided_sat_solve(markdown_file::String; compare_traditional=true, verbose=true, use_v2_algorithm=true)
    start_time = time()
    
    if verbose
        println("🔍 Community-Guided SAT Solving")
        println("=" ^ 50)
        println("📂 Input file: $markdown_file")
    end
    
    # Step 1: Parse 3-SAT instance and convert to graph
    if verbose
        println("\n📋 Step 1: Parsing 3-SAT instance...")
    end
    
    instance = parse_3sat_instance_from_markdown(markdown_file)
    graph_content, node_mapping = sat3_to_graph(instance)
    
    # Create temporary graph file for community detection
    temp_graph_file = tempname() * ".txt"
    open(temp_graph_file, "w") do f
        write(f, graph_content)
    end
    
    if verbose
        println("   • Variables: $(length(instance.variables))")
        println("   • Clauses: $(length(instance.clauses))")
        println("   • Graph nodes: $(length(node_mapping))")
    end
    
    # Step 2: Run community detection using existing infrastructure
    if verbose
        algorithm_name = use_v2_algorithm ? "label propagation v2 (score-based)" : "basic label propagation"
        println("\n🔍 Step 2: Running community detection ($algorithm_name)...")
    end
    
    edge_list = read_edges(temp_graph_file)
    g, edge_weights = build_graph(edge_list)
    
    # Build node info structure (as used in mini03.jl)
    node_info = Dict{Int, NodeInfo}()
    for n in 1:nv(g)
        neighbors_list = collect(neighbors(g, n))
        node_info[n] = NodeInfo(n, neighbors_list)  # Initial label = node number
    end
    
    # Run community detection algorithm
    if use_v2_algorithm
        label_propagation_v2(g, edge_weights, node_info)
    else
        label_propagation(g, node_info)
    end
    
    # Extract communities from label propagation results
    communities = extract_communities_from_labels(node_info)
    modularity_score = calculate_modularity_score(g, edge_weights, node_info)
    
    if verbose
        println("   • Communities found: $(length(communities))")
        println("   • Modularity score: $(round(modularity_score, digits=4))")
    end
    
    # Step 3: Sort communities by modularity contribution
    if verbose
        println("\n🎯 Step 3: Analyzing community contributions...")
    end
    
    community_contributions = calculate_community_contributions(g, edge_weights, communities)
    sorted_communities = sort_communities_by_contribution(communities, community_contributions)
    
    if verbose
        println("   • Community contributions calculated")
        for (i, (comm_idx, contrib)) in enumerate(sorted_communities[1:min(3, end)])
            println("   • Community $comm_idx: $(round(contrib, digits=4)) contribution")
        end
    end
    
    # Step 4: Generate assignment using community-guided strategy
    if verbose
        println("\n⚡ Step 4: Generating community-guided assignment...")
    end
    
    assignment, strategy = generate_community_guided_assignment(
        g, edge_weights, sorted_communities, node_mapping, instance, verbose, use_v2_algorithm
    )
    
    # Step 5: Validate assignment against original formula
    if verbose
        println("\n✅ Step 5: Validating assignment...")
    end
    
    satisfiable = validate_assignment(instance, assignment)
    assignment_quality = analyze_assignment_quality(instance, assignment, verbose)
    
    if verbose
        if satisfiable
            println("   • Assignment is SATISFIABLE ✅")
        else
            println("   • Assignment is UNSATISFIABLE ❌")
            if assignment_quality.satisfaction_rate > 0.8
                println("   • 🔥 VERY CLOSE: $(round(assignment_quality.satisfaction_rate * 100, digits=1))% clauses satisfied!")
            elseif assignment_quality.satisfaction_rate > 0.5
                println("   • 🎯 PARTIAL SUCCESS: $(round(assignment_quality.satisfaction_rate * 100, digits=1))% clauses satisfied")
            end
        end
    end
    
    # Step 5.5: Apply violation repair heuristic if close to solution
    if !satisfiable && assignment_quality.satisfaction_rate >= 0.75
        if verbose
            println("\n🔧 Step 5.5: Applying violation repair heuristic...")
            println("   • Assignment quality: $(round(assignment_quality.satisfaction_rate * 100, digits=1))% - attempting repair")
        end
        
        repaired_assignment = greedy_violation_repair(instance, assignment, verbose, 5)
        repaired_satisfiable = validate_assignment(instance, repaired_assignment)
        
        if repaired_satisfiable
            assignment = repaired_assignment
            satisfiable = true
            assignment_quality = analyze_assignment_quality(instance, assignment, false)
            
            if verbose
                println("   • 🎉 REPAIR SUCCESSFUL! Assignment now satisfiable")
            end
        else
            if verbose
                repaired_quality = analyze_assignment_quality(instance, repaired_assignment, false)
                improvement = repaired_quality.satisfaction_rate - assignment_quality.satisfaction_rate
                if improvement > 0
                    println("   • 📈 Partial improvement: +$(round(improvement * 100, digits=1))% satisfaction")
                else
                    println("   • ➡️  No improvement from violation repair")
                end
            end
        end
    end
    
    # Step 6: Compare with traditional SAT solver (optional)
    traditional_result = nothing
    if compare_traditional
        if verbose
            println("\n🔄 Step 6: Comparing with traditional SAT solver...")
        end
        traditional_result = compare_with_traditional_solver(markdown_file, verbose)
    end
    
    # Cleanup
    rm(temp_graph_file, force=true)
    
    solve_time = time() - start_time
    
    if verbose
        println("\n🎉 Community-guided SAT solving completed!")
        println("   • Total time: $(round(solve_time, digits=3))s")
        println("   • Result: $(satisfiable ? "SATISFIABLE" : "UNSATISFIABLE")")
    end
    
    return CommunityGuidedResult(
        assignment, satisfiable, communities, modularity_score, 
        strategy, solve_time, traditional_result, assignment_quality
    )
end

"""
    extract_communities_from_labels(node_info)

Extract community structure from label propagation results.
"""
function extract_communities_from_labels(node_info)
    label_to_nodes = Dict{Int, Vector{Int}}()
    
    for (node, info) in node_info
        label = info.label
        if !haskey(label_to_nodes, label)
            label_to_nodes[label] = Int[]
        end
        push!(label_to_nodes[label], node)
    end
    
    return collect(values(label_to_nodes))
end

"""
    calculate_modularity_score(g, edge_weights, node_info)

Calculate modularity score using existing scoring infrastructure.
"""
function calculate_modularity_score(g, edge_weights, node_info)
    current_colors = [node_info[k].label for k in 1:nv(g)]
    return get_score(g, edge_weights, node_info, current_colors)
end

"""
    calculate_community_contributions(g, edge_weights, communities)

Calculate how much each community contributes to the total modularity score.
"""
function calculate_community_contributions(g, edge_weights, communities)
    contributions = Float64[]
    
    for community in communities
        # Calculate internal connectivity strength for this community
        internal_weight = 0.0
        total_degree = 0.0
        
        for node in community
            if node <= nv(g)
                for neighbor in neighbors(g, node)
                    weight = get(edge_weights, (node, neighbor), 0.0)
                    total_degree += weight
                    if neighbor in community
                        internal_weight += weight
                    end
                end
            end
        end
        
        # Contribution metric based on internal connectivity ratio
        contribution = total_degree > 0 ? internal_weight / total_degree : 0.0
        push!(contributions, contribution)
    end
    
    return contributions
end

"""
    sort_communities_by_contribution(communities, contributions)

Sort communities by their modularity contribution (lowest to highest).
"""
function sort_communities_by_contribution(communities, contributions)
    community_pairs = [(i, contrib) for (i, contrib) in enumerate(contributions)]
    sorted_pairs = sort(community_pairs, by=x->x[2], rev=false)
    return sorted_pairs
end

"""
    generate_community_guided_assignment(g, edge_weights, sorted_communities, node_mapping, instance, verbose, use_v2_algorithm)

Generate variable assignment using community-guided strategy.
"""
function generate_community_guided_assignment(g, edge_weights, sorted_communities, node_mapping, instance, verbose, use_v2_algorithm)
    assignment = Dict{String, Bool}()
    assigned_variables = Set{String}()
    strategy = String[]
    
    # Get the communities list for indexing
    communities = extract_communities_from_labels(create_node_info_for_communities(g, edge_weights, use_v2_algorithm))
    
    if verbose
        println("   • Processing communities in order of contribution...")
    end
    
    for (comm_idx, (community_index, contribution)) in enumerate(sorted_communities)
        if community_index <= length(communities)
            community = communities[community_index]  # Get the actual community
            
            if verbose
                println("   • Community $comm_idx (contribution: $(round(contribution, digits=4)))")
            end
            
            # Get unassigned nodes in this community
            unassigned_nodes = []
            for node in community
                if haskey(node_mapping, node)
                    literal = node_mapping[node]
                    var_name = get_variable_name(literal)
                    if !(var_name in assigned_variables)
                        push!(unassigned_nodes, node)
                    end
                end
            end
            
            # Sort nodes by total edge weight
            node_weights = []
            for node in unassigned_nodes
                total_weight = 0.0
                if node <= nv(g)
                for neighbor in neighbors(g, node)
                    weight = get(edge_weights, (node, neighbor), 0.0)
                    total_weight += weight
                end
            end
            push!(node_weights, (node, total_weight))
        end
        sort!(node_weights, by=x->x[2], rev=false)            # Assign variables based on literal frequency analysis
            for (node, weight) in node_weights
                if haskey(node_mapping, node)
                    literal = node_mapping[node]
                    var_name = get_variable_name(literal)
                    
                    if !(var_name in assigned_variables)
                        # Count positive vs negative occurrences and their clause impact
                        pos_count = 0
                        neg_count = 0
                        pos_clause_contribution = 0.0
                        neg_clause_contribution = 0.0
                        
                        for (clause_idx, clause) in enumerate(instance.clauses)
                            var_in_clause = false
                            pos_in_clause = false
                            neg_in_clause = false
                            
                            for clause_literal in clause
                                if get_variable_name(clause_literal) == var_name
                                    var_in_clause = true
                                    if is_negated(clause_literal)
                                        neg_count += 1
                                        neg_in_clause = true
                                    else
                                        pos_count += 1
                                        pos_in_clause = true
                                    end
                                end
                            end
                            
                            # Weight by clause size (smaller clauses are more constraining)
                            clause_weight = 1.0 / length(clause)
                            if pos_in_clause
                                pos_clause_contribution += clause_weight
                            end
                            if neg_in_clause
                                neg_clause_contribution += clause_weight
                            end
                        end
                        
                        # Assign based on weighted contribution: higher contribution = assign true
                        assignment[var_name] = pos_clause_contribution >= neg_clause_contribution
                        push!(assigned_variables, var_name)
                        
                        strategy_msg = "Community $comm_idx: $var_name = $(assignment[var_name]) (pos: $pos_count/$pos_clause_contribution, neg: $neg_count/$neg_clause_contribution, weight: $weight)"
                        push!(strategy, strategy_msg)
                        
                        if verbose
                            println("     • $strategy_msg")
                        end
                    end
                end
            end
        end
    end
    
    # Assign any remaining unassigned variables randomly
    for var in instance.variables
        if !(var in assigned_variables)
            assignment[var] = rand(Bool)
            push!(strategy, "Random: $var = $(assignment[var]) (unprocessed)")
            if verbose
                println("     • Random assignment: $var = $(assignment[var])")
            end
        end
    end
    
    return assignment, strategy
end

"""
    create_node_info_for_communities(g, edge_weights, use_v2=true)

Helper function to create node_info structure for community extraction.
"""
function create_node_info_for_communities(g, edge_weights, use_v2=true)
    node_info = Dict{Int, NodeInfo}()
    for n in 1:nv(g)
        neighbors_list = collect(neighbors(g, n))
        node_info[n] = NodeInfo(n, neighbors_list)
    end
    
    # Run community detection
    if use_v2
        label_propagation_v2(g, edge_weights, node_info)
    else
        label_propagation(g, node_info)
    end
    
    return node_info
end

"""
    get_variable_name(literal::String)

Extract variable name from literal (removes negation symbol if present).
"""
function get_variable_name(literal::String)
    return startswith(literal, "¬") ? literal[nextind(literal, 1):end] : literal
end

"""
    is_negated(literal::String)

Check if literal is negated.
"""
function is_negated(literal::String)
    return startswith(literal, "¬")
end

"""
    validate_assignment(instance, assignment)

Check if the assignment satisfies all clauses in the 3-SAT instance.
"""
function validate_assignment(instance, assignment)
    for clause in instance.clauses
        clause_satisfied = false
        
        for literal in clause
            var_name = get_variable_name(literal)
            var_value = get(assignment, var_name, false)
            
            # Check if this literal is satisfied
            literal_satisfied = is_negated(literal) ? !var_value : var_value
            
            if literal_satisfied
                clause_satisfied = true
                break
            end
        end
        
        if !clause_satisfied
            return false
        end
    end
    
    return true
end

"""
    analyze_assignment_quality(instance, assignment, verbose=false)

Analyze how close an assignment comes to satisfying the 3-SAT instance.
Returns detailed diagnostics about clause satisfaction.
"""
function analyze_assignment_quality(instance, assignment, verbose=false)
    total_clauses = length(instance.clauses)
    satisfied_clauses = 0
    violated_clauses = []
    clause_satisfaction_details = []
    
    for (i, clause) in enumerate(instance.clauses)
        clause_satisfied = false
        satisfied_literals = 0
        literal_details = []
        
        for literal in clause
            var_name = get_variable_name(literal)
            var_value = get(assignment, var_name, false)
            
            # Check if this literal is satisfied
            literal_satisfied = is_negated(literal) ? !var_value : var_value
            
            if literal_satisfied
                satisfied_literals += 1
                clause_satisfied = true
            end
            
            push!(literal_details, (literal, literal_satisfied, var_name, var_value))
        end
        
        clause_info = (
            clause_id = i,
            clause = clause,
            satisfied = clause_satisfied,
            satisfied_literals = satisfied_literals,
            total_literals = length(clause),
            literal_details = literal_details
        )
        
        push!(clause_satisfaction_details, clause_info)
        
        if clause_satisfied
            satisfied_clauses += 1
        else
            push!(violated_clauses, clause_info)
        end
    end
    
    satisfaction_rate = satisfied_clauses / total_clauses
    
    if verbose
        println("\n📊 ASSIGNMENT QUALITY ANALYSIS:")
        println("   Satisfied clauses: $satisfied_clauses/$total_clauses ($(round(satisfaction_rate * 100, digits=1))%)")
        
        if !isempty(violated_clauses)
            println("   \n❌ VIOLATED CLAUSES:")
            for clause_info in violated_clauses
                println("     Clause $(clause_info.clause_id): $(join(clause_info.clause, " ∨ "))")
                for (literal, satisfied, var_name, var_value) in clause_info.literal_details
                    status = satisfied ? "✓" : "✗"
                    println("       $status $literal ($var_name = $var_value)")
                end
            end
        end
        
        if satisfaction_rate < 1.0 && satisfaction_rate > 0.8
            println("   \n💡 CLOSE TO SOLUTION: $(round((1-satisfaction_rate)*100, digits=1))% of clauses unsatisfied")
            println("      Consider variable flipping heuristics for remaining clauses")
        elseif satisfaction_rate > 0.5
            println("   \n🎯 PARTIALLY SUCCESSFUL: Over half the clauses satisfied")
        end
    end
    
    return (
        satisfaction_rate = satisfaction_rate,
        satisfied_clauses = satisfied_clauses,
        total_clauses = total_clauses,
        violated_clauses = violated_clauses,
        clause_details = clause_satisfaction_details
    )
end

"""
    compare_with_traditional_solver(markdown_file, verbose)

Compare results with traditional SAT solver if available.
"""
function compare_with_traditional_solver(markdown_file, verbose)
    try
        # Try to use the existing SAT solver if available
        if isdefined(Main, :solve_3sat)
            result = Main.solve_3sat(markdown_file)
            if verbose
                println("   • Traditional solver: $(result.satisfiable ? "SATISFIABLE" : "UNSATISFIABLE")")
                if result.satisfiable && result.solution !== nothing
                    println("   • Traditional solution found")
                end
            end
            return result
        else
            if verbose
                println("   • Traditional SAT solver not available for comparison")
            end
            return nothing
        end
    catch e
        if verbose
            println("   • Error comparing with traditional solver: $e")
        end
        return nothing
    end
end

"""
    demo_community_guided_sat(; num_vars=4, num_clauses=8, seed=42, use_v2_algorithm=true)

Demo function to showcase community-guided SAT solving.
"""
function demo_community_guided_sat(; num_vars=4, num_clauses=8, seed=42, use_v2_algorithm=true)
    println("🚀 Community-Guided SAT Solving Demo")
    println("=" ^ 50)
    
    # Generate a test instance
    println("📋 Generating test 3-SAT instance...")
    instance = generate_random_3sat(num_vars, num_clauses, seed=seed)
    
    # Create temporary markdown file
    temp_md_file = tempname() * ".md"
    md_content = to_markdown(instance, "Demo Instance: $num_vars variables, $num_clauses clauses")
    open(temp_md_file, "w") do f
        write(f, md_content)
    end
    
    println("   • Generated: $num_vars variables, $num_clauses clauses")
    println("   • Clause/variable ratio: $(round(num_clauses/num_vars, digits=2))")
    println()
    
    # Run community-guided solving
    result = community_guided_sat_solve(temp_md_file, compare_traditional=true, use_v2_algorithm=use_v2_algorithm)
    
    # Display results
    println("\n📊 Results Summary:")
    println("   • Community-guided result: $(result.satisfiable ? "SATISFIABLE" : "UNSATISFIABLE")")
    println("   • Communities found: $(length(result.communities))")
    println("   • Modularity score: $(round(result.modularity_score, digits=4))")
    println("   • Solve time: $(round(result.solve_time, digits=3))s")
    
    if result.traditional_sat_result !== nothing
        traditional_satisfiable = result.traditional_sat_result.satisfiable
        println("   • Traditional solver: $(traditional_satisfiable ? "SATISFIABLE" : "UNSATISFIABLE")")
        
        if result.satisfiable == traditional_satisfiable
            println("   • ✅ Results MATCH!")
        else
            println("   • ❌ Results DIFFER - needs investigation")
        end
    end
    
    println("\n🎯 Assignment Strategy:")
    for (i, step) in enumerate(result.assignment_strategy[1:min(5, end)])
        println("   $i. $step")
    end
    if length(result.assignment_strategy) > 5
        println("   ... ($(length(result.assignment_strategy) - 5) more steps)")
    end
    
    # Cleanup
    rm(temp_md_file, force=true)
    
    return result
end

# Export main functions
export community_guided_sat_solve, demo_community_guided_sat, CommunityGuidedResult
