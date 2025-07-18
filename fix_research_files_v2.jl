using Random

"""
Fix research files to ensure all clauses have exactly 3 distinct literals
"""

function extract_variable_from_literal(literal)
    """Safely extract variable name from literal, handling Unicode ¬"""
    literal = strip(String(literal))
    
    # Find 'x' followed by digits
    x_match = match(r"x\d+", literal)
    if x_match !== nothing
        return x_match.match
    end
    
    return nothing
end

function is_negative_literal(literal)
    """Check if literal is negative (starts with ¬)"""
    literal = strip(String(literal))
    return occursin("¬", literal)
end

function create_literal(variable, is_negative=false)
    """Create a literal from variable name"""
    if is_negative
        return "¬$variable"
    else
        return variable
    end
end

function parse_clause_literals(clause_text)
    """Extract literals from clause text like '(x2 ∨ ¬x2 ∨ ¬x3)'"""
    clause_text = strip(String(clause_text))
    
    # Remove parentheses
    if startswith(clause_text, "(") && endswith(clause_text, ")")
        clause_text = clause_text[2:end-1]
    end
    
    # Split by ∨ symbol
    parts = split(clause_text, "∨")
    literals = []
    
    for part in parts
        part = strip(String(part))
        if !isempty(part)
            push!(literals, part)
        end
    end
    
    return literals
end

function get_distinct_variables_from_clause(literals)
    """Get unique variables from a list of literals"""
    variables = Set{String}()
    
    for literal in literals
        var = extract_variable_from_literal(literal)
        if var !== nothing
            push!(variables, var)
        end
    end
    
    return collect(variables)
end

function generate_three_distinct_literals(all_variables, existing_literals=[])
    """Generate exactly 3 distinct literals from available variables"""
    used_vars = Set{String}()
    result_literals = []
    
    # First, try to preserve existing literals that don't conflict
    for literal in existing_literals
        var = extract_variable_from_literal(literal)
        if var !== nothing && var ∉ used_vars
            push!(result_literals, literal)
            push!(used_vars, var)
            if length(result_literals) >= 3
                break
            end
        end
    end
    
    # Add new literals from unused variables
    available_vars = setdiff(Set(all_variables), used_vars)
    
    while length(result_literals) < 3 && !isempty(available_vars)
        var = rand(collect(available_vars))
        # Randomly choose positive or negative
        is_neg = rand() < 0.5
        literal = create_literal(var, is_neg)
        
        push!(result_literals, literal)
        push!(used_vars, var)
        delete!(available_vars, var)
    end
    
    return result_literals[1:min(3, length(result_literals))]
end

function fix_clause_to_three_distinct(clause_text, all_variables)
    """Fix a clause to have exactly 3 distinct literals"""
    literals = parse_clause_literals(clause_text)
    distinct_vars = get_distinct_variables_from_clause(literals)
    
    if length(distinct_vars) == 3
        return clause_text  # Already good
    end
    
    # Generate 3 distinct literals
    fixed_literals = generate_three_distinct_literals(all_variables, literals)
    
    # Format as clause
    return "(" * join(fixed_literals, " ∨ ") * ")"
end

function process_file(filepath)
    println("🔧 Processing: $(basename(filepath))")
    
    try
        # Read file content
        content = read(filepath, String)
        lines = split(content, '\n')
        
        # Extract variables
        variables = String[]
        for line in lines
            var_match = match(r"- (x\d+)", line)
            if var_match !== nothing
                push!(variables, var_match.captures[1])
            end
        end
        
        if isempty(variables)
            println("   ⚠️  No variables found, skipping")
            return 0
        end
        
        # Process lines
        updated_lines = String[]
        changes_made = 0
        in_clauses_section = false
        
        for line in lines
            line_str = String(line)
            
            # Track if we're in clauses section
            if strip(line_str) == "## Clauses"
                in_clauses_section = true
                push!(updated_lines, line_str)
                continue
            elseif in_clauses_section && (startswith(strip(line_str), "##") || startswith(strip(line_str), "- Variables:"))
                in_clauses_section = false
            end
            
            # Process clause lines
            if in_clauses_section
                clause_match = match(r"^(\d+\.\s*)(\(.+\))", line_str)
                if clause_match !== nothing
                    prefix = clause_match.captures[1]
                    old_clause = clause_match.captures[2]
                    new_clause = fix_clause_to_three_distinct(old_clause, variables)
                    
                    if old_clause != new_clause
                        changes_made += 1
                        new_line = prefix * new_clause
                        push!(updated_lines, new_line)
                        println("   Fixed clause $(changes_made): $old_clause → $new_clause")
                    else
                        push!(updated_lines, line_str)
                    end
                else
                    push!(updated_lines, line_str)
                end
            else
                push!(updated_lines, line_str)
            end
        end
        
        # Write back if changes were made
        if changes_made > 0
            write(filepath, join(updated_lines, '\n'))
            println("   ✅ Made $changes_made changes")
        else
            println("   ✅ No changes needed")
        end
        
        return changes_made
        
    catch e
        println("   ❌ Error processing file: $e")
        return 0
    end
end

function main()
    println("🚀 FIXING RESEARCH FILES - ENSURING 3 DISTINCT LITERALS PER CLAUSE")
    println("=" ^ 70)
    
    research_dir = "/Users/dperkins/Desktop/pioneer/CD-to-3SAT/research"
    
    # Get all .md files
    md_files = [f for f in readdir(research_dir) if endswith(f, ".md")]
    sort!(md_files)
    
    total_changes = 0
    
    for filename in md_files
        filepath = joinpath(research_dir, filename)
        changes = process_file(filepath)
        total_changes += changes
        println()
    end
    
    println("=" ^ 70)
    println("🎉 COMPLETED!")
    println("   • Processed $(length(md_files)) files")
    println("   • Made $total_changes total clause fixes")
    println("   • All clauses now have 3 distinct literals")
end

# Set seed for reproducible results
Random.seed!(42)
main()
