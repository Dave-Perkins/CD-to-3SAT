"""
SAT Solver Integration Module

Provides satisfiability checking for 3-SAT instances using CryptoMiniSat.
Integrates with the existing markdown-based 3-SAT pipeline.
"""

using CryptoMiniSat

"""
    SATResult

Structure to hold satisfiability checking results.
"""
mutable struct SATResult
    satisfiable::Bool
    solution::Union{Vector{Bool}, Nothing}
    solve_time::Float64
    num_conflicts::Int
    
    SATResult() = new(false, nothing, 0.0, 0)
end

"""
    parse_3sat_from_markdown(filename::String) -> (Int, Vector{Vector{Int}})

Parse a 3-SAT instance from markdown format.
Returns (num_variables, clauses) where each clause is a vector of literals.
Positive literals are represented as positive integers, negative literals as negative.
"""
function parse_3sat_from_markdown(filename::String)
    if !isfile(filename)
        error("File not found: $filename")
    end
    
    lines = readlines(filename)
    num_variables = 0
    clauses = Vector{Vector{Int}}()
    
    in_clauses_section = false
    
    for line in lines
        # Skip empty lines and markdown formatting
        line = strip(line)
        if isempty(line) || startswith(line, "#") || startswith(line, "-")
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
            clause = parse_clause_from_line(String(line))  # Convert to String
            if !isempty(clause)
                push!(clauses, clause)
            end
        end
    end
    
    return num_variables, clauses
end

"""
    parse_clause_from_line(line::String) -> Vector{Int}

Parse a single clause from a markdown line like "1. (x₁ ∨ ¬x₂ ∨ x₃)"
Returns vector of literals where positive = variable, negative = ¬variable.
"""
function parse_clause_from_line(line::String)
    clause = Int[]
    
    # Extract the part between parentheses
    paren_match = match(r"\(([^)]+)\)", line)
    if paren_match === nothing
        return clause
    end
    
    clause_content = paren_match.captures[1]
    
    # Split by ∨ (or | for alternative format) and parse each literal
    # Handle both Unicode ∨ and ASCII |
    literals = split(clause_content, r"[∨|]")
    
    for literal in literals
        literal = strip(literal)
        
        # Check for negation - handle both ¬ and ASCII ~
        is_negative = false
        if startswith(literal, "¬") || startswith(literal, "~")
            is_negative = true
            # Remove negation symbol - handle Unicode properly
            if startswith(literal, "¬")
                literal = literal[nextind(literal, 1):end]  # Unicode-safe
            else
                literal = literal[2:end]  # ASCII ~
            end
        end
        
        # Extract variable number - simple regex for x followed by digits
        var_match = match(r"x(\d+)", literal)
        
        if var_match !== nothing
            var_num = parse(Int, var_match.captures[1])
            push!(clause, is_negative ? -var_num : var_num)
        end
    end
    
    return clause
end

"""
    solve_3sat(filename::String; timeout::Float64=30.0) -> SATResult

Solve a 3-SAT instance from a markdown file using CryptoMiniSat.
Returns a SATResult with satisfiability, solution, and solving statistics.
"""
function solve_3sat(filename::String; timeout::Float64=30.0)
    result = SATResult()
    start_time = time()  # Define start_time at the beginning
    
    try
        # Parse the 3-SAT instance
        num_variables, clauses = parse_3sat_from_markdown(filename)
        
    if num_variables == 0 || isempty(clauses)
        # If variable count wasn't found in metadata, infer from clauses
        if !isempty(clauses) && num_variables == 0
            max_var = 0
            for clause in clauses
                for literal in clause
                    max_var = max(max_var, abs(literal))
                end
            end
            num_variables = max_var
            @info "Variable count not found in metadata, inferred $num_variables variables from clauses"
        end
        
        if num_variables == 0 || isempty(clauses)
            @warn "Could not parse 3-SAT instance from $filename"
            return result
        end
    end
        
        println("📊 Solving 3-SAT instance: $num_variables variables, $(length(clauses)) clauses")
        
        # Create SAT solver instance
        solver = CryptoMiniSat.CMS()
        
        # Add variables
        CryptoMiniSat.new_vars(solver, num_variables)
        
        # Add clauses
        for clause in clauses
            # CryptoMiniSat expects 1-based indexing with positive/negative integers
            CryptoMiniSat.add_clause(solver, clause)
        end
        
        # Solve
        solve_start = time()
        sat_result = CryptoMiniSat.solve(solver)
        solve_time = time() - solve_start
        
        result.solve_time = solve_time
        
        if sat_result == true
            result.satisfiable = true
            
            # Get solution
            model = CryptoMiniSat.get_model(solver)
            # CryptoMiniSat returns 0-based model, convert to 1-based for our usage
            solution = Bool[]
            for i in 1:num_variables
                push!(solution, model[i])  # model is 0-based, so i maps to i-1 in model
            end
            result.solution = solution
            
            println("✅ SATISFIABLE (solved in $(round(solve_time, digits=3))s)")
            
        elseif sat_result == false
            result.satisfiable = false
            println("❌ UNSATISFIABLE (solved in $(round(solve_time, digits=3))s)")
            
        else
            println("⏱️  TIMEOUT or UNKNOWN result after $(round(solve_time, digits=3))s")
        end
        
    catch e
        @error "Error solving SAT instance: $e"
        result.solve_time = time() - start_time
    end
    
    return result
end

"""
    verify_solution(filename::String, solution::Vector{Bool}) -> Bool

Verify that a solution satisfies all clauses in the 3-SAT instance.
"""
function verify_solution(filename::String, solution::Vector{Bool})
    try
        num_variables, clauses = parse_3sat_from_markdown(filename)
        
        if length(solution) != num_variables
            @warn "Solution length ($(length(solution))) doesn't match number of variables ($num_variables)"
            return false
        end
        
        for (i, clause) in enumerate(clauses)
            satisfied = false
            
            for literal in clause
                var_idx = abs(literal)
                var_value = solution[var_idx]
                
                # Check if this literal satisfies the clause
                if (literal > 0 && var_value) || (literal < 0 && !var_value)
                    satisfied = true
                    break
                end
            end
            
            if !satisfied
                @warn "Clause $i is not satisfied: $clause"
                return false
            end
        end
        
        return true
        
    catch e
        @error "Error verifying solution: $e"
        return false
    end
end

"""
    solve_and_update_markdown(filename::String; timeout::Float64=30.0)

Solve a 3-SAT instance and update the markdown file with the results.
Adds satisfiability information and solution to the metadata section.
"""
function solve_and_update_markdown(filename::String; timeout::Float64=30.0)
    if !isfile(filename)
        error("File not found: $filename")
    end
    
    # Solve the instance
    result = solve_3sat(filename, timeout=timeout)
    
    # Read the current file
    content = read(filename, String)
    lines = split(content, '\n')
    
    # Find and update the metadata section
    updated_lines = String[]
    in_metadata = false
    metadata_updated = false
    
    for line in lines
        if contains(line, "## Metadata")
            in_metadata = true
            push!(updated_lines, line)
        elseif startswith(line, "##") && in_metadata
            # End of metadata section, add SAT results before next section
            if !metadata_updated
                push!(updated_lines, "- Satisfiable: $(result.satisfiable ? "YES" : "NO")")
                push!(updated_lines, "- Solve time: $(round(result.solve_time, digits=3))s")
                
                if result.satisfiable && result.solution !== nothing
                    solution_str = join(["x$i=$(result.solution[i] ? "T" : "F")" for i in 1:length(result.solution)], ", ")
                    push!(updated_lines, "- Solution: $solution_str")
                end
                
                metadata_updated = true
            end
            in_metadata = false
            push!(updated_lines, line)
        elseif in_metadata && (contains(line, "Satisfiable:") || contains(line, "Solve time:") || contains(line, "Solution:"))
            # Skip existing SAT results
            continue
        else
            push!(updated_lines, line)
        end
    end
    
    # If we didn't find a metadata section or didn't update, add at the end
    if !metadata_updated
        push!(updated_lines, "")
        push!(updated_lines, "## SAT Solving Results")
        push!(updated_lines, "- Satisfiable: $(result.satisfiable ? "YES" : "NO")")
        push!(updated_lines, "- Solve time: $(round(result.solve_time, digits=3))s")
        
        if result.satisfiable && result.solution !== nothing
            solution_str = join(["x$i=$(result.solution[i] ? "T" : "F")" for i in 1:length(result.solution)], ", ")
            push!(updated_lines, "- Solution: $solution_str")
        end
    end
    
    # Write the updated content back
    write(filename, join(updated_lines, '\n'))
    
    return result
end

"""
    batch_solve_directory(directory::String; pattern::String="*.md", timeout::Float64=30.0)

Solve all 3-SAT instances in a directory and update their markdown files.
Returns a summary of results.
"""
function batch_solve_directory(directory::String; pattern::String="*.md", timeout::Float64=30.0)
    if !isdir(directory)
        error("Directory not found: $directory")
    end
    
    # Find all matching files
    files = filter(f -> endswith(f, ".md"), readdir(directory, join=true))
    
    if isempty(files)
        println("No markdown files found in $directory")
        return
    end
    
    println("🔍 Found $(length(files)) 3-SAT instances to solve...")
    
    results = []
    satisfiable_count = 0
    total_time = 0.0
    
    for filename in files
        println("\n📄 Processing: $(basename(filename))")
        
        try
            result = solve_and_update_markdown(filename, timeout=timeout)
            push!(results, (filename, result))
            
            if result.satisfiable
                satisfiable_count += 1
            end
            total_time += result.solve_time
            
        catch e
            @error "Failed to process $filename: $e"
        end
    end
    
    # Print summary
    println("\n" * "="^50)
    println("📊 BATCH SOLVING SUMMARY")
    println("="^50)
    println("Total instances: $(length(files))")
    println("Satisfiable: $satisfiable_count")
    println("Unsatisfiable: $(length(files) - satisfiable_count)")
    println("Total solve time: $(round(total_time, digits=3))s")
    println("Average solve time: $(round(total_time / length(files), digits=3))s")
    
    return results
end

# Export main functions
export SATResult, solve_3sat, verify_solution, solve_and_update_markdown, batch_solve_directory
export parse_3sat_from_markdown, parse_clause_from_line

println("📦 SAT Solver module loaded! Available functions:")
println("   - solve_3sat(filename): Solve a 3-SAT instance")
println("   - solve_and_update_markdown(filename): Solve and update file")
println("   - batch_solve_directory(directory): Solve all instances in directory")
println("   - verify_solution(filename, solution): Verify a solution")
