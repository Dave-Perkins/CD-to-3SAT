"""
DIMACS Format Support Module

Provides import/export functionality for DIMACS CNF format, the standard
interchange format for SAT problems in the research community.

DIMACS Format:
- Comments start with 'c'
- Problem line: 'p cnf <variables> <clauses>'
- Clauses: space-separated literals ending with 0
- Positive integers = positive literals, negative = negated literals
"""

using Dates

"""
    parse_dimacs(filename::String) -> (Int, Vector{Vector{Int}})

Parse a DIMACS CNF file and return (num_variables, clauses).
Each clause is a vector of literals (positive/negative integers).
"""
function parse_dimacs(filename::String)
    if !isfile(filename)
        error("DIMACS file not found: $filename")
    end
    
    lines = readlines(filename)
    num_variables = 0
    num_clauses = 0
    clauses = Vector{Vector{Int}}()
    
    for line in lines
        line = strip(line)
        
        # Skip empty lines and comments
        if isempty(line) || startswith(line, "c")
            continue
        end
        
        # Parse problem line
        if startswith(line, "p cnf")
            parts = split(line)
            if length(parts) >= 4
                num_variables = parse(Int, parts[3])
                num_clauses = parse(Int, parts[4])
                println("📋 DIMACS: $num_variables variables, $num_clauses clauses")
            end
            continue
        end
        
        # Parse clause line
        if !isempty(line) && !startswith(line, "p") && !startswith(line, "c")
            literals = Int[]
            for token in split(line)
                if !isempty(token)
                    lit = parse(Int, token)
                    if lit == 0
                        break  # End of clause
                    end
                    push!(literals, lit)
                end
            end
            
            if !isempty(literals)
                push!(clauses, literals)
            end
        end
    end
    
    # Validate
    if length(clauses) != num_clauses
        @warn "Expected $num_clauses clauses, found $(length(clauses))"
    end
    
    println("✅ Parsed DIMACS: $num_variables variables, $(length(clauses)) clauses")
    return num_variables, clauses
end

"""
    export_to_dimacs(markdown_file::String, dimacs_file::String; comment::String="")

Convert a markdown 3-SAT instance to DIMACS format.
"""
function export_to_dimacs(markdown_file::String, dimacs_file::String; comment::String="")
    # Parse the markdown file using existing function
    num_variables, clauses = parse_3sat_from_markdown(markdown_file)
    
    # Apply variable count fallback if needed
    if num_variables == 0 && !isempty(clauses)
        max_var = 0
        for clause in clauses
            for literal in clause
                max_var = max(max_var, abs(literal))
            end
        end
        num_variables = max_var
        @info "Variable count inferred from clauses: $num_variables variables"
    end
    
    if num_variables == 0 || isempty(clauses)
        error("Could not parse 3-SAT instance from $markdown_file")
    end
    
    # Write DIMACS format
    open(dimacs_file, "w") do io
        # Write comments
        println(io, "c DIMACS CNF format")
        println(io, "c Generated from: $(basename(markdown_file))")
        if !isempty(comment)
            println(io, "c $comment")
        end
        println(io, "c Generated on: $(Dates.now())")
        println(io, "c")
        
        # Write problem line
        println(io, "p cnf $num_variables $(length(clauses))")
        
        # Write clauses
        for clause in clauses
            clause_str = join(clause, " ") * " 0"
            println(io, clause_str)
        end
    end
    
    println("💾 Exported to DIMACS: $dimacs_file")
    return dimacs_file
end

"""
    import_dimacs_to_markdown(dimacs_file::String, markdown_file::String; title::String="")

Convert a DIMACS CNF file to markdown format.
"""
function import_dimacs_to_markdown(dimacs_file::String, markdown_file::String; title::String="")
    num_variables, clauses = parse_dimacs(dimacs_file)
    
    if num_variables == 0 || isempty(clauses)
        error("Could not parse DIMACS file: $dimacs_file")
    end
    
    # Generate title if not provided
    if isempty(title)
        base_name = splitext(basename(dimacs_file))[1]
        title = "Imported from $base_name"
    end
    
    # Convert to markdown format
    open(markdown_file, "w") do io
        println(io, "# $title")
        println(io, "")
        println(io, "## Variables")
        
        # List variables
        for i in 1:num_variables
            print(io, "- x$i")
            if i < num_variables
                println(io, "")
            else
                println(io, "")
            end
        end
        
        println(io, "")
        println(io, "## Clauses")
        
        # Convert clauses to readable format
        for (i, clause) in enumerate(clauses)
            clause_str = "("
            for (j, literal) in enumerate(clause)
                if literal > 0
                    clause_str *= "x$literal"
                else
                    clause_str *= "¬x$(abs(literal))"
                end
                
                if j < length(clause)
                    clause_str *= " ∨ "
                end
            end
            clause_str *= ")"
            
            println(io, "$i. $clause_str")
        end
        
        println(io, "")
        println(io, "## Metadata")
        println(io, "- Variables: $num_variables")
        println(io, "- Clauses: $(length(clauses))")
        println(io, "- Ratio: $(round(length(clauses) / num_variables, digits=2)) (clauses/variables)")
        println(io, "- Source: $(basename(dimacs_file))")
        println(io, "- Imported: $(Dates.now())")
    end
    
    println("📝 Imported to markdown: $markdown_file")
    return markdown_file
end

"""
    batch_export_to_dimacs(markdown_dir::String, dimacs_dir::String)

Export all markdown 3-SAT files in a directory to DIMACS format.
"""
function batch_export_to_dimacs(markdown_dir::String, dimacs_dir::String)
    if !isdir(markdown_dir)
        error("Source directory not found: $markdown_dir")
    end
    
    # Create output directory if it doesn't exist
    if !isdir(dimacs_dir)
        mkpath(dimacs_dir)
        println("📁 Created directory: $dimacs_dir")
    end
    
    # Find all markdown files
    md_files = filter(f -> endswith(f, ".md"), readdir(markdown_dir, join=true))
    
    if isempty(md_files)
        println("No markdown files found in $markdown_dir")
        return
    end
    
    println("🔄 Converting $(length(md_files)) markdown files to DIMACS...")
    
    converted = 0
    for md_file in md_files
        try
            # Generate DIMACS filename
            base_name = splitext(basename(md_file))[1]
            dimacs_file = joinpath(dimacs_dir, base_name * ".cnf")
            
            # Convert
            export_to_dimacs(md_file, dimacs_file, comment="Batch export from $(basename(markdown_dir))")
            converted += 1
            
        catch e
            @warn "Failed to convert $(basename(md_file)): $e"
        end
    end
    
    println("✅ Successfully converted $converted/$(length(md_files)) files")
    return converted
end

"""
    batch_import_from_dimacs(dimacs_dir::String, markdown_dir::String)

Import all DIMACS CNF files in a directory to markdown format.
"""
function batch_import_from_dimacs(dimacs_dir::String, markdown_dir::String)
    if !isdir(dimacs_dir)
        error("Source directory not found: $dimacs_dir")
    end
    
    # Create output directory if it doesn't exist
    if !isdir(markdown_dir)
        mkpath(markdown_dir)
        println("📁 Created directory: $markdown_dir")
    end
    
    # Find all DIMACS files
    cnf_files = filter(f -> endswith(f, ".cnf"), readdir(dimacs_dir, join=true))
    
    if isempty(cnf_files)
        println("No DIMACS (.cnf) files found in $dimacs_dir")
        return
    end
    
    println("🔄 Converting $(length(cnf_files)) DIMACS files to markdown...")
    
    converted = 0
    for cnf_file in cnf_files
        try
            # Generate markdown filename
            base_name = splitext(basename(cnf_file))[1]
            md_file = joinpath(markdown_dir, base_name * ".md")
            
            # Convert
            import_dimacs_to_markdown(cnf_file, md_file)
            converted += 1
            
        catch e
            @warn "Failed to convert $(basename(cnf_file)): $e"
        end
    end
    
    println("✅ Successfully converted $converted/$(length(cnf_files)) files")
    return converted
end

"""
    solve_dimacs(dimacs_file::String; timeout::Float64=30.0) -> SATResult

Solve a DIMACS CNF file directly using CryptoMiniSat.
"""
function solve_dimacs(dimacs_file::String; timeout::Float64=30.0)
    result = SATResult()
    start_time = time()
    
    try
        # Parse DIMACS file
        num_variables, clauses = parse_dimacs(dimacs_file)
        
        if num_variables == 0 || isempty(clauses)
            @warn "Could not parse DIMACS file: $dimacs_file"
            return result
        end
        
        println("📊 Solving DIMACS instance: $num_variables variables, $(length(clauses)) clauses")
        
        # Create SAT solver instance
        solver = CryptoMiniSat.CMS()
        
        # Add variables
        CryptoMiniSat.new_vars(solver, num_variables)
        
        # Add clauses
        for clause in clauses
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
            solution = Bool[]
            for i in 1:num_variables
                push!(solution, model[i])
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
        @error "Error solving DIMACS instance: $e"
        result.solve_time = time() - start_time
    end
    
    return result
end

"""
    compare_formats(markdown_file::String)

Compare solving performance between markdown and DIMACS formats.
Useful for validating the conversion process.
"""
function compare_formats(markdown_file::String)
    if !isfile(markdown_file)
        error("Markdown file not found: $markdown_file")
    end
    
    println("🔬 Comparing solving performance: Markdown vs DIMACS")
    println("=" ^50)
    
    # Solve markdown format
    println("📝 Solving markdown format...")
    md_result = solve_3sat(markdown_file)
    
    # Convert to DIMACS and solve
    temp_dimacs = tempname() * ".cnf"
    try
        export_to_dimacs(markdown_file, temp_dimacs)
        
        println("\n📋 Solving DIMACS format...")
        dimacs_result = solve_dimacs(temp_dimacs)
        
        # Compare results
        println("\n" * "=" ^50)
        println("📊 COMPARISON RESULTS")
        println("=" ^50)
        println("Markdown format:")
        println("  Satisfiable: $(md_result.satisfiable)")
        println("  Solve time:  $(round(md_result.solve_time, digits=3))s")
        
        println("\nDIMACS format:")
        println("  Satisfiable: $(dimacs_result.satisfiable)")
        println("  Solve time:  $(round(dimacs_result.solve_time, digits=3))s")
        
        # Validation
        if md_result.satisfiable == dimacs_result.satisfiable
            println("\n✅ Results match - conversion validated!")
        else
            println("\n❌ Results differ - check conversion!")
        end
        
        # Performance comparison
        if md_result.solve_time > 0 && dimacs_result.solve_time > 0
            ratio = md_result.solve_time / dimacs_result.solve_time
            println("📈 Performance ratio (MD/DIMACS): $(round(ratio, digits=2))x")
        end
        
    finally
        # Clean up temporary file
        if isfile(temp_dimacs)
            rm(temp_dimacs)
        end
    end
end

# Export main functions
export parse_dimacs, export_to_dimacs, import_dimacs_to_markdown
export batch_export_to_dimacs, batch_import_from_dimacs
export solve_dimacs, compare_formats

println("📦 DIMACS module loaded! Available functions:")
println("   - parse_dimacs(file): Parse DIMACS CNF file")
println("   - export_to_dimacs(md_file, cnf_file): Convert markdown → DIMACS")
println("   - import_dimacs_to_markdown(cnf_file, md_file): Convert DIMACS → markdown")
println("   - batch_export_to_dimacs(md_dir, cnf_dir): Batch convert to DIMACS")
println("   - solve_dimacs(cnf_file): Solve DIMACS file directly")
println("   - compare_formats(md_file): Validate conversion accuracy")
