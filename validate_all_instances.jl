#!/usr/bin/env julia

# Validation script to ensure all 3-SAT instances have distinct literals
# Usage: julia validate_all_instances.jl [directory]

using Pkg
Pkg.activate(".")

include("src/sat3_markdown_generator.jl")

function validate_directory(dir_path=".")
    println("🔍 VALIDATING 3-SAT INSTANCES IN: $dir_path")
    println("=" ^ 60)
    
    md_files = []
    for (root, dirs, files) in walkdir(dir_path)
        for file in files
            if endswith(file, ".md")
                full_path = joinpath(root, file)
                push!(md_files, full_path)
            end
        end
    end
    
    if isempty(md_files)
        println("No .md files found in $dir_path")
        return true
    end
    
    total_files = 0
    valid_files = 0
    total_violations = 0
    
    for filepath in md_files
        try
            # Try to parse as 3-SAT instance
            instance = parse_3sat_markdown(filepath)
            total_files += 1
            
            violations = validate_distinct_literals(instance)
            if isempty(violations)
                println("✅ $(basename(filepath)): Valid")
                valid_files += 1
            else
                println("❌ $(basename(filepath)): $(length(violations)) violations")
                for violation in violations
                    println("   • $violation")
                end
                total_violations += length(violations)
            end
        catch e
            # Skip files that aren't 3-SAT instances
            if occursin("Variables", string(e)) || occursin("Clauses", string(e))
                println("⚠️  $(basename(filepath)): Not a 3-SAT instance")
            end
        end
    end
    
    println("\n" * "=" ^ 60)
    println("📊 VALIDATION SUMMARY:")
    println("   • Total 3-SAT files: $total_files")
    println("   • Valid files: $valid_files")
    println("   • Files with violations: $(total_files - valid_files)")
    println("   • Total violations: $total_violations")
    
    all_valid = (valid_files == total_files)
    if all_valid
        println("🎉 ALL FILES PASS VALIDATION!")
    else
        println("⚠️  Some files need fixing")
        println("\n💡 To fix violations, use:")
        println("   instance, violations = ensure_distinct_literals(instance)")
    end
    
    return all_valid
end

function main()
    dir_path = length(ARGS) > 0 ? ARGS[1] : "."
    
    println("🔒 3-SAT INSTANCE VALIDATION")
    println("Constraint: Each clause must have exactly 3 distinct literals")
    println()
    
    is_valid = validate_directory(dir_path)
    
    if !is_valid
        exit(1)  # Exit with error code for CI/CD
    end
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main()
end
