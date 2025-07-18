#!/usr/bin/env julia

"""
Large Instance Batch Comparison - SATLIB Benchmarks
Streamlined comparison with minimal verbose output.
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
end

# Test single instance
function test_instance(cnf_file::String)
    base_name = splitext(basename(cnf_file))[1]
    md_file = "/Users/dperkins/Desktop/pioneer/CD-to-3SAT/benchmarks/$(base_name).md"
    
    # Convert if needed
    if !isfile(md_file)
        convert_cnf_to_md(cnf_file, md_file)
    end
    
    # Initialize variables
    cg_sat = false
    cg_success = false
    crypto_sat = false
    crypto_success = false
    
    # Test community-guided solver
    cg_time = @elapsed begin
        try
            cg_result = solve_3sat(md_file)
            cg_sat = cg_result.satisfiable
            cg_success = true
        catch
            cg_sat = false
            cg_success = false
        end
    end
    
    # Test CryptoMiniSat
    crypto_time = @elapsed begin
        try
            output = read(pipeline(`cryptominisat5 --verb=0 $cnf_file`), String)
            crypto_sat = occursin("s SATISFIABLE", output)
            crypto_success = true
        catch
            crypto_sat = false
            crypto_success = false
        end
    end
    
    return (
        name = base_name,
        cg_sat = cg_sat,
        crypto_sat = crypto_sat,
        cg_time = cg_time,
        crypto_time = crypto_time,
        agreement = cg_success && crypto_success && (cg_sat == crypto_sat),
        success = cg_success && crypto_success
    )
end

# Main batch comparison
function batch_compare(num_instances::Int=5)
    println("🚀 STREAMLINED BATCH COMPARISON")
    println("="^50)
    println("📦 SATLIB Benchmarks: 250 vars, 1065 clauses")
    println("🎯 Testing $(num_instances) instances")
    println()
    
    # Load solver
    print("🔧 Loading modules... ")
    if !load_solver_quietly()
        println("❌ Failed")
        return
    end
    println("✅")
    
    # Get files
    cnf_dir = "/Users/dperkins/Desktop/pioneer/CD-to-3SAT/benchmarks/ai/hoos/Shortcuts/UF250.1065.100"
    cnf_files = [f for f in readdir(cnf_dir, join=true) if endswith(f, ".cnf")]
    test_files = cnf_files[1:min(num_instances, length(cnf_files))]
    
    println("📋 Found $(length(cnf_files)) files, testing $(length(test_files))")
    println()
    
    # Process files
    results = []
    for (i, cnf_file) in enumerate(test_files)
        print("$(i)/$(length(test_files)) ")
        result = test_instance(cnf_file)
        
        if result.success
            status = result.agreement ? "✅" : "❌"
            speedup = result.crypto_time / result.cg_time
            println("$(result.name): $(status) CG:$(result.cg_sat ? "SAT" : "UNS")($(round(result.cg_time, digits=3))s) Crypto:$(result.crypto_sat ? "SAT" : "UNS")($(round(result.crypto_time, digits=3))s) [$(round(speedup, digits=1))x]")
        else
            println("$(result.name): ❌ ERROR")
        end
        
        push!(results, result)
    end
    
    # Summary
    println()
    println("="^50)
    println("📊 SUMMARY")
    println("="^50)
    
    successful = count(r -> r.success, results)
    agreements = count(r -> r.agreement, results)
    
    println("✅ Successful: $(successful)/$(length(results))")
    if successful > 0
        println("🎯 Agreement: $(agreements)/$(successful) ($(round(agreements/successful*100, digits=1))%)")
        
        cg_times = [r.cg_time for r in results if r.success]
        crypto_times = [r.crypto_time for r in results if r.success]
        
        if !isempty(cg_times)
            avg_cg = mean(cg_times)
            avg_crypto = mean(crypto_times)
            println("⚡ Avg Times: CG=$(round(avg_cg, digits=3))s, Crypto=$(round(avg_crypto, digits=3))s")
            println("🏃 Speed: CryptoMiniSat $(round(avg_crypto/avg_cg, digits=1))x $(avg_crypto > avg_cg ? "slower" : "faster")")
        end
        
        cg_sat = count(r -> r.success && r.cg_sat, results)
        crypto_sat = count(r -> r.success && r.crypto_sat, results)
        println("📈 SAT Rates: CG=$(round(cg_sat/successful*100, digits=1))%, Crypto=$(round(crypto_sat/successful*100, digits=1))%")
    end
    
    println("\n🏁 Complete!")
    return results
end

# Execute
if abspath(PROGRAM_FILE) == @__FILE__
    num = length(ARGS) > 0 ? parse(Int, ARGS[1]) : 3
    batch_compare(num)
end
