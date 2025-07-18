# 3-SAT Instance Generator and Parser
# Handles Markdown-formatted 3-SAT instances

using Random
using StatsBase  # For sample function

# Structure to represent a 3-SAT instance
struct SAT3Instance
    variables::Vector{String}
    clauses::Vector{Vector{String}}
    metadata::Dict{String, Any}
end

# Generate random 3-SAT instance with exactly 3 distinct literals per clause
function generate_random_3sat(num_vars::Int, num_clauses::Int; seed=nothing)
    if seed !== nothing
        Random.seed!(seed)
    end
    
    if num_vars < 3
        error("Need at least 3 variables to generate 3-SAT with distinct literals per clause")
    end
    
    # Create variable names
    variables = ["x$i" for i in 1:num_vars]
    
    # Generate random clauses with exactly 3 distinct variables each
    clauses = []
    for _ in 1:num_clauses
        # Pick 3 distinct variables (without replacement)
        selected_vars = sample(variables, 3, replace=false)
        
        clause = []
        for var in selected_vars
            # 50% chance of negation for each literal
            literal = rand(Bool) ? var : "¬$var"
            push!(clause, literal)
        end
        push!(clauses, clause)
    end
    
    metadata = Dict(
        "variables" => num_vars,
        "clauses" => num_clauses,
        "ratio" => num_clauses / num_vars,
        "generated" => "random",
        "seed" => seed,
        "constraint" => "3_distinct_literals_per_clause"
    )
    
    return SAT3Instance(variables, clauses, metadata)
end

# Validate that all clauses have exactly 3 distinct literals
function validate_distinct_literals(instance::SAT3Instance)
    violations = []
    
    for (i, clause) in enumerate(instance.clauses)
        if length(clause) != 3
            push!(violations, "Clause $i has $(length(clause)) literals (expected 3)")
            continue
        end
        
        # Extract variable names from literals
        variables_in_clause = Set{String}()
        for literal in clause
            # Remove negation symbol to get variable name (handle Unicode ¬)
            if startswith(literal, "¬")
                # Find the variable part after the negation symbol
                var_match = match(r"x\d+", literal)
                if var_match !== nothing
                    push!(variables_in_clause, var_match.match)
                end
            else
                push!(variables_in_clause, literal)
            end
        end
        
        if length(variables_in_clause) != 3
            distinct_vars = collect(variables_in_clause)
            push!(violations, "Clause $i: $(join(clause, " ∨ ")) uses only $(length(variables_in_clause)) distinct variables: $(join(distinct_vars, ", "))")
        end
    end
    
    return violations
end

# Validate and optionally fix SAT instance
function ensure_distinct_literals(instance::SAT3Instance; fix_violations=true)
    violations = validate_distinct_literals(instance)
    
    if isempty(violations)
        println("✅ All clauses have 3 distinct literals")
        return instance, violations
    end
    
    if !fix_violations
        println("❌ Found $(length(violations)) clause violations:")
        for violation in violations
            println("   • $violation")
        end
        return instance, violations
    end
    
    # Fix violations by regenerating problematic clauses
    println("🔧 Found $(length(violations)) violations, fixing...")
    fixed_clauses = copy(instance.clauses)
    
    for (i, clause) in enumerate(instance.clauses)
        vars_in_clause = Set{String}()
        for literal in clause
            # Extract variable name safely
            if startswith(literal, "¬")
                var_match = match(r"x\d+", literal)
                if var_match !== nothing
                    push!(vars_in_clause, var_match.match)
                end
            else
                push!(vars_in_clause, literal)
            end
        end
        
        if length(vars_in_clause) != 3
            # Regenerate this clause with 3 distinct variables
            available_vars = instance.variables
            if length(available_vars) >= 3
                selected_vars = sample(available_vars, 3, replace=false)
                new_clause = []
                for var in selected_vars
                    literal = rand(Bool) ? var : "¬$var"
                    push!(new_clause, literal)
                end
                fixed_clauses[i] = new_clause
                println("   Fixed clause $i: $(join(clause, " ∨ ")) → $(join(new_clause, " ∨ "))")
            end
        end
    end
    
    # Create new instance with fixed clauses
    fixed_metadata = copy(instance.metadata)
    fixed_metadata["fixed_violations"] = length(violations)
    fixed_instance = SAT3Instance(instance.variables, fixed_clauses, fixed_metadata)
    
    # Validate the fix
    remaining_violations = validate_distinct_literals(fixed_instance)
    if isempty(remaining_violations)
        println("✅ All violations fixed successfully")
    else
        println("⚠️  $(length(remaining_violations)) violations remain")
    end
    
    return fixed_instance, violations
end

# Convert 3-SAT instance to Markdown format
function to_markdown(instance::SAT3Instance, title::String="3-SAT Instance")
    md = """
    # $title
    
    ## Variables
    $(join(["- " * var for var in instance.variables], "\n"))
    
    ## Clauses
    """
    
    for (i, clause) in enumerate(instance.clauses)
        clause_str = "(" * join(clause, " ∨ ") * ")"
        md *= "$i. $clause_str\n"
    end
    
    md *= """
    
    ## Metadata
    - Variables: $(get(instance.metadata, "variables", length(instance.variables)))
    - Clauses: $(get(instance.metadata, "clauses", length(instance.clauses)))
    - Ratio: $(round(get(instance.metadata, "ratio", length(instance.clauses) / length(instance.variables)), digits=2)) (clauses/variables)"""
    
    if haskey(instance.metadata, "generated")
        md *= "\n- Generated: $(instance.metadata["generated"])"
    end
    if haskey(instance.metadata, "seed")
        md *= "\n- Seed: $(instance.metadata["seed"])"
    end
    
    md *= "\n"
    
    if haskey(instance.metadata, "seed")
        md *= "\n- Seed: $(instance.metadata["seed"])"
    end
    
    return md
end

# Parse Markdown 3-SAT file
function parse_3sat_markdown(filepath::String)
    content = read(filepath, String)
    lines = split(content, "\\n")
    
    variables = String[]
    clauses = Vector{String}[]
    metadata = Dict{String, Any}()
    
    current_section = ""
    
    for line in lines
        line = strip(line)
        if startswith(line, "## Variables")
            current_section = "variables"
        elseif startswith(line, "## Clauses")
            current_section = "clauses"
        elseif startswith(line, "## Metadata")
            current_section = "metadata"
        elseif current_section == "variables" && startswith(line, "- ")
            # Parse variables: "- x₁, x₂, x₃" or "- x₁"
            var_line = replace(line[3:end], " " => "")
            vars = split(var_line, ",")
            append!(variables, [strip(v) for v in vars if !isempty(strip(v))])
        elseif current_section == "clauses" && match(r"^\\d+\\.", line) !== nothing
            # Parse clause: "1. (x₁ ∨ ¬x₂ ∨ x₃)"
            clause_match = match(r"\\((.+?)\\)", line)
            if clause_match !== nothing
                clause_str = clause_match.captures[1]
                # Split by ∨ and clean up
                literals = [strip(lit) for lit in split(clause_str, "∨")]
                push!(clauses, literals)
            end
        elseif current_section == "metadata" && startswith(line, "- ")
            # Parse metadata: "- Variables: 5"
            meta_match = match(r"- (.+?): (.+)", line)
            if meta_match !== nothing
                key, value = meta_match.captures
                # Try to parse as number
                try
                    metadata[key] = parse(Float64, value)
                catch
                    metadata[key] = value
                end
            end
        end
    end
    
    return SAT3Instance(variables, clauses, metadata)
end

# Convert 3-SAT instance to graph format (our .txt format)
function sat3_to_graph(instance::SAT3Instance)
    # Create literal-to-node mapping
    literal_to_node = Dict{String, Int}()
    node_to_literal = Dict{Int, String}()
    node_counter = 1
    
    # Map all literals (positive and negative)
    for var in instance.variables
        if !haskey(literal_to_node, var)
            literal_to_node[var] = node_counter
            node_to_literal[node_counter] = var
            node_counter += 1
        end
        
        neg_var = "¬$var"
        if !haskey(literal_to_node, neg_var)
            literal_to_node[neg_var] = node_counter
            node_to_literal[node_counter] = neg_var
            node_counter += 1
        end
    end
    
    # Count co-occurrences in clauses
    edge_weights = Dict{Tuple{Int,Int}, Int}()
    
    for clause in instance.clauses
        # For each pair of literals in the clause
        for i in 1:length(clause)
            for j in (i+1):length(clause)
                lit1, lit2 = clause[i], clause[j]
                node1, node2 = literal_to_node[lit1], literal_to_node[lit2]
                
                # Add both directions (undirected graph)
                key1 = (node1, node2)
                key2 = (node2, node1)
                
                edge_weights[key1] = get(edge_weights, key1, 0) + 1
                edge_weights[key2] = get(edge_weights, key2, 0) + 1
            end
        end
    end
    
    # Generate graph file content
    graph_lines = String[]
    for ((i, j), weight) in edge_weights
        if i < j  # Only write each edge once
            push!(graph_lines, "$i $j $weight")
        end
    end
    
    return join(graph_lines, "\n"), node_to_literal
end

# Example usage
println("=== 3-SAT Markdown Generator ===")

# Ensure examples directory exists
examples_dir = "examples"
if !isdir(examples_dir)
    mkdir(examples_dir)
end

# Generate a random instance
instance = generate_random_3sat(4, 6, seed=123)

# Convert to markdown and save
md_content = to_markdown(instance, "Random 4-variable, 6-clause Instance")
open("$examples_dir/example_3sat.md", "w") do f
    write(f, md_content)
end
println("✓ Saved Markdown to $examples_dir/example_3sat.md")

# Convert to graph format and save
graph_content, node_mapping = sat3_to_graph(instance)
open("$examples_dir/example_3sat_graph.txt", "w") do f
    write(f, graph_content)
end
println("✓ Saved Graph to $examples_dir/example_3sat_graph.txt")

# Save node mapping
open("$examples_dir/example_3sat_mapping.txt", "w") do f
    for (node, literal) in sort(collect(node_mapping))
        write(f, "Node $node: $literal\n")
    end
end
println("✓ Saved Node Mapping to $examples_dir/example_3sat_mapping.txt")

println("\n=== Files Created ===")
println("1. $examples_dir/example_3sat.md - Human-readable 3-SAT instance")
println("2. $examples_dir/example_3sat_graph.txt - Graph format for community detection")
println("3. $examples_dir/example_3sat_mapping.txt - Node to literal mapping")

println("\n=== Preview of Markdown File ===")
println(md_content[1:min(length(md_content), 500)])
if length(md_content) > 500
    println("... (truncated)")
end

# CONVENIENCE FUNCTIONS FOR CREATING VALID 3-SAT INSTANCES

"""
Create a research-quality 3-SAT instance with guaranteed distinct literals per clause.
This is the recommended way to create new 3-SAT instances.
"""
function create_research_instance(num_vars::Int, num_clauses::Int; 
                                 seed=nothing, 
                                 title="Research 3-SAT Instance",
                                 validate=true)
    
    # Generate the instance
    instance = generate_random_3sat(num_vars, num_clauses, seed=seed)
    
    # Validate constraints
    if validate
        violations = validate_distinct_literals(instance)
        if !isempty(violations)
            error("Generated instance has constraint violations: $(join(violations, ", "))")
        end
        println("✅ Generated valid instance: $num_vars variables, $num_clauses clauses")
    end
    
    return instance, to_markdown(instance, title)
end

"""
Quick template for creating test instances with proper constraints.
Usage: 
  - create_test_instance(4, 8)  # 4 variables, 8 clauses
  - create_test_instance(5, 15, seed=42, name="my_test")
"""
function create_test_instance(num_vars::Int, num_clauses::Int; 
                             seed=nothing, 
                             name="test_instance")
    
    if num_vars < 3
        error("Need at least 3 variables for distinct literals constraint")
    end
    
    instance, markdown = create_research_instance(
        num_vars, num_clauses, 
        seed=seed, 
        title="Test Instance: $num_vars variables, $num_clauses clauses"
    )
    
    # Save to file
    filename = "$(name)_$(num_vars)vars_$(num_clauses)clauses"
    if seed !== nothing
        filename *= "_seed$(seed)"
    end
    filename *= ".md"
    
    write(filename, markdown)
    println("💾 Saved to: $filename")
    
    return instance, filename
end

"""
Reminder function - always call this when creating new instances manually!
"""
function remind_distinct_literals()
    println("🔒 CONSTRAINT REMINDER:")
    println("   • All 3-SAT clauses MUST have exactly 3 DISTINCT literals")
    println("   • Use create_research_instance() or create_test_instance()")
    println("   • Validate existing instances with validate_distinct_literals()")
    println("   • Fix violations with ensure_distinct_literals()")
    println("   • Generator enforces constraint: generate_random_3sat()")
end
