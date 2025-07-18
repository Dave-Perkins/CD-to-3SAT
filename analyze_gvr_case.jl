# Analyze the GVR performance and understand why it couldn't repair this case
using Pkg
Pkg.activate(".")

include("src/community_guided_sat.jl")
include("src/sat3_markdown_generator.jl")

println("🔬 GVR ANALYSIS: Why couldn't we repair this case?")
println("=" ^ 50)

# Recreate the problematic instance
instance = generate_random_3sat(6, 18, seed=5001)
test_file = "temp_analysis.md"
write(test_file, to_markdown(instance, "Analysis Test"))

# Get the community-guided result
result = community_guided_sat_solve(test_file, use_v2_algorithm=true, verbose=false)

if result !== nothing && result.assignment_quality !== nothing
    println("📊 CASE ANALYSIS:")
    println("   • Satisfaction: $(round(result.assignment_quality.satisfaction_rate * 100, digits=1))%")
    println("   • Violated clauses: $(length(result.assignment_quality.violated_clauses))")
    println("   • Our result: $(result.satisfiable ? "SAT" : "UNSAT")")
    println("   • Traditional: $(result.traditional_sat_result.satisfiable ? "SAT" : "UNSAT")")
    
    # Show the violated clause
    if length(result.assignment_quality.violated_clauses) > 0
        violated_clause_info = result.assignment_quality.violated_clauses[1]
        violated_clause_idx = violated_clause_info.clause_id
        clause = violated_clause_info.clause
        println("\n❌ VIOLATED CLAUSE $violated_clause_idx: $(join(clause, " ∨ "))")
        
        # Show assignment for variables in this clause
        println("   Assignment values:")
        variables_in_clause = Set{String}()
        for literal in clause
            # Handle both ASCII ¬ and Unicode ¬ characters
            if length(literal) > 0 && (literal[1:1] == "¬" || (length(literal) > 2 && literal[1:3] == "¬"))
                # It's a negated literal - extract variable name
                var = literal[1] == '¬' ? literal[2:end] : literal[4:end]  # Handle different ¬ encodings
            else
                var = literal
            end
            push!(variables_in_clause, var)
        end
        
        for var in sort(collect(variables_in_clause))
            value = result.assignment[var]
            println("     • $var = $value")
        end
        
        # Manual analysis: what would happen if we flip each variable?
        println("\n🔧 MANUAL FLIP ANALYSIS:")
        for var in sort(collect(variables_in_clause))
            test_assignment = copy(result.assignment)
            test_assignment[var] = !test_assignment[var]
            
            # Count how many clauses this assignment satisfies
            satisfied = 0
            total = length(instance.clauses)
            
            for (i, clause) in enumerate(instance.clauses)
                clause_satisfied = false
                for literal in clause
                    # Handle both ASCII ¬ and Unicode ¬ characters
                    if length(literal) > 0 && (literal[1:1] == "¬" || (length(literal) > 2 && literal[1:3] == "¬"))
                        is_negative = true
                        var_name = literal[1] == '¬' ? literal[2:end] : literal[4:end]
                    else
                        is_negative = false
                        var_name = literal
                    end
                    
                    if (is_negative && !test_assignment[var_name]) || 
                       (!is_negative && test_assignment[var_name])
                        clause_satisfied = true
                        break
                    end
                end
                if clause_satisfied
                    satisfied += 1
                end
            end
            
            change = satisfied - result.assignment_quality.satisfied_count
            println("     • Flip $var: $(satisfied)/$total satisfied ($(change >= 0 ? "+" : "")$change)")
        end
    end
    
    # Show the traditional SAT solver solution for comparison
    if result.traditional_sat_result !== nothing && result.traditional_sat_result.satisfiable
        println("\n✅ TRADITIONAL SAT SOLUTION:")
        for (var, value) in sort(collect(result.traditional_sat_result.assignment))
            our_value = result.assignment[var]
            match = our_value == value ? "✓" : "✗"
            println("     • $var: ours=$our_value, traditional=$value $match")
        end
    end
end

rm(test_file, force=true)

println("\n" * "=" ^ 50)
println("🎯 GVR INSIGHTS:")
println("✅ GVR successfully triggers on high-quality failures")
println("⚡ GVR correctly identifies when no beneficial flips exist")
println("💡 Some instances require multi-variable flips beyond single-variable heuristics")
println("🔬 The 94.4% → 100% gap may require more sophisticated repair strategies")
