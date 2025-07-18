using Pkg
Pkg.activate(".")

include("src/community_guided_sat.jl")

"""
Comprehensive batch comparison between Community-Guided SAT and CryptoMiniSat
"""

function run_batch_comparison(input_files::Vector{String}; verbose_individual=false)
    println("🔄 BATCH SAT SOLVER COMPARISON")
    println("Community-Guided Algorithm vs CryptoMiniSat")
    println("=" ^ 70)
    
    results = []
    total_files = length(input_files)
    
    # Statistics tracking
    agreements = 0
    disagreements = 0
    cg_sat_count = 0
    crypto_sat_count = 0
    cg_times = Float64[]
    crypto_times = Float64[]
    quality_scores = Float64[]
    
    println("Processing $total_files files...\n")
    
    for (i, filepath) in enumerate(input_files)
        filename = basename(filepath)
        print("[$i/$total_files] $filename: ")
        
        try
            # Run community-guided solver
            cg_result = community_guided_sat_solve(filepath, use_v2_algorithm=true, verbose=verbose_individual)
            
            if cg_result === nothing
                println("❌ Failed to solve")
                continue
            end
            
            # Extract results
            cg_satisfiable = cg_result.satisfiable
            cg_time = cg_result.solve_time
            traditional_result = cg_result.traditional_sat_result
            
            if traditional_result === nothing
                println("⚠️  No traditional solver result")
                continue
            end
            
            crypto_satisfiable = traditional_result.satisfiable
            crypto_time = traditional_result.solve_time
            
            # Check agreement
            agreement = (cg_satisfiable == crypto_satisfiable)
            
            # Get quality score if available
            quality_score = nothing
            if cg_result.assignment_quality !== nothing
                quality_score = cg_result.assignment_quality.satisfaction_rate * 100
                push!(quality_scores, quality_score)
            end
            
            # Update statistics
            if agreement
                agreements += 1
                print("✅ ")
            else
                disagreements += 1
                print("❌ ")
            end
            
            if cg_satisfiable
                cg_sat_count += 1
            end
            if crypto_satisfiable
                crypto_sat_count += 1
            end
            
            push!(cg_times, cg_time)
            push!(crypto_times, crypto_time)
            
            # Print result summary
            cg_status = cg_satisfiable ? "SAT" : "UNSAT"
            crypto_status = crypto_satisfiable ? "SAT" : "UNSAT"
            
            quality_str = quality_score !== nothing ? " ($(round(quality_score, digits=1))%)" : ""
            
            println("CG: $cg_status$(quality_str), Crypto: $crypto_status, Times: $(round(cg_time, digits=4))s vs $(round(crypto_time, digits=4))s")
            
            # Store detailed result
            push!(results, (
                filename = filename,
                cg_satisfiable = cg_satisfiable,
                crypto_satisfiable = crypto_satisfiable,
                agreement = agreement,
                cg_time = cg_time,
                crypto_time = crypto_time,
                quality_score = quality_score,
                speedup = crypto_time / cg_time
            ))
            
        catch e
            println("💥 Error: $e")
        end
    end
    
    # Print comprehensive summary
    println("\n" * repeat("=", 70))
    println("📊 COMPREHENSIVE COMPARISON SUMMARY")
    println(repeat("=", 70))
    
    total_processed = length(results)
    
    if total_processed == 0
        println("No files successfully processed!")
        return results
    end
    
    # Agreement statistics
    agreement_rate = (agreements / total_processed) * 100
    println("🎯 AGREEMENT ANALYSIS:")
    println("   • Total processed: $total_processed files")
    println("   • Agreements: $agreements ($(round(agreement_rate, digits=1))%)")
    println("   • Disagreements: $disagreements ($(round(100-agreement_rate, digits=1))%)")
    
    # Satisfiability statistics
    cg_sat_rate = (cg_sat_count / total_processed) * 100
    crypto_sat_rate = (crypto_sat_count / total_processed) * 100
    
    println("\n📈 SATISFIABILITY RATES:")
    println("   • Community-Guided: $cg_sat_count/$total_processed ($(round(cg_sat_rate, digits=1))%)")
    println("   • CryptoMiniSat: $crypto_sat_count/$total_processed ($(round(crypto_sat_rate, digits=1))%)")
    
    # Performance statistics
    avg_cg_time = sum(cg_times) / length(cg_times)
    avg_crypto_time = sum(crypto_times) / length(crypto_times)
    avg_speedup = avg_crypto_time / avg_cg_time
    
    println("\n⚡ PERFORMANCE COMPARISON:")
    println("   • Avg CG time: $(round(avg_cg_time, digits=4))s")
    println("   • Avg Crypto time: $(round(avg_crypto_time, digits=4))s")
    println("   • Average speedup: $(round(avg_speedup, digits=1))x faster")
    
    # Quality analysis
    if !isempty(quality_scores)
        avg_quality = sum(quality_scores) / length(quality_scores)
        min_quality = minimum(quality_scores)
        max_quality = maximum(quality_scores)
        
        println("\n🎯 ASSIGNMENT QUALITY (CG Algorithm):")
        println("   • Average clause satisfaction: $(round(avg_quality, digits=1))%")
        println("   • Range: $(round(min_quality, digits=1))% - $(round(max_quality, digits=1))%")
        
        # Quality in disagreement cases
        disagreement_qualities = [r.quality_score for r in results if !r.agreement && r.quality_score !== nothing]
        if !isempty(disagreement_qualities)
            avg_disagreement_quality = sum(disagreement_qualities) / length(disagreement_qualities)
            println("   • Avg quality in disagreements: $(round(avg_disagreement_quality, digits=1))%")
        end
    end
    
    # Detailed disagreement analysis
    if disagreements > 0
        println("\n🔍 DISAGREEMENT ANALYSIS:")
        disagreement_cases = [r for r in results if !r.agreement]
        
        cg_sat_crypto_unsat = length([r for r in disagreement_cases if r.cg_satisfiable && !r.crypto_satisfiable])
        cg_unsat_crypto_sat = length([r for r in disagreement_cases if !r.cg_satisfiable && r.crypto_satisfiable])
        
        println("   • CG says SAT, Crypto says UNSAT: $cg_sat_crypto_unsat")
        println("   • CG says UNSAT, Crypto says SAT: $cg_unsat_crypto_sat")
        
        if cg_unsat_crypto_sat > 0
            println("\n   Files where CG missed solutions:")
            for r in disagreement_cases
                if !r.cg_satisfiable && r.crypto_satisfiable
                    quality_str = r.quality_score !== nothing ? " ($(round(r.quality_score, digits=1))%)" : ""
                    println("     • $(r.filename)$quality_str")
                end
            end
        end
    end
    
    return results
end

function main()
    println("🚀 Starting batch comparison...")
    
    # Get all research files
    research_files = String[]
    research_dir = "research"
    
    if isdir(research_dir)
        for file in readdir(research_dir)
            if endswith(file, ".md")
                push!(research_files, joinpath(research_dir, file))
            end
        end
    end
    
    # Also include any examples
    examples_files = String[]
    examples_dir = "examples"
    
    if isdir(examples_dir)
        for file in readdir(examples_dir)
            if endswith(file, ".md")
                push!(examples_files, joinpath(examples_dir, file))
            end
        end
    end
    
    all_files = vcat(research_files, examples_files)
    
    if isempty(all_files)
        println("No .md files found in research/ or examples/ directories")
        return
    end
    
    println("Found $(length(all_files)) test files")
    
    # Run the comparison
    results = run_batch_comparison(all_files, verbose_individual=false)
    
    println("\n🎉 Batch comparison complete!")
    println("Results available in returned data structure")
    
    return results
end

# Run the comparison
main()
