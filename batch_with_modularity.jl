# Enhanced batch solver with modularity scores
# Extends existing solve_3sat functionality to include community detection modularity

# Add src to load path if not already added
if !(joinpath(@__DIR__, "src") in LOAD_PATH)
    push!(LOAD_PATH, joinpath(@__DIR__, "src"))
end

# Include main solver functions and community guided solver
include("main.jl")
include("src/community_guided_sat.jl")

"""
    solve_with_modularity(filename::String; verbose=false)

Solve a 3-SAT instance and return both basic SAT result and modularity score.
This combines the fast solve_3sat() with modularity from community_guided_sat_solve().
"""
function solve_with_modularity(filename::String; verbose=false)
    if !isfile(filename)
        return (satisfiable=false, solve_time=0.0, modularity=nothing, error="File not found")
    end
    
    try
        # Get basic SAT result (fast)
        basic_result = solve_3sat(filename)
        
        # Get modularity from community detection (more detailed but slower)
        community_result = community_guided_sat_solve(filename, verbose=false)
        
        return (
            satisfiable = basic_result.satisfiable,
            solve_time = basic_result.solve_time, 
            modularity = community_result.modularity_score,
            communities = length(community_result.communities),
            assignment_available = community_result.assignment !== nothing
        )
        
    catch e
        return (satisfiable=false, solve_time=0.0, modularity=nothing, error=string(e))
    end
end

"""
    batch_solve_with_modularity(directory::String; max_files=nothing, verbose=false)

Solve all instances in a directory and report modularity scores alongside SAT results.
"""
function batch_solve_with_modularity(directory::String; max_files=nothing, verbose=false)
    if !isdir(directory)
        println("❌ Directory not found: $directory")
        return
    end
    
    # Find all markdown files
    md_files = filter(f -> endswith(f, ".md"), readdir(directory, join=true))
    
    if isempty(md_files)
        println("❌ No markdown files found in $directory")
        return
    end
    
    # Limit files if requested
    if max_files !== nothing
        md_files = md_files[1:min(length(md_files), max_files)]
    end
    
    println("🔬 Batch Solving with Modularity Analysis")
    println("=" ^ 60)
    println("📁 Directory: $directory")
    println("📄 Files to process: $(length(md_files))")
    println()
    
    results = []
    total_time = 0.0
    satisfied_count = 0
    
    for (i, file) in enumerate(md_files)
        filename = basename(file)
        print("[$i/$(length(md_files))] $filename: ")
        
        result = solve_with_modularity(file, verbose=verbose)
        push!(results, (file=filename, result=result))
        
        if haskey(result, :error)
            println("❌ ERROR - $(result.error)")
        else
            status = result.satisfiable ? "✅ SAT" : "❌ UNSAT"
            modularity_str = result.modularity !== nothing ? 
                             "Mod: $(round(result.modularity, digits=3))" : "Mod: N/A"
            communities_str = "Comm: $(result.communities)"
            time_str = "$(round(result.solve_time, digits=4))s"
            
            println("$status | $modularity_str | $communities_str | $time_str")
            
            if result.satisfiable
                satisfied_count += 1
            end
            total_time += result.solve_time
        end
    end
    
    println()
    println("📊 Summary:")
    println("   • Total instances: $(length(md_files))")
    println("   • Satisfiable: $satisfied_count")
    println("   • Success rate: $(round(satisfied_count/length(md_files)*100, digits=1))%")
    println("   • Total time: $(round(total_time, digits=3))s")
    println("   • Average time: $(round(total_time/length(md_files), digits=4))s")
    
    return results
end

"""
    quick_modularity_test()

Quick test of modularity extraction on small research instances.
"""
function quick_modularity_test()
    println("🧪 Quick Modularity Test")
    println("=" ^ 30)
    
    # Test on a few small instances
    test_files = [
        "research/research_3vars_5clauses_seed42.md",
        "research/research_3vars_6clauses_seed123.md", 
        "research/research_4vars_12clauses_seed123.md"
    ]
    
    for file in test_files
        if isfile(file)
            print("$(basename(file)): ")
            result = solve_with_modularity(file)
            
            if haskey(result, :error)
                println("❌ $(result.error)")
            else
                status = result.satisfiable ? "SAT" : "UNSAT"
                mod_str = result.modularity !== nothing ? 
                         "$(round(result.modularity, digits=3))" : "N/A"
                println("$status | Modularity: $mod_str | Communities: $(result.communities)")
            end
        else
            println("$(basename(file)): ❌ File not found")
        end
    end
end

# Run quick test if script is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    quick_modularity_test()
end
