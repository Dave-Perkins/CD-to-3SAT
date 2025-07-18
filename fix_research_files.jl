using Random

"""
Fix research files to ensure all clauses have exactly 3 distinct literals
"""

function parse_clause(clause_text)
    # Extract literals from clause text like "(x2 ∨ ¬x2 ∨ ¬x3)"
    # Remove parentheses and split by ∨
    clause_text = strip(clause_text)
    if startswith(clause_text, "(") && endswith(clause_text, ")")
        clause_text = clause_text[2:end-1]
    end
    
    literals = []
    for literal in split(clause_text, "∨")
        literal = strip(literal)
        if !isempty(literal)
            push!(literals, literal)
        end
    end
    return literals
end

function get_variable_from_literal(literal)
    literal = strip(literal)
    # Handle both ASCII ¬ and Unicode ¬ characters
    if startswith(literal, "¬")
        # Unicode ¬ is multi-byte, so find where the variable starts
        for i in 2:length(literal)
            if literal[i] == 'x'
                return literal[i:end]
            end
        end
        return literal[2:end]  # fallback
    else
        return literal
    end
end

function generate_distinct_literals(variables, existing_literals, target_count=3)
    """Generate exactly target_count distinct literals from available variables"""
    # Get variables that are already represented
    used_vars = Set()
    valid_literals = []
    
    # First, add existing literals that don't conflict
    for lit in existing_literals
        var = get_variable_from_literal(lit)
        if var ∉ used_vars
            push!(valid_literals, lit)
            push!(used_vars, var)
        end
        if length(valid_literals) >= target_count
            break
        end
    end
    
    # Then add new literals from unused variables
    available_vars = setdiff(Set(variables), used_vars)
    while length(valid_literals) < target_count && !isempty(available_vars)
        var = rand(collect(available_vars))
        # Randomly choose positive or negative
        literal = rand() < 0.5 ? var : "¬$var"
        push!(valid_literals, literal)
        push!(used_vars, var)
        delete!(available_vars, var)
    end
    
    return valid_literals[1:min(target_count, length(valid_literals))]
end

function fix_clause(clause_text, variables)
    """Fix a clause to have exactly 3 distinct literals"""
    literals = parse_clause(clause_text)
    
    # Check if already has 3 distinct literals
    used_vars = Set()
    distinct_literals = []
    
    for lit in literals
        var = get_variable_from_literal(lit)
        if var ∉ used_vars
            push!(distinct_literals, lit)
            push!(used_vars, var)
        end
    end
    
    if length(distinct_literals) == 3
        return clause_text  # Already good
    end
    
    # Generate 3 distinct literals
    fixed_literals = generate_distinct_literals(variables, distinct_literals, 3)
    
    # Format as clause
    return "(" * join(fixed_literals, " ∨ ") * ")"
end

function process_research_file(filepath)
    println("🔧 Processing: $(basename(filepath))")
    
    # Read the file
    content = read(filepath, String)
    lines = split(content, '\n')
    
    # Extract variables and clauses
    variables = []
    clause_section = false
    updated_lines = String[]
    changes_made = 0
    
    for (i, line) in enumerate(lines)
        line = strip(line)
        
        # Track variables
        if startswith(line, "- x")
            var_match = match(r"- (x\d+)", line)
            if var_match !== nothing
                push!(variables, var_match.captures[1])
            end
        end
        
        # Check for clause section
        if line == "## Clauses"
            clause_section = true
            push!(updated_lines, lines[i])
            continue
        elseif clause_section && (startswith(line, "##") || startswith(line, "- Variables:") || startswith(line, "- Clauses:"))
            clause_section = false
        end
        
        # Process clause lines
        if clause_section && match(r"^\d+\.\s*\(", line) !== nothing
            # Extract the clause part
            clause_match = match(r"^\d+\.\s*(\(.+\))", line)
            if clause_match !== nothing
                old_clause = clause_match.captures[1]
                new_clause = fix_clause(old_clause, variables)
                
                if old_clause != new_clause
                    changes_made += 1
                    new_line = replace(line, old_clause => new_clause)
                    push!(updated_lines, new_line)
                    println("   Fixed clause $(changes_made): $old_clause → $new_clause")
                else
                    push!(updated_lines, lines[i])
                end
            else
                push!(updated_lines, lines[i])
            end
        else
            push!(updated_lines, lines[i])
        end
    end
    
    if changes_made > 0
        # Write back the updated content
        write(filepath, join(updated_lines, '\n'))
        println("   ✅ Made $changes_made changes to $(basename(filepath))")
    else
        println("   ✅ No changes needed for $(basename(filepath))")
    end
    
    return changes_made
end

function main()
    println("🚀 FIXING RESEARCH FILES - ENSURING 3 DISTINCT LITERALS PER CLAUSE")
    println("=" ^ 70)
    
    research_dir = "/Users/dperkins/Desktop/pioneer/CD-to-3SAT/research"
    
    # Get all .md files in research directory
    md_files = [f for f in readdir(research_dir) if endswith(f, ".md")]
    sort!(md_files)
    
    total_changes = 0
    
    for filename in md_files
        filepath = joinpath(research_dir, filename)
        changes = process_research_file(filepath)
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
Random.seed!(12345)
main()
