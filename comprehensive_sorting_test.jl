# Comprehensive test comparing HIGH-TO-LOW vs LOW-TO-HIGH node sorting
using Pkg
Pkg.activate(".")

include("src/community_guided_sat.jl")
include("src/sat3_markdown_generator.jl")

println("🔬 COMPREHENSIVE NODE SORTING OPTIMIZATION TEST")
println("=" ^ 60)

# First, let's change back to high-to-low and test
function test_sorting_direction(use_low_to_high::Bool, num_tests::Int = 5)
    println("\n🧪 Testing $(use_low_to_high ? "LOW-TO-HIGH" : "HIGH-TO-LOW") sorting...")
    
    # Change the sorting direction in the code temporarily
    filename = "src/community_guided_sat.jl"
    content = read(filename, String)
    
    if use_low_to_high
        # Change to low-to-high (rev=false)
        new_content = replace(content, "sort!(node_weights, by=x->x[2], rev=true)" => "sort!(node_weights, by=x->x[2], rev=false)")
    else
        # Change to high-to-low (rev=true) 
        new_content = replace(content, "sort!(node_weights, by=x->x[2], rev=false)" => "sort!(node_weights, by=x->x[2], rev=true)")
    end
    
    write(filename, new_content)
    
    # Test results
    agreements = 0
    total_time = 0.0
    total_modularity = 0.0
    total_communities = 0
    valid_tests = 0
    
    for i in 1:num_tests
        # Generate a random test instance
        instance = generate_random_3sat(4, 6, seed=1000+i)
        test_file = "temp_test_$i.md"
        
        try
            # Save instance to markdown
            markdown_content = to_markdown(instance, "Test Instance $i")
            write(test_file, markdown_content)
            
            # Test our solver
            result = community_guided_sat_solve(test_file, use_v2_algorithm=true, verbose=false)
            
            if result !== nothing && result.traditional_sat_result !== nothing
                valid_tests += 1
                
                # Check agreement
                if result.satisfiable == result.traditional_sat_result.satisfiable
                    agreements += 1
                end
                
                total_time += result.solve_time
                total_modularity += result.modularity_score
                total_communities += length(result.communities)
                
                print(".")
            end
            
            # Clean up
            rm(test_file, force=true)
            
        catch e
            print("E")
        end
    end
    
    println()
    
    if valid_tests > 0
        agreement_rate = (agreements / valid_tests) * 100
        avg_time = total_time / valid_tests
        avg_modularity = total_modularity / valid_tests
        avg_communities = total_communities / valid_tests
        
        println("   📊 Results:")
        println("     • Agreement rate: $(round(agreement_rate, digits=1))% ($agreements/$valid_tests)")
        println("     • Avg solve time: $(round(avg_time, digits=3))s")
        println("     • Avg modularity: $(round(avg_modularity, digits=3))")
        println("     • Avg communities: $(round(avg_communities, digits=1))")
        
        return (agreement_rate, avg_time, avg_modularity, avg_communities)
    else
        println("   ❌ No valid tests completed")
        return (0.0, 0.0, 0.0, 0.0)
    end
end

# Test both directions
println("Testing node processing order optimization...")

# Test original approach (high-to-low)
high_to_low_results = test_sorting_direction(false, 8)

# Test optimized approach (low-to-high) 
low_to_high_results = test_sorting_direction(true, 8)

# Compare results
println("\n" * "=" ^ 60)
println("🏆 COMPARISON RESULTS:")
println("=" ^ 60)

println("High-to-Low (Original):")
println("  Agreement: $(round(high_to_low_results[1], digits=1))%")
println("  Avg Time: $(round(high_to_low_results[2], digits=3))s") 
println("  Avg Modularity: $(round(high_to_low_results[3], digits=3))")
println("  Avg Communities: $(round(high_to_low_results[4], digits=1))")

println("\nLow-to-High (Optimized):")
println("  Agreement: $(round(low_to_high_results[1], digits=1))%")
println("  Avg Time: $(round(low_to_high_results[2], digits=3))s")
println("  Avg Modularity: $(round(low_to_high_results[3], digits=3))")
println("  Avg Communities: $(round(low_to_high_results[4], digits=1))")

# Calculate improvements
agreement_improvement = low_to_high_results[1] - high_to_low_results[1]
time_improvement = high_to_low_results[2] - low_to_high_results[2]
modularity_improvement = low_to_high_results[3] - high_to_low_results[3]

println("\n📈 IMPROVEMENTS:")
if agreement_improvement > 0
    println("  ✅ Agreement: +$(round(agreement_improvement, digits=1))%")
elseif agreement_improvement < 0
    println("  📉 Agreement: $(round(agreement_improvement, digits=1))%")
else
    println("  ➡️  Agreement: No change")
end

if time_improvement > 0
    println("  ⚡ Time: $(round(time_improvement, digits=3))s faster")
elseif time_improvement < 0
    println("  🐌 Time: $(round(-time_improvement, digits=3))s slower")
else
    println("  ➡️  Time: No significant change")
end

if modularity_improvement > 0
    println("  📊 Modularity: +$(round(modularity_improvement, digits=3))")
else
    println("  📊 Modularity: $(round(modularity_improvement, digits=3))")
end

# Conclusion
println("\n🎯 CONCLUSION:")
if agreement_improvement > 2
    println("  🎉 LOW-TO-HIGH processing shows significant improvement!")
elseif agreement_improvement > 0
    println("  ✅ LOW-TO-HIGH processing shows modest improvement")
elseif agreement_improvement < -2
    println("  ❌ LOW-TO-HIGH processing shows degradation - reverting recommended")
else
    println("  ➡️  No significant difference between approaches")
end
