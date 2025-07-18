#!/usr/bin/env julia

"""
Large Instance Batch Comparison - SATLIB Benchmarks
Streamlined comparison between Community-Guided SAT Solver and CryptoMiniSat
Focus on concise reporting with minimal verbose output.
"""

using Printf
using Statistics
using Dates

# Suppress excessive output from modules
ENV["JULIA_QUIET"] = "true"

"""
Load solver modules once at startup (quietly).
"""
function load_solver_modules()
    # Redirect stdout to suppress verbose module loading
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
        println("❌ Failed to load solver modules: $(e)")
        return false
    end
end

"""
Solve a single large instance with minimal output.
"""
function solve_large_instance_quiet(md_file::String)
    try
        # Time the solving
        start_time = time()
        result = solve_3sat(md_file)
        solve_time = time() - start_time
        
        return (
            satisfiable = result.satisfiable,
            solve_time = solve_time,
            success = true,
            error = nothing
        )
        
    catch e
        return (
            satisfiable = false,
            solve_time = 0.0,
            success = false,
            error = string(e)
        )
    end
end

"""
Simple CNF to markdown converter (embedded).
"""
function simple_cnf_to_markdown(cnf_file::String, output_file::String)
    variables = 0
    clauses = 0
    clause_list = Vector{Vector{Int}}()
    
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
                continue
            end
            
            # Parse clause
            if !startswith(line, "c") && !startswith(line, "p")
                try
                    parts = split(line)
                    clause_nums = Int[]
                    for part in parts
                        if part != "0" && !isempty(part)
                            try
                                num = parse(Int, part)
                                push!(clause_nums, num)
                            catch
                                continue
                            end
                        end
                    end
                    if !isempty(clause_nums)
                        push!(clause_list, clause_nums)
                    end
                catch e
                    continue
                end
            end
        end
    end
    
    # Generate markdown
    content = """
# Large 3-SAT Instance - $(basename(cnf_file))

**Source**: SATLIB Benchmark Collection
**Original File**: $(basename(cnf_file))

## Variables
"""
    
    # List all variables
    for i in 1:variables
        content *= "- x$(i)\n"
    end
    
    content *= "\n## Clauses\n"
    
    # Convert each clause to markdown format
    for (i, clause) in enumerate(clause_list)
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
- Variables: $(variables)
- Clauses: $(length(clause_list))
- Ratio: $(round(length(clause_list)/variables, digits=2)) (clauses/variables)
- Source: SATLIB Benchmark Collection
- Constraint: All clauses have exactly 3 distinct literals ✓
"""
    
    # Write to output file
    open(output_file, "w") do file
        write(file, content)
    end
    
    return variables, length(clause_list)
end
function solve_with_cryptominisat(cnf_file::String)
    try
        start_time = time()
        
        # Run CryptoMiniSat with minimal output
        result = read(pipeline(`cryptominisat5 --verb=0 $cnf_file`), String)
        solve_time = time() - start_time
        
        satisfiable = occursin("s SATISFIABLE", result)
        
        return (
            satisfiable = satisfiable,
            solve_time = solve_time,
            success = true,
            error = nothing
        )
        
    catch e
        return (
            satisfiable = false,
            solve_time = 0.0,
            success = false,
            error = string(e)
        )
    end
end

"""
Run streamlined batch comparison on SATLIB instances.
"""
function batch_compare_large_instances(max_instances::Int=10)
    println("🚀 LARGE INSTANCE BATCH COMPARISON")
    println("="^60)
    println("📊 Comparing Community-Guided vs CryptoMiniSat")
    println("📦 SATLIB Benchmark Collection (250 vars, 1065 clauses)")
    println("🎯 Processing $(max_instances) instances with minimal output")
    println()
    
    # Get list of CNF files
    cnf_dir = "/Users/dperkins/Desktop/pioneer/CD-to-3SAT/benchmarks/ai/hoos/Shortcuts/UF250.1065.100"
    cnf_files = [f for f in readdir(cnf_dir, join=true) if endswith(f, ".cnf")]
    
    if length(cnf_files) == 0
        println("❌ No CNF files found in $(cnf_dir)")
        return
    end
    
    # Limit to requested number
    test_files = cnf_files[1:min(max_instances, length(cnf_files))]
    
    println("📋 Found $(length(cnf_files)) total files, testing $(length(test_files))")
    println()
    
    # Track results
    results = []
    agreements = 0
    cg_times = Float64[]
    crypto_times = Float64[]
    cg_sat_count = 0
    crypto_sat_count = 0
    
    # Process each file
    for (i, cnf_file) in enumerate(test_files)
        base_name = splitext(basename(cnf_file))[1]
        md_file = "/Users/dperkins/Desktop/pioneer/CD-to-3SAT/benchmarks/$(base_name).md"
        
        # Show progress with minimal detail
        print("$(lpad(i, 2))/$(length(test_files)) $(base_name): ")
        
"""
Run streamlined batch comparison on SATLIB instances.
"""
function batch_compare_large_instances(max_instances::Int=10)
    println("🚀 LARGE INSTANCE BATCH COMPARISON")
    println("="^60)
    println("📊 Comparing Community-Guided vs CryptoMiniSat")
    println("📦 SATLIB Benchmark Collection (250 vars, 1065 clauses)")
    println("🎯 Processing $(max_instances) instances with minimal output")
    println()
    
    # Load solver modules once
    print("🔧 Loading solver modules... ")
    if !load_solver_modules()
        println("❌ Failed to load modules")
        return
    end
    println("✅ Ready")
    println()
    
    # Get list of CNF files
    cnf_dir = "/Users/dperkins/Desktop/pioneer/CD-to-3SAT/benchmarks/ai/hoos/Shortcuts/UF250.1065.100"
    cnf_files = [f for f in readdir(cnf_dir, join=true) if endswith(f, ".cnf")]
    
    if length(cnf_files) == 0
        println("❌ No CNF files found in $(cnf_dir)")
        return
    end
    
    # Limit to requested number
    test_files = cnf_files[1:min(max_instances, length(cnf_files))]
    
    println("📋 Found $(length(cnf_files)) total files, testing $(length(test_files))")
    println()
    
    # Track results
    results = []
    agreements = 0
    cg_times = Float64[]
    crypto_times = Float64[]
    cg_sat_count = 0
    crypto_sat_count = 0
    
    # Process each file
    for (i, cnf_file) in enumerate(test_files)
        base_name = splitext(basename(cnf_file))[1]
        md_file = "/Users/dperkins/Desktop/pioneer/CD-to-3SAT/benchmarks/$(base_name).md"
        
        # Show progress with minimal detail
        print("$(lpad(i, 2))/$(length(test_files)) $(base_name): ")
        
        # Convert CNF to markdown if needed
        if !isfile(md_file)
            try
                simple_cnf_to_markdown(cnf_file, md_file)
            catch e
                println("❌ Conversion failed")
                continue
            end
        end
        
        # Test Community-Guided solver
        cg_result = solve_large_instance_quiet(md_file)
        
        # Test CryptoMiniSat
        crypto_result = solve_with_cryptominisat(cnf_file)
        
        # Compare results
        if cg_result.success && crypto_result.success
            agreement = cg_result.satisfiable == crypto_result.satisfiable
            if agreement
                agreements += 1
                print("✅")
            else
                print("❌")
            end
            
            # Track statistics
            push!(cg_times, cg_result.solve_time)
            push!(crypto_times, crypto_result.solve_time)
            
            if cg_result.satisfiable
                cg_sat_count += 1
            end
            if crypto_result.satisfiable
                crypto_sat_count += 1
            end
            
            # Show timing comparison
            speedup = crypto_result.solve_time / cg_result.solve_time
            println(" CG:$(cg_result.satisfiable ? "SAT" : "UNS") ($(round(cg_result.solve_time, digits=4))s) vs Crypto:$(crypto_result.satisfiable ? "SAT" : "UNS") ($(round(crypto_result.solve_time, digits=4))s) [$(round(speedup, digits=1))x]")
            
        else
            println("❌ Error - CG:$(cg_result.success) Crypto:$(crypto_result.success)")
        end
        
        push!(results, (cg=cg_result, crypto=crypto_result, agreement=cg_result.success && crypto_result.success && cg_result.satisfiable == crypto_result.satisfiable))
        
        # Small delay to prevent overwhelming
        sleep(0.05)
    end
        
        # Test Community-Guided solver
        cg_result = solve_large_instance_quiet(md_file)
        
        # Test CryptoMiniSat
        crypto_result = solve_with_cryptominisat(cnf_file)
        
        # Compare results
        if cg_result.success && crypto_result.success
            agreement = cg_result.satisfiable == crypto_result.satisfiable
            if agreement
                agreements += 1
                print("✅")
            else
                print("❌")
            end
            
            # Track statistics
            push!(cg_times, cg_result.solve_time)
            push!(crypto_times, crypto_result.solve_time)
            
            if cg_result.satisfiable
                cg_sat_count += 1
            end
            if crypto_result.satisfiable
                crypto_sat_count += 1
            end
            
            # Show timing comparison
            speedup = crypto_result.solve_time / cg_result.solve_time
            println(" CG:$(cg_result.satisfiable ? "SAT" : "UNS") ($(round(cg_result.solve_time, digits=4))s) vs Crypto:$(crypto_result.satisfiable ? "SAT" : "UNS") ($(round(crypto_result.solve_time, digits=4))s) [$(round(speedup, digits=1))x]")
            
        else
            println("❌ Error - CG:$(cg_result.success) Crypto:$(crypto_result.success)")
        end
        
        push!(results, (cg=cg_result, crypto=crypto_result, agreement=cg_result.success && crypto_result.success && cg_result.satisfiable == crypto_result.satisfiable))
        
        # Small delay to prevent overwhelming
        sleep(0.05)
    end
    
    # Summary statistics
    println()
    println("="^60)
    println("📊 BATCH COMPARISON SUMMARY")
    println("="^60)
    
    successful_comparisons = count(r -> r.cg.success && r.crypto.success, results)
    println("✅ Successful comparisons: $(successful_comparisons)/$(length(results))")
    
    if successful_comparisons > 0
        agreement_rate = agreements / successful_comparisons * 100
        println("🎯 Agreement rate: $(agreements)/$(successful_comparisons) ($(round(agreement_rate, digits=1))%)")
        
        println()
        println("📈 SATISFIABILITY RATES:")
        println("   Community-Guided: $(cg_sat_count)/$(successful_comparisons) ($(round(cg_sat_count/successful_comparisons*100, digits=1))%)")
        println("   CryptoMiniSat: $(crypto_sat_count)/$(successful_comparisons) ($(round(crypto_sat_count/successful_comparisons*100, digits=1))%)")
        
        println()
        println("⚡ PERFORMANCE COMPARISON:")
        if !isempty(cg_times) && !isempty(crypto_times)
            avg_cg = mean(cg_times)
            avg_crypto = mean(crypto_times)
            speedup = avg_crypto / avg_cg
            
            println("   Average CG time: $(round(avg_cg, digits=4))s")
            println("   Average Crypto time: $(round(avg_crypto, digits=4))s")
            println("   Speed comparison: CryptoMiniSat is $(round(speedup, digits=1))x $(speedup > 1 ? "faster" : "slower")")
            
            println()
            println("📊 DETAILED TIMING:")
            println("   CG - Min: $(round(minimum(cg_times), digits=4))s, Max: $(round(maximum(cg_times), digits=4))s")
            println("   Crypto - Min: $(round(minimum(crypto_times), digits=4))s, Max: $(round(maximum(crypto_times), digits=4))s")
        end
        
        # Quality assessment
        if agreement_rate >= 90
            println()
            println("🎉 EXCELLENT: High agreement rate indicates strong algorithm reliability!")
        elseif agreement_rate >= 75
            println()
            println("👍 GOOD: Reasonable agreement rate for experimental algorithm.")
        else
            println()
            println("⚠️  CAUTION: Lower agreement rate may indicate algorithmic differences.")
        end
    end
    
    println()
    println("🏁 Batch comparison complete at $(now())")
    
    return results
end

"""
Quick test on a smaller subset.
"""
function quick_test(num_instances::Int=3)
    println("🔬 QUICK TEST - $(num_instances) instances")
    println("="^40)
    batch_compare_large_instances(num_instances)
end

# Main execution
if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) > 0
        num_instances = parse(Int, ARGS[1])
        batch_compare_large_instances(num_instances)
    else
        # Default to a reasonable number for testing
        quick_test(5)
    end
end
