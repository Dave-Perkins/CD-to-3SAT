# MINI03 - Community Detection for 3-SAT Research
# Main entry point

# Add src to load path
push!(LOAD_PATH, joinpath(@__DIR__, "src"))

# Import core modules
include("src/mini03.jl")              # Core community detection (includes scoring.jl)
include("src/sat3_markdown_generator.jl")  # 3-SAT generation
include("src/research_pipeline.jl")   # Research automation
include("src/sat_solver.jl")          # SAT solver integration
include("src/dimacs_support.jl")      # DIMACS format support
include("src/enhanced_pipeline.jl")   # Enhanced research pipeline

"""
    MINI03 - Community Detection for 3-SAT Research

Main functions:
    • run_graph(filename) - Analyze a graph file
    • run_graph_interactive(filename) - Interactive analysis
    • research_pipeline(vars, clauses; seed=nothing) - Generate and analyze 3-SAT instances
    • generate_random_3sat(vars, clauses; seed=nothing) - Create 3-SAT instances
    • solve_3sat(filename) - Check satisfiability using CryptoMiniSat
    • batch_solve_directory(directory) - Solve all instances in a directory
    • export_to_dimacs(md_file, cnf_file) - Convert markdown to DIMACS format
    • import_dimacs_to_markdown(cnf_file, md_file) - Convert DIMACS to markdown
    • enhanced_research_pipeline(vars, clauses; seed=123, analysis_type="both") - Advanced analysis pipeline
    • batch_enhanced_pipeline([(vars,clauses,seed), ...]) - Batch process with enhanced pipeline

Examples:
    # Analyze existing graph
    julia> run_graph("graphs/graph03.txt")
    
    # Interactive analysis
    julia> run_graph_interactive("graphs/graph03.txt")
    
    # Generate and analyze 3-SAT instance
    julia> research_pipeline(5, 15, seed=123)
    
    # Generate markdown 3-SAT
    julia> instance = generate_random_3sat(4, 10)
    julia> md = to_markdown(instance, "My Test Instance")
    
    # Check satisfiability
    julia> solve_3sat("research/research_5vars_15clauses_seed123.md")
    
    # Solve all instances in research directory
    julia> batch_solve_directory("research/")
    
    # Export to DIMACS format
    julia> export_to_dimacs("research/research_5vars_15clauses_seed123.md", "output.cnf")
    
    # Import DIMACS benchmark
    julia> import_dimacs_to_markdown("benchmark.cnf", "imported_instance.md")
    
    # Enhanced research pipeline example
    julia> enhanced_research_pipeline(5, 21, seed=123)
"""

# Welcome message
println("🌟 MINI03 - Community Detection for 3-SAT Research")
println("=" ^60)
println("📚 Core functions loaded:")
println("   • run_graph(filename) - Simple analysis workflow") 
println("   • run_graph_interactive(filename) - Interactive menu")
println("   • research_pipeline(vars, clauses; seed=nothing) - 3-SAT research")
println("   • generate_random_3sat(vars, clauses; seed=nothing) - Generate instances")
println("   • solve_3sat(filename) - SAT solving with CryptoMiniSat")
println("   • batch_solve_directory(directory) - Batch SAT solving")
println("   • export_to_dimacs(md_file, cnf_file) - Export to DIMACS format")
println("   • solve_dimacs(cnf_file) - Solve DIMACS files directly")
println("   • enhanced_research_pipeline(vars, clauses; seed=123, analysis_type=\"both\") - Advanced analysis pipeline")
println("   • batch_enhanced_pipeline([(vars,clauses,seed), ...]) - Batch process with enhanced pipeline")
println()
println("🚀 Quick start:")
println("   julia> run_graph(\"graphs/graph03.txt\")")
println("   julia> research_pipeline(5, 15, seed=123)")
println("   julia> solve_3sat(\"research/research_5vars_15clauses_seed123.md\")")
println()

# Commented out - no longer showing available graph files by default
# println("📁 Available graph files:")
# println("=" ^60)
# graph_dir = "graphs"
# if isdir(graph_dir)
#     for file in readdir(graph_dir)
#         if endswith(file, ".txt")
#             println("   • graphs/$file")
#         end
#     end
# else
#     println("   (No graphs directory found)")
# end

research_dir = "research"  
if isdir(research_dir)
    println()
    println("📊 Research instances:")
    for file in readdir(research_dir)
        if endswith(file, ".md")
            println("   • research/$file")
        end
    end
end
