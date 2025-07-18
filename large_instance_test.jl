#!/usr/bin/env julia

"""
Large Instance Performance Test - SATLIB Benchmarks
Test community-guided SAT solver on large instances with minimal output.
"""

using Printf
using Statistics
using Dates

# Load solver modules quietly
function load_solver_quietly()
    original_stdout = stdout
    rd, wr = redirect_stdout()
    try
        include("/Users/dperkins/Desktop/pioneer/CD-to-3SAT/main.jl")
        redirect_stdout(original_stdout)
        close(wr)
        return true
    catch e
        redirect_stdout(original_stdout)
        close(wr)
        println("❌ Load error: $(e)")
        return false
    end
end

# Simple CNF to markdown converter
function convert_cnf_to_md(cnf_file::String, md_file::String)
    variables = 0
    clause_list = Vector{Vector{Int}}()
    
    open(cnf_file, "r") do file
        for line in eachline(file)
            line = strip(line)
            if startswith(line, "p cnf")
                variables = parse(Int, split(line)[3])
            elseif !startswith(line, "c") && !isempty(line)
                try
                    nums = [parse(Int, x) for x in split(line) if x != "0" && !isempty(x)]
                    if !isempty(nums)
                        push!(clause_list, nums)
                    end
                catch
                end
            end
        end
    end
    
    # Generate markdown
    content = "# Large 3-SAT Instance - $(basename(cnf_file))\n\n"
    content *= "## Variables\n"
    for i in 1:variables
        content *= "- x$(i)\n"
    end
    content *= "\n## Clauses\n"
    for (i, clause) in enumerate(clause_list)
        literals = [lit > 0 ? "x$(lit)" : "¬x$(abs(lit))" for lit in clause]
        content *= "$(i). ($(join(literals, " ∨ ")))\n"
    end
    content *= "\n## Metadata\n- Variables: $(variables)\n- Clauses: $(length(clause_list))\n"
    
    open(md_file, "w") do f
        write(f, content)
    end
    
    return variables, length(clause_list)
end

# Test single instance
function test_large_instance(cnf_file::String)
    base_name = splitext(basename(cnf_file))[1]
    md_file = "/Users/dperkins/Desktop/pioneer/CD-to-3SAT/benchmarks/$(base_name).md"
    
    # Convert if needed
    vars, clauses = 0, 0
    if !isfile(md_file)
        try
            vars, clauses = convert_cnf_to_md(cnf_file, md_file)
        catch e
            return (name=base_name, success=false, error="Conversion failed: $(e)")
        end
    else
        # Parse existing file for stats
        content = read(md_file, String)
        vars_match = match(r"Variables: (\d+)", content)
        clauses_match = match(r"Clauses: (\d+)", content)
        vars = vars_match !== nothing ? parse(Int, vars_match[1]) : 0
        clauses = clauses_match !== nothing ? parse(Int, clauses_match[1]) : 0
    end
    
    # Test community-guided solver
    try
        start_time = time()
        result = solve_3sat(md_file)
        solve_time = time() - start_time
        
        return (
            name = base_name,
            variables = vars,
            clauses = clauses,
            satisfiable = result.satisfiable,
            solve_time = solve_time,
            success = true,
            error = nothing
        )
    catch e
        return (
            name = base_name,
            variables = vars,
            clauses = clauses,
            satisfiable = false,
            solve_time = 0.0,
            success = false,
            error = string(e)
        )
    end
end

# Main performance test
function test_large_instances(num_instances::Int=5)
    println("🚀 LARGE INSTANCE PERFORMANCE TEST")
    println("="^50)
    println("📦 SATLIB Benchmarks: Community-Guided SAT Solver")
    println("🎯 Testing $(num_instances) instances (250 vars, 1065 clauses)")
    println()
    
    # Load solver
    print("🔧 Loading solver modules... ")
    if !load_solver_quietly()
        println("❌ Failed to load solver")
        return
    end
    println("✅")
    
    # Get files
    cnf_dir = "/Users/dperkins/Desktop/pioneer/CD-to-3SAT/benchmarks/ai/hoos/Shortcuts/UF250.1065.100"
    cnf_files = [f for f in readdir(cnf_dir, join=true) if endswith(f, ".cnf")]
    test_files = cnf_files[1:min(num_instances, length(cnf_files))]
    
    println("📋 Found $(length(cnf_files)) total files, testing $(length(test_files))")
    println()
    
    # Process files
    results = []
    sat_count = 0
    unsat_count = 0
    total_time = 0.0
    
    for (i, cnf_file) in enumerate(test_files)
        print("$(lpad(i, 2))/$(length(test_files)) ")
        result = test_large_instance(cnf_file)
        
        if result.success
            status_symbol = result.satisfiable ? "✅ SAT" : "❌ UNSAT"
            println("$(result.name): $(status_symbol) ($(round(result.solve_time, digits=4))s)")
            
            if result.satisfiable
                sat_count += 1
            else
                unsat_count += 1
            end
            total_time += result.solve_time
        else
            println("$(result.name): ❌ ERROR - $(result.error)")
        end
        
        push!(results, result)
    end
    
    # Summary
    println()
    println("="^50)
    println("📊 PERFORMANCE SUMMARY")
    println("="^50)
    
    successful = count(r -> r.success, results)
    println("✅ Successfully solved: $(successful)/$(length(results))")
    
    if successful > 0
        println("📈 Results:")
        println("   • SAT instances: $(sat_count)")
        println("   • UNSAT instances: $(unsat_count)")
        println("   • SAT rate: $(round(sat_count/successful*100, digits=1))%")
        
        times = [r.solve_time for r in results if r.success]
        if !isempty(times)
            println()
            println("⚡ Performance:")
            println("   • Total time: $(round(total_time, digits=3))s")
            println("   • Average time: $(round(mean(times), digits=4))s")
            println("   • Min time: $(round(minimum(times), digits=4))s")
            println("   • Max time: $(round(maximum(times), digits=4))s")
            println("   • Throughput: $(round(successful/total_time, digits=1)) instances/second")
        end
        
        # Performance assessment
        avg_time = mean(times)
        if avg_time < 0.01
            println("\n🎉 EXCELLENT: Very fast solving (< 0.01s average)")
        elseif avg_time < 0.1
            println("\n👍 GOOD: Fast solving (< 0.1s average)")
        elseif avg_time < 1.0
            println("\n✅ ACCEPTABLE: Reasonable solving time (< 1s average)")
        else
            println("\n⚠️  SLOW: Consider optimization for large instances")
        end
        
        # Scale projection
        if successful >= 3
            estimated_100_time = 100 * mean(times)
            println("\n🔮 Projection: 100 instances ≈ $(round(estimated_100_time, digits=1))s")
        end
    end
    
    println("\n🏁 Performance test complete!")
    return results
end

# Execute
if abspath(PROGRAM_FILE) == @__FILE__
    num = length(ARGS) > 0 ? parse(Int, ARGS[1]) : 5
    test_large_instances(num)
end
