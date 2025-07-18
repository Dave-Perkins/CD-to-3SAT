#!/usr/bin/env julia
"""
Comparative Systematic Testing: label_propagation vs label_propagation_v2

Tests both community detection algorithms to compare performance on SAT solving.
"""

# Add src directory to path for imports
push!(LOAD_PATH, "src")

include("src/community_guided_sat.jl")

using Dates

"""
    run_comparative_systematic_tests()

Run systematic tests comparing basic vs v2 label propagation algorithms.
"""
function run_comparative_systematic_tests()
    println("🔬 COMPARATIVE SYSTEMATIC TESTING")
    println("="^65)
    println("Comparing: Basic Label Propagation vs Label Propagation V2")
    println("Started at: $(Dates.now())")
    println()
    
    # Test configuration - smaller set for focused comparison
    test_configs = [
        # Easy region
        (3, 6, "Easy"),
        (4, 8, "Easy"), 
        (5, 10, "Easy"),
        
        # Critical region  
        (5, 20, "Critical"),
        (5, 21, "Critical"),
        (6, 25, "Critical"),
        
        # Hard region
        (4, 20, "Hard"),
        (5, 25, "Hard"),
        (4, 28, "Hard"),
        
        # Scalability
        (8, 16, "Scale"),
        (10, 42, "Scale"),
    ]
    
    results_basic = []
    results_v2 = []
    
    println("📊 Running $(length(test_configs)) test configurations...")
    println("   Each configuration tested with both algorithms")
    println()
    
    for (i, (num_vars, num_clauses, category)) in enumerate(test_configs)
        ratio = round(num_clauses / num_vars, digits=2)
        println("🧪 Test $i/$length(test_configs): $category - $num_vars vars, $num_clauses clauses (ratio: $ratio)")
        
        # Generate same instance for both tests
        seed = 1000 + i
        instance = generate_random_3sat(num_vars, num_clauses, seed=seed)
        
        # Create temporary markdown file
        temp_md_file = tempname() * ".md"
        md_content = to_markdown(instance, "Comparative Test $i")
        open(temp_md_file, "w") do f
            write(f, md_content)
        end
        
        # Test traditional SAT solver first
        traditional_result = nothing
        try
            if isdefined(Main, :solve_3sat)
                traditional_result = Main.solve_3sat(temp_md_file)
            end
        catch e
            println("   ⚠️  Traditional solver error: $e")
        end
        
        # Test basic label propagation
        println("   🔍 Testing basic label propagation...")
        basic_start = time()
        try
            basic_result = community_guided_sat_solve(temp_md_file, 
                compare_traditional=false, verbose=false, use_v2_algorithm=false)
            basic_time = time() - basic_start
            
            basic_agreement = traditional_result !== nothing ? 
                (basic_result.satisfiable == traditional_result.satisfiable) : false
                
            push!(results_basic, (
                category=category,
                vars=num_vars,
                clauses=num_clauses,
                ratio=ratio,
                satisfiable=basic_result.satisfiable,
                traditional_sat=(traditional_result !== nothing ? traditional_result.satisfiable : nothing),
                agreement=basic_agreement,
                time=basic_time,
                communities=length(basic_result.communities),
                modularity=basic_result.modularity_score,
                algorithm="basic"
            ))
            
            agreement_str = basic_agreement ? "✅" : "❌"
            println("     → Basic: $(basic_result.satisfiable ? "SAT" : "UNSAT") | " *
                   "Traditional: $(traditional_result !== nothing ? (traditional_result.satisfiable ? "SAT" : "UNSAT") : "N/A") | " *
                   "Agreement: $agreement_str | " *
                   "Time: $(round(basic_time, digits=3))s | " *
                   "Communities: $(length(basic_result.communities)) | " *
                   "Modularity: $(round(basic_result.modularity_score, digits=3))")
        catch e
            println("     → Basic: ERROR - $e")
            push!(results_basic, (
                category=category, vars=num_vars, clauses=num_clauses, ratio=ratio,
                satisfiable=false, traditional_sat=nothing, agreement=false,
                time=0.0, communities=0, modularity=0.0, algorithm="basic"
            ))
        end
        
        # Test v2 label propagation
        println("   🚀 Testing label propagation v2...")
        v2_start = time()
        try
            v2_result = community_guided_sat_solve(temp_md_file,
                compare_traditional=false, verbose=false, use_v2_algorithm=true)
            v2_time = time() - v2_start
            
            v2_agreement = traditional_result !== nothing ? 
                (v2_result.satisfiable == traditional_result.satisfiable) : false
                
            push!(results_v2, (
                category=category,
                vars=num_vars,
                clauses=num_clauses,
                ratio=ratio,
                satisfiable=v2_result.satisfiable,
                traditional_sat=(traditional_result !== nothing ? traditional_result.satisfiable : nothing),
                agreement=v2_agreement,
                time=v2_time,
                communities=length(v2_result.communities),
                modularity=v2_result.modularity_score,
                algorithm="v2"
            ))
            
            agreement_str = v2_agreement ? "✅" : "❌"
            println("     → V2: $(v2_result.satisfiable ? "SAT" : "UNSAT") | " *
                   "Traditional: $(traditional_result !== nothing ? (traditional_result.satisfiable ? "SAT" : "UNSAT") : "N/A") | " *
                   "Agreement: $agreement_str | " *
                   "Time: $(round(v2_time, digits=3))s | " *
                   "Communities: $(length(v2_result.communities)) | " *
                   "Modularity: $(round(v2_result.modularity_score, digits=3))")
        catch e
            println("     → V2: ERROR - $e")
            push!(results_v2, (
                category=category, vars=num_vars, clauses=num_clauses, ratio=ratio,
                satisfiable=false, traditional_sat=nothing, agreement=false,
                time=0.0, communities=0, modularity=0.0, algorithm="v2"
            ))
        end
        
        # Cleanup
        rm(temp_md_file, force=true)
        println()
    end
    
    # Analyze results
    analyze_comparative_results(results_basic, results_v2)
end

"""
    analyze_comparative_results(results_basic, results_v2)

Analyze and compare results from both algorithms.
"""
function analyze_comparative_results(results_basic, results_v2)
    println("📈 COMPARATIVE ANALYSIS")
    println("="^50)
    
    # Overall statistics
    total_tests = length(results_basic)
    
    # Basic algorithm stats
    basic_agreements = sum(r.agreement for r in results_basic)
    basic_sat_count = sum(r.satisfiable for r in results_basic)
    basic_avg_time = mean(r.time for r in results_basic)
    basic_avg_communities = mean(r.communities for r in results_basic)
    basic_avg_modularity = mean(r.modularity for r in results_basic)
    
    # V2 algorithm stats  
    v2_agreements = sum(r.agreement for r in results_v2)
    v2_sat_count = sum(r.satisfiable for r in results_v2)
    v2_avg_time = mean(r.time for r in results_v2)
    v2_avg_communities = mean(r.communities for r in results_v2)
    v2_avg_modularity = mean(r.modularity for r in results_v2)
    
    println("\n🎯 OVERALL PERFORMANCE COMPARISON")
    println("-" ^ 40)
    println("Total tests: $total_tests")
    println()
    println("📊 Agreement Rates:")
    println("   • Basic Label Propagation:    $basic_agreements/$total_tests ($(round(100*basic_agreements/total_tests, digits=1))%)")
    println("   • Label Propagation V2:       $v2_agreements/$total_tests ($(round(100*v2_agreements/total_tests, digits=1))%)")
    improvement = v2_agreements - basic_agreements
    improvement_pct = round(100 * improvement / total_tests, digits=1)
    println("   • Improvement:                +$improvement tests (+$improvement_pct%)")
    println()
    
    println("⚡ Performance Metrics:")
    println("   • Basic avg time:             $(round(basic_avg_time, digits=3))s")
    println("   • V2 avg time:                $(round(v2_avg_time, digits=3))s")
    speedup = basic_avg_time / v2_avg_time
    println("   • Speedup factor:             $(round(speedup, digits=2))x")
    println()
    
    println("🏘️  Community Structure:")
    println("   • Basic avg communities:      $(round(basic_avg_communities, digits=2))")
    println("   • V2 avg communities:         $(round(v2_avg_communities, digits=2))")
    println("   • Basic avg modularity:       $(round(basic_avg_modularity, digits=4))")
    println("   • V2 avg modularity:          $(round(v2_avg_modularity, digits=4))")
    modularity_improvement = round(v2_avg_modularity - basic_avg_modularity, digits=4)
    println("   • Modularity improvement:     +$modularity_improvement")
    println()
    
    # Category breakdown
    println("📊 PERFORMANCE BY CATEGORY")
    println("-" ^ 40)
    categories = unique([r.category for r in results_basic])
    
    for category in categories
        basic_cat = [r for r in results_basic if r.category == category]
        v2_cat = [r for r in results_v2 if r.category == category]
        
        basic_cat_agreements = sum(r.agreement for r in basic_cat)
        v2_cat_agreements = sum(r.agreement for r in v2_cat)
        cat_total = length(basic_cat)
        
        basic_cat_modularity = mean(r.modularity for r in basic_cat)
        v2_cat_modularity = mean(r.modularity for r in v2_cat)
        
        println("$category Region:")
        println("   • Basic agreement:  $basic_cat_agreements/$cat_total ($(round(100*basic_cat_agreements/cat_total, digits=1))%)")
        println("   • V2 agreement:     $v2_cat_agreements/$cat_total ($(round(100*v2_cat_agreements/cat_total, digits=1))%)")
        println("   • Basic modularity: $(round(basic_cat_modularity, digits=4))")
        println("   • V2 modularity:    $(round(v2_cat_modularity, digits=4))")
        println()
    end
    
    # Detailed results table
    println("📋 DETAILED COMPARISON TABLE")
    println("-" ^ 90)
    println("Test | Category | Vars | Clauses | Ratio | Basic Result | V2 Result | Basic Mod | V2 Mod | Winner")
    println("-" ^ 90)
    
    for i in 1:length(results_basic)
        basic = results_basic[i]
        v2 = results_v2[i]
        
        basic_result = basic.agreement ? "✅" : "❌"
        v2_result = v2.agreement ? "✅" : "❌"
        
        winner = ""
        if v2.agreement && !basic.agreement
            winner = "V2 🏆"
        elseif !v2.agreement && basic.agreement
            winner = "Basic 🏆"
        elseif v2.agreement && basic.agreement
            winner = v2.modularity > basic.modularity ? "V2 📈" : "Basic 📈"
        else
            winner = "-"
        end
        
        println("$(lpad(i, 4)) | $(rpad(basic.category, 8)) | $(lpad(basic.vars, 4)) | " *
               "$(lpad(basic.clauses, 7)) | $(rpad(round(basic.ratio, digits=2), 5)) | " *
               "$(rpad(basic_result, 12)) | $(rpad(v2_result, 9)) | " *
               "$(rpad(round(basic.modularity, digits=3), 9)) | $(rpad(round(v2.modularity, digits=3), 6)) | $winner")
    end
    
    println("\n🎉 COMPARATIVE TESTING COMPLETED!")
    println("="^50)
    
    return results_basic, results_v2
end

# Helper function for mean calculation
function mean(arr)
    if isempty(arr)
        return 0.0
    end
    return sum(arr) / length(arr)
end

# Main execution
if abspath(PROGRAM_FILE) == @__FILE__
    run_comparative_systematic_tests()
end
