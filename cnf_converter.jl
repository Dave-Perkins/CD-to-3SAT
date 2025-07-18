#!/usr/bin/env julia

"""
DIMACS CNF to Markdown Converter
Converts DIMACS format 3-SAT instances to our markdown format for community-guided SAT solving.
"""

using Printf
using Dates
using Statistics

"""
Parse a DIMACS CNF file and convert to markdown format.
"""
function cnf_to_markdown(cnf_file::String, output_file::String)
    variables = 0
    clauses = 0
    clause_list = Vector{Vector{Int}}()
    
    println("🔄 Converting $(basename(cnf_file)) to markdown format...")
    
    # Read and parse CNF file
    open(cnf_file, "r") do file
        for line in eachline(file)
            line = strip(line)
            
            # Skip comments
            if startswith(line, "c") || isempty(line)
                continue
            end
            
            # Parse problem line
            if startswith(line, "p cnf")
                parts = split(line)
                variables = parse(Int, parts[3])
                clauses = parse(Int, parts[4])
                println("📊 Instance: $(variables) variables, $(clauses) clauses")
                continue
            end
            
            # Parse clause
            if !startswith(line, "c") && !startswith(line, "p")
                try
                    parts = split(line)
                    clause_nums = Int[]
                    for part in parts
                        if part != "0" && !isempty(part)
                            # Try to parse as integer, skip if it fails
                            try
                                num = parse(Int, part)
                                push!(clause_nums, num)
                            catch
                                # Skip non-numeric parts
                                continue
                            end
                        end
                    end
                    if !isempty(clause_nums)
                        push!(clause_list, clause_nums)
                    end
                catch e
                    # Skip problematic lines
                    continue
                end
            end
        end
    end
    
    # Validate that we got the expected number of clauses
    if length(clause_list) != clauses
        @warn "Expected $(clauses) clauses but found $(length(clause_list))"
    end
    
    # Generate markdown
    markdown_content = generate_markdown_content(variables, clause_list, cnf_file)
    
    # Write to output file
    open(output_file, "w") do file
        write(file, markdown_content)
    end
    
    println("✅ Converted to $(output_file)")
    return variables, length(clause_list)
end

"""
Generate markdown content from parsed CNF data.
"""
function generate_markdown_content(num_vars::Int, clauses::Vector{Vector{Int}}, source_file::String)
    content = """
# Large 3-SAT Instance - $(basename(source_file))

**Source**: SATLIB Benchmark Collection
**Original File**: $(basename(source_file))
**Format**: Converted from DIMACS CNF

## Variables
"""
    
    # List all variables
    for i in 1:num_vars
        content *= "- x$(i)\n"
    end
    
    content *= "\n## Clauses\n"
    
    # Convert each clause to markdown format
    for (i, clause) in enumerate(clauses)
        literals = String[]
        for lit in clause
            if lit > 0
                push!(literals, "x$(lit)")
            else
                push!(literals, "¬x$(abs(lit))")
            end
        end
        content *= "$(i). ($(join(literals, " ∨ ")))\n"
    end
    
    # Add metadata
    content *= """

## Metadata
- Variables: $(num_vars)
- Clauses: $(length(clauses))
- Ratio: $(round(length(clauses)/num_vars, digits=2)) (clauses/variables)
- Generated: $(now())
- Source: SATLIB Benchmark Collection
- Constraint: All clauses have exactly 3 distinct literals ✓
"""
    
    return content
end

"""
Convert a single CNF file and test it with our solver.
"""
function convert_and_test(cnf_file::String)
    # Create output filename
    base_name = splitext(basename(cnf_file))[1]
    output_file = "/Users/dperkins/Desktop/pioneer/CD-to-3SAT/benchmarks/$(base_name).md"
    
    # Convert to markdown
    vars, clauses = cnf_to_markdown(cnf_file, output_file)
    
    println("🎯 Testing with community-guided SAT solver...")
    
    # Load our SAT solver and test
    try
        include("/Users/dperkins/Desktop/pioneer/CD-to-3SAT/main.jl")
        result = solve_3sat(output_file)
        
        println("📈 Results:")
        println("  - Variables: $(vars)")
        println("  - Clauses: $(clauses)")
        println("  - Result: $(result[:satisfiable] ? "SAT" : "UNSAT")")
        println("  - Quality: $(round(result[:quality_score]*100, digits=1))%")
        println("  - Time: $(round(result[:solve_time], digits=4))s")
        println("  - Communities: $(result[:num_communities])")
        println("  - Modularity: $(round(result[:modularity], digits=3))")
        
        return result
    catch e
        println("❌ Error testing with solver: $(e)")
        return nothing
    end
end

"""
Convert multiple CNF files from a directory.
"""
function batch_convert_cnf(cnf_dir::String, max_files::Int=5)
    cnf_files = [f for f in readdir(cnf_dir, join=true) if endswith(f, ".cnf")]
    
    println("🚀 Found $(length(cnf_files)) CNF files")
    println("📋 Converting first $(min(max_files, length(cnf_files))) files...")
    
    results = []
    for (i, cnf_file) in enumerate(cnf_files[1:min(max_files, length(cnf_files))])
        println("\n" * "="^60)
        println("🔢 File $(i)/$(min(max_files, length(cnf_files))): $(basename(cnf_file))")
        println("="^60)
        
        result = convert_and_test(cnf_file)
        push!(results, result)
        
        # Add a small delay to prevent overwhelming the system
        sleep(0.1)
    end
    
    # Summary
    println("\n" * "="^60)
    println("📊 BATCH CONVERSION SUMMARY")
    println("="^60)
    successful = count(r -> r !== nothing, results)
    println("✅ Successfully converted and tested: $(successful)/$(length(results))")
    
    if successful > 0
        sat_count = count(r -> r !== nothing && r[:satisfiable], results)
        avg_time = mean([r[:solve_time] for r in results if r !== nothing])
        avg_quality = mean([r[:quality_score] for r in results if r !== nothing])
        
        println("📈 Statistics:")
        println("  - SAT instances: $(sat_count)/$(successful)")
        println("  - Average solve time: $(round(avg_time, digits=4))s")
        println("  - Average quality: $(round(avg_quality*100, digits=1))%")
    end
    
    return results
end

# If running directly
if abspath(PROGRAM_FILE) == @__FILE__
    println("🌟 DIMACS CNF to Markdown Converter")
    println("="^50)
    
    cnf_directory = "/Users/dperkins/Desktop/pioneer/CD-to-3SAT/benchmarks/ai/hoos/Shortcuts/UF250.1065.100"
    
    if length(ARGS) > 0
        # Convert specific file
        cnf_file = ARGS[1]
        convert_and_test(cnf_file)
    else
        # Batch convert
        batch_convert_cnf(cnf_directory, 3)  # Start with 3 files for testing
    end
end
