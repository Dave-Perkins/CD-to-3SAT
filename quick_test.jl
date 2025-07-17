#!/usr/bin/env julia

# Quick Enhanced Pipeline Test with Command Line Arguments
include("main.jl")

# Parse command line arguments
function parse_args()
    args = ARGS
    
    # Default values
    vars = 5
    clauses = 21
    seed = 123
    analysis_type = "both"
    interactive = false
    
    if length(args) >= 1
        vars = parse(Int, args[1])
    end
    if length(args) >= 2
        clauses = parse(Int, args[2])
    end
    if length(args) >= 3
        seed = parse(Int, args[3])
    end
    if length(args) >= 4
        analysis_type = String(args[4])
    end
    if length(args) >= 5
        interactive = parse(Bool, args[5])
    end
    
    return vars, clauses, seed, analysis_type, interactive
end

# Show usage if help requested
if "--help" in ARGS || "-h" in ARGS
    println("🚀 Enhanced Pipeline Quick Test")
    println("=" ^50)
    println("Usage: julia quick_test.jl [vars] [clauses] [seed] [analysis_type] [interactive]")
    println()
    println("Parameters:")
    println("  vars          : Number of variables (default: 5)")
    println("  clauses       : Number of clauses (default: 21)")
    println("  seed          : Random seed (default: 123)")
    println("  analysis_type : 'sat', 'community', or 'both' (default: 'both')")
    println("  interactive   : true/false for interactive mode (default: false)")
    println()
    println("Examples:")
    println("  julia quick_test.jl")
    println("  julia quick_test.jl 4 12")
    println("  julia quick_test.jl 5 21 456")
    println("  julia quick_test.jl 3 8 999 sat")
    println("  julia quick_test.jl 4 15 100 community true")
    exit(0)
end

# Parse arguments
vars, clauses, seed, analysis_type, interactive = parse_args()

println("🚀 Running Enhanced Pipeline Test...")
println("Parameters: $vars variables, $clauses clauses, seed=$seed, analysis=$analysis_type, interactive=$interactive")
println()

result = enhanced_research_pipeline(vars, clauses, seed=seed, analysis_type=analysis_type, interactive=interactive)
println("\n✅ Test completed!")
