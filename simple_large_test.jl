#!/usr/bin/env julia

# Simple Large Instance Test Script
include("main.jl")

println("🚀 LARGE INSTANCE PERFORMANCE TEST")
println("="^50)
println("📦 SATLIB Benchmarks: 250 variables, 1065 clauses")
println()

files = ["benchmarks/uf250-01.md", "benchmarks/uf250-010.md", "benchmarks/uf250-0100.md", 
         "benchmarks/uf250-011.md", "benchmarks/uf250-012.md"]

results = []
total_time = 0.0
sat_count = 0

for (i, file) in enumerate(files)
    if isfile(file)
        print("$(i)/$(length(files)) $(basename(file)): ")
        try
            start = time()
            result = solve_3sat(file)
            solve_time = time() - start
            global total_time += solve_time
            
            if result.satisfiable
                global sat_count += 1
                println("✅ SAT ($(round(solve_time, digits=4))s)")
            else
                println("❌ UNSAT ($(round(solve_time, digits=4))s)")
            end
            
            # Extract modularity score if available
            modularity = hasfield(typeof(result), :modularity) ? result.modularity : nothing
            num_communities = hasfield(typeof(result), :num_communities) ? result.num_communities : nothing
            
            push!(results, (
                file=basename(file), 
                sat=result.satisfiable, 
                time=solve_time,
                modularity=modularity,
                communities=num_communities
            ))
            
            # Print modularity info if available
            if modularity !== nothing
                println("    📊 Modularity: $(round(modularity, digits=4))")
            end
            if num_communities !== nothing
                println("    🏘️  Communities: $(num_communities)")
            end
            
        catch e
            println("💥 ERROR: $e")
        end
    else
        println("$(i)/$(length(files)) $(basename(file)): ❌ FILE NOT FOUND")
    end
end

println()
println("📊 SUMMARY:")
println("✅ Solved: $(length(results))/$(length(files))")
if length(results) > 0
    println("📈 SAT rate: $(round(sat_count/length(results)*100, digits=1))%")
    println("⚡ Total time: $(round(total_time, digits=3))s")
    println("⚡ Average time: $(round(total_time/length(results), digits=4))s per instance")
    println("🎯 Throughput: $(round(length(results)/total_time, digits=1)) instances/second")
    
    # Modularity analysis
    modularity_scores = [r.modularity for r in results if r.modularity !== nothing]
    community_counts = [r.communities for r in results if r.communities !== nothing]
    
    if !isempty(modularity_scores)
        println()
        println("🔬 COMMUNITY DETECTION ANALYSIS:")
        println("   📊 Average modularity: $(round(mean(modularity_scores), digits=4))")
        println("   📊 Modularity range: $(round(minimum(modularity_scores), digits=4)) - $(round(maximum(modularity_scores), digits=4))")
        
        if !isempty(community_counts)
            println("   🏘️  Average communities: $(round(mean(community_counts), digits=1))")
            println("   🏘️  Community range: $(minimum(community_counts)) - $(maximum(community_counts))")
        end
        
        # Quality assessment
        avg_modularity = mean(modularity_scores)
        if avg_modularity > 0.3
            println("   🎉 EXCELLENT community structure (modularity > 0.3)")
        elseif avg_modularity > 0.2
            println("   👍 GOOD community structure (modularity > 0.2)")
        elseif avg_modularity > 0.1
            println("   ✅ MODERATE community structure (modularity > 0.1)")
        else
            println("   ⚠️  WEAK community structure (modularity ≤ 0.1)")
        end
    end
    
    # Performance assessment
    avg_time = total_time/length(results)
    if avg_time < 0.01
        println("\n🎉 EXCELLENT: Lightning fast! (< 0.01s average)")
    elseif avg_time < 0.1
        println("\n👍 VERY GOOD: Fast solving (< 0.1s average)")
    elseif avg_time < 1.0
        println("\n✅ GOOD: Reasonable performance (< 1s average)")
    else
        println("\n⚠️  SLOW: May need optimization for large instances")
    end
    
    println("\n🔮 PROJECTION: 100 large instances ≈ $(round(100 * avg_time, digits=1))s")
end

println("\n🏁 Large instance test complete!")
