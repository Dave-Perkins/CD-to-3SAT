#!/usr/bin/env julia
"""
Focused Community-Guided SAT Debugging

Debug and analyze the community-guided SAT algorithm step by step.
"""

# Add src directory to path for imports
push!(LOAD_PATH, "src")

include("src/community_guided_sat.jl")

"""
    debug_single_instance(num_vars, num_clauses, seed)

Debug a single instance with detailed output.
"""
function debug_single_instance(num_vars, num_clauses, seed)
    println("🔍 DEBUGGING COMMUNITY-GUIDED SAT")
    println("=" ^ 50)
    
    # Generate instance
    println("📋 Generating instance: $num_vars vars, $num_clauses clauses, seed=$seed")
    instance = generate_random_3sat(num_vars, num_clauses, seed=seed)
    
    temp_md_file = tempname() * ".md"
    md_content = to_markdown(instance, "Debug Instance")
    open(temp_md_file, "w") do f
        write(f, md_content)
    end
    
    println("📄 Instance content:")
    println("   Variables: $(instance.variables)")
    println("   Clauses:")
    for (i, clause) in enumerate(instance.clauses)
        println("     $i. ($(join(clause, " ∨ ")))")
    end
    
    # Test traditional SAT solver first
    println("\n🔧 Testing traditional SAT solver...")
    try
        if isdefined(Main, :solve_3sat)
            trad_result = Main.solve_3sat(temp_md_file)
            println("   Traditional result: $(trad_result.satisfiable ? "SATISFIABLE" : "UNSATISFIABLE")")
            if trad_result.satisfiable && trad_result.solution !== nothing
                println("   Traditional solution: $(trad_result.solution)")
            end
        else
            println("   Traditional solver not available")
        end
    catch e
        println("   Traditional solver error: $e")
    end
    
    # Manual satisfiability check
    println("\n🧮 Manual satisfiability check...")
    manual_result = manual_satisfiability_check(instance)
    println("   Manual check result: $(manual_result ? "SATISFIABLE" : "UNSATISFIABLE")")
    
    # Test community-guided approach with detailed debugging
    println("\n🏘️  Testing community-guided approach...")
    try
        result = community_guided_sat_solve(temp_md_file, compare_traditional=false, verbose=true)
        
        println("\n📊 Community-guided results:")
        println("   Result: $(result.satisfiable ? "SATISFIABLE" : "UNSATISFIABLE")")
        println("   Assignment: $(result.assignment)")
        println("   Communities: $(length(result.communities))")
        println("   Modularity: $(result.modularity_score)")
        
        # Validate the assignment manually
        validation = validate_assignment(instance, result.assignment)
        println("   Assignment validation: $(validation ? "VALID" : "INVALID")")
        
        if !validation
            println("\n❌ Assignment validation failed! Debugging...")
            debug_assignment_validation(instance, result.assignment)
        end
        
    catch e
        println("   Community-guided error: $e")
        println("   Stack trace:")
        for line in split(string(catch_backtrace()), '\n')[1:min(10, end)]
            println("     $line")
        end
    end
    
    # Cleanup
    rm(temp_md_file, force=true)
end

"""
    manual_satisfiability_check(instance)

Manually check satisfiability by trying some simple assignments.
"""
function manual_satisfiability_check(instance)
    # Try all possible assignments for small instances
    n_vars = length(instance.variables)
    if n_vars > 6
        println("   Too many variables for exhaustive check")
        return false
    end
    
    for i in 0:(2^n_vars - 1)
        assignment = Dict{String, Bool}()
        for (j, var) in enumerate(instance.variables)
            assignment[var] = (i >> (j-1)) & 1 == 1
        end
        
        if validate_assignment(instance, assignment)
            println("   Found satisfying assignment: $assignment")
            return true
        end
    end
    
    return false
end

"""
    debug_assignment_validation(instance, assignment)

Debug why an assignment validation failed.
"""
function debug_assignment_validation(instance, assignment)
    println("   Checking each clause:")
    
    for (i, clause) in enumerate(instance.clauses)
        clause_satisfied = false
        clause_details = []
        
        for literal in clause
            var_name = get_variable_name(literal)
            var_value = get(assignment, var_name, false)
            literal_satisfied = is_negated(literal) ? !var_value : var_value
            
            push!(clause_details, "$literal: $var_name=$var_value → $(literal_satisfied ? "T" : "F")")
            
            if literal_satisfied
                clause_satisfied = true
            end
        end
        
        status = clause_satisfied ? "✅ SAT" : "❌ UNSAT"
        println("     Clause $i: ($(join(clause, " ∨ "))) → $status")
        for detail in clause_details
            println("       $detail")
        end
        
        if !clause_satisfied
            println("       ⚠️  This clause is not satisfied!")
        end
    end
end

"""
    test_simple_cases()

Test with very simple, known cases.
"""
function test_simple_cases()
    println("🧪 TESTING SIMPLE KNOWN CASES")
    println("=" ^ 40)
    
    # Test 1: Obviously satisfiable
    println("\n📋 Test 1: Obviously satisfiable case")
    debug_single_instance(2, 2, 1000)  # Small, likely satisfiable
    
    # Test 2: Medium case
    println("\n📋 Test 2: Medium case")
    debug_single_instance(3, 5, 1001)
    
    # Test 3: Likely unsatisfiable
    println("\n📋 Test 3: High ratio case")
    debug_single_instance(3, 12, 1002)  # High ratio, likely unsatisfiable
end

"""
    analyze_community_guided_issues()

Analyze why the community-guided approach might be failing.
"""
function analyze_community_guided_issues()
    println("\n🔍 ANALYZING COMMUNITY-GUIDED ISSUES")
    println("=" ^ 45)
    
    # Test with a simple manually created instance
    println("📋 Creating manual test instance...")
    
    # Create a simple satisfiable instance: (x1 ∨ x2) ∧ (¬x1 ∨ x3)
    variables = ["x1", "x2", "x3"]
    clauses = [
        ["x1", "x2"],
        ["¬x1", "x3"]
    ]
    metadata = Dict(
        "variables" => 3, 
        "clauses" => 2, 
        "ratio" => 2/3,
        "generated" => "manual",
        "description" => "Simple test case"
    )
    
    instance = SAT3Instance(variables, clauses, metadata)
    
    println("   Variables: $(instance.variables)")
    println("   Clauses:")
    for (i, clause) in enumerate(instance.clauses)
        println("     $i. ($(join(clause, " ∨ ")))")
    end
    
    # Expected satisfying assignment: x1=true, x2=any, x3=any
    # Or: x1=false, x2=true, x3=true
    
    # Test manual validation first
    test_assignments = [
        Dict("x1" => true, "x2" => true, "x3" => true),
        Dict("x1" => false, "x2" => true, "x3" => true),
        Dict("x1" => true, "x2" => false, "x3" => false),
    ]
    
    println("\n🧮 Testing manual assignments:")
    for (i, assignment) in enumerate(test_assignments)
        result = validate_assignment(instance, assignment)
        println("   Assignment $i: $assignment → $(result ? "VALID" : "INVALID")")
    end
    
    # Create temporary file and test community-guided approach
    temp_md_file = tempname() * ".md"
    md_content = to_markdown(instance, "Manual Test Instance")
    open(temp_md_file, "w") do f
        write(f, md_content)
    end
    
    println("\n🏘️  Testing community-guided on manual instance:")
    try
        result = community_guided_sat_solve(temp_md_file, compare_traditional=false, verbose=true)
        
        println("   Community result: $(result.satisfiable ? "SATISFIABLE" : "UNSATISFIABLE")")
        println("   Assignment: $(result.assignment)")
        
        validation = validate_assignment(instance, result.assignment)
        println("   Validation: $(validation ? "VALID" : "INVALID")")
        
        if !validation
            debug_assignment_validation(instance, result.assignment)
        end
        
    catch e
        println("   Error: $e")
    end
    
    rm(temp_md_file, force=true)
end

# Run the debugging
if abspath(PROGRAM_FILE) == @__FILE__
    test_simple_cases()
    analyze_community_guided_issues()
    
    println("\n🎯 DEBUGGING COMPLETE")
    println("Check the output above to identify issues with the community-guided algorithm.")
end
