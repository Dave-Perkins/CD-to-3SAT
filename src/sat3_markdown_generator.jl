# 3-SAT Instance Generator and Parser
# Handles Markdown-formatted 3-SAT instances

using Random

# Structure to represent a 3-SAT instance
struct SAT3Instance
    variables::Vector{String}
    clauses::Vector{Vector{String}}
    metadata::Dict{String, Any}
end

# Generate random 3-SAT instance
function generate_random_3sat(num_vars::Int, num_clauses::Int; seed=nothing)
    if seed !== nothing
        Random.seed!(seed)
    end
    
    # Create variable names
    variables = ["x$i" for i in 1:num_vars]
    
    # Generate random clauses
    clauses = []
    for _ in 1:num_clauses
        clause = []
        # Pick 3 random variables (with replacement allowed)
        for _ in 1:3
            var = rand(variables)
            # 50% chance of negation
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
        "seed" => seed
    )
    
    return SAT3Instance(variables, clauses, metadata)
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
    - Variables: $(instance.metadata["variables"])
    - Clauses: $(instance.metadata["clauses"])
    - Ratio: $(round(instance.metadata["ratio"], digits=2)) (clauses/variables)
    - Generated: $(instance.metadata["generated"])
    """
    
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
