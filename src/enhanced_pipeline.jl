"""
Enhanced Research Pipeline with DIMACS Integration

Implements the optimal workflow:
Markdown (.md) → DIMACS (.cnf) → Dual Analysis:
                                 ├── (1) CryptoMiniSat → Satisfiability  
                                 └── (2) Graph → Community Detection

This pipeline maintains human-readable markdown as the source of truth while
leveraging DIMACS format for high-performance analysis and industry compatibility.
"""

using Random
using Dates

# Import necessary functions from other modules
# These will be available when this module is included after the main modules

"""
    enhanced_research_pipeline(vars::Int, clauses::Int; seed::Union{Int, Nothing}=nothing, 
                               interactive::Bool=false, analysis_type::String="both")

Enhanced research pipeline that creates markdown, exports to DIMACS, and performs
dual analysis: SAT solving + community detection.

Parameters:
- vars: Number of variables
- clauses: Number of clauses
- seed: Random seed for reproducibility
- interactive: Enable interactive community detection
- analysis_type: "sat", "community", or "both" (default)
"""
function enhanced_research_pipeline(vars::Int, clauses::Int; 
                                   seed::Union{Int, Nothing}=nothing,
                                   interactive::Bool=false, 
                                   analysis_type::String="both")
    
    println("🚀 Enhanced Research Pipeline")
    println("=" ^50)
    println("Variables: $vars, Clauses: $clauses")
    if seed !== nothing
        println("Seed: $seed")
    end
    println("Analysis: $analysis_type")
    println()
    
    # Set random seed if provided
    if seed !== nothing
        Random.seed!(seed)
    end
    
    # Step 1: Generate markdown 3-SAT instance
    println("📝 Step 1: Creating markdown 3-SAT instance...")
    md_filename = "research/research_$(vars)vars_$(clauses)clauses"
    if seed !== nothing
        md_filename *= "_seed$(seed)"
    end
    md_filename *= ".md"
    
    # Generate the instance
    instance = generate_random_3sat(vars, clauses)
    title = "Research Instance: $vars variables, $clauses clauses"
    if seed !== nothing
        title *= " (seed $seed)"
    end
    
    # Create markdown content
    md_content = to_markdown(instance, title)
    
    # Add seed to metadata if provided
    if seed !== nothing
        md_content = replace(md_content, "- Generated: random" => "- Generated: random\n- Seed: $seed")
    end
    
    # Save markdown file
    write(md_filename, md_content)
    println("✅ Saved: $md_filename")
    
    # Step 2: Export to DIMACS format
    println("\n📋 Step 2: Exporting to DIMACS format...")
    cnf_filename = replace(md_filename, ".md" => ".cnf")
    cnf_filename = replace(cnf_filename, "research/" => "dimacs_exports/")
    
    # Ensure dimacs_exports directory exists
    if !isdir("dimacs_exports")
        mkpath("dimacs_exports")
    end
    
    export_to_dimacs(md_filename, cnf_filename, 
                    comment="Enhanced research pipeline - dual analysis ready")
    println("✅ Exported: $cnf_filename")
    
    # Results container
    results = Dict{String, Any}()
    results["markdown_file"] = md_filename
    results["dimacs_file"] = cnf_filename
    results["variables"] = vars
    results["clauses"] = clauses
    results["seed"] = seed
    
    # Step 3a: SAT Analysis (if requested)
    if analysis_type in ["sat", "both"]
        println("\n⚡ Step 3a: SAT Satisfiability Analysis...")
        sat_result = solve_dimacs(cnf_filename)
        results["sat_result"] = sat_result
        
        # Update markdown with SAT results
        solve_and_update_markdown(md_filename)
        println("✅ SAT analysis complete, markdown updated")
    end
    
    # Step 3b: Community Detection Analysis (if requested)  
    if analysis_type in ["community", "both"]
        println("\n🔍 Step 3b: Community Detection Analysis...")
        
        # Convert DIMACS to graph format for community detection
        graph_filename = replace(cnf_filename, ".cnf" => "_graph.txt")
        graph_filename = replace(graph_filename, "dimacs_exports/" => "graphs/")
        
        # Create graph from DIMACS
        num_vars, cnf_clauses = parse_dimacs(cnf_filename)
        graph_data = dimacs_to_graph(num_vars, cnf_clauses)
        
        # Save graph file
        write_graph_file(graph_filename, graph_data)
        println("✅ Created graph: $graph_filename")
        
        # Run community detection
        if interactive
            println("🎮 Running interactive community detection...")
            community_result = run_graph_interactive(graph_filename)
        else
            println("🤖 Running automated community detection...")
            community_result = run_graph(graph_filename)
        end
        
        results["graph_file"] = graph_filename
        results["community_result"] = community_result
        println("✅ Community analysis complete")
    end
    
    # Step 4: Summary Report
    println("\n📊 Step 4: Research Summary")
    println("=" ^50)
    print_research_summary(results)
    
    return results
end

"""
    dimacs_to_graph(num_vars::Int, clauses::Vector{Vector{Int}}) -> GraphData

Convert DIMACS clauses to graph representation for community detection.
Creates edges between literals that co-occur in clauses.
"""
function dimacs_to_graph(num_vars::Int, clauses::Vector{Vector{Int}})
    # Create literal mapping: positive and negative literals as separate nodes
    # Positive literal i -> node i
    # Negative literal -i -> node (num_vars + i)
    total_nodes = 2 * num_vars
    
    # Count co-occurrences between literals
    edge_weights = Dict{Tuple{Int, Int}, Int}()
    
    for clause in clauses
        # Convert literals to node indices
        nodes = Int[]
        for literal in clause
            if literal > 0
                push!(nodes, literal)  # Positive literal -> node literal
            else
                push!(nodes, num_vars + abs(literal))  # Negative literal -> node num_vars + |literal|
            end
        end
        
        # Add edges between all pairs in this clause
        for i in 1:length(nodes)
            for j in (i+1):length(nodes)
                node1, node2 = sort([nodes[i], nodes[j]])
                edge_key = (node1, node2)
                edge_weights[edge_key] = get(edge_weights, edge_key, 0) + 1
            end
        end
    end
    
    # Convert to edges list
    edges = []
    for ((node1, node2), weight) in edge_weights
        push!(edges, (node1, node2, weight))
    end
    
    return (nodes=total_nodes, edges=edges, num_vars=num_vars)
end

"""
    write_graph_file(filename::String, graph_data)

Write graph data to file in the format expected by the community detection algorithm.
"""
function write_graph_file(filename::String, graph_data)
    # Ensure graphs directory exists
    graphs_dir = dirname(filename)
    if !isdir(graphs_dir)
        mkpath(graphs_dir)
    end
    
    open(filename, "w") do io
        # Write header with comment prefix to avoid parsing as edge
        println(io, "# Graph: $(graph_data.nodes) nodes, $(length(graph_data.edges)) edges, max_weight=$(maximum([edge[3] for edge in graph_data.edges]; init=1))")
        
        # Write edges: node1 node2 weight
        for (node1, node2, weight) in graph_data.edges
            println(io, "$node1 $node2 $weight")
        end
    end
    
    # Also create a mapping file to understand node meanings
    mapping_filename = replace(filename, ".txt" => "_mapping.txt")
    open(mapping_filename, "w") do io
        println(io, "# Node to Literal Mapping")
        println(io, "# Format: Node -> Literal")
        println(io, "")
        
        for i in 1:graph_data.num_vars
            println(io, "$i -> x$i")  # Positive literals
        end
        for i in 1:graph_data.num_vars
            println(io, "$(graph_data.num_vars + i) -> ¬x$i")  # Negative literals
        end
    end
    
    println("📄 Created mapping: $mapping_filename")
end

"""
    print_research_summary(results::Dict)

Print a comprehensive summary of the research pipeline results.
"""
function print_research_summary(results::Dict)
    println("📁 Files Generated:")
    println("   • Markdown: $(results["markdown_file"])")
    println("   • DIMACS:   $(results["dimacs_file"])")
    
    if haskey(results, "graph_file")
        println("   • Graph:    $(results["graph_file"])")
    end
    
    println("\n🔬 Analysis Results:")
    
    if haskey(results, "sat_result")
        sat = results["sat_result"]
        status = sat.satisfiable ? "SATISFIABLE" : "UNSATISFIABLE"
        println("   • SAT Status: $status")
        println("   • Solve Time: $(round(sat.solve_time, digits=3))s")
        
        if sat.satisfiable && sat.solution !== nothing
            true_vars = [i for i in 1:length(sat.solution) if sat.solution[i]]
            false_vars = [i for i in 1:length(sat.solution) if !sat.solution[i]]
            println("   • Solution: x$(join(true_vars, ",")) = TRUE; x$(join(false_vars, ",")) = FALSE")
        end
    end
    
    if haskey(results, "community_result")
        println("   • Community Detection: Completed")
        println("   • Graph Analysis: Available")
    end
    
    # Research insights
    ratio = results["clauses"] / results["variables"]
    println("\n🎯 Research Context:")
    println("   • Clause/Variable Ratio: $(round(ratio, digits=2))")
    
    if ratio < 3.0
        println("   • SAT Region: Easy (likely satisfiable)")
    elseif ratio < 5.0
        println("   • SAT Region: Critical (phase transition)")
    else
        println("   • SAT Region: Hard (likely unsatisfiable)")
    end
    
    if results["seed"] !== nothing
        println("   • Reproducible: Yes (seed=$(results["seed"]))")
    end
end

"""
    batch_enhanced_pipeline(config_list::Vector; analysis_type::String="both")

Run enhanced pipeline on multiple configurations.

config_list format: [(vars, clauses, seed), ...]
"""
function batch_enhanced_pipeline(config_list::Vector; analysis_type::String="both")
    println("🔄 Batch Enhanced Research Pipeline")
    println("=" ^50)
    println("Configurations: $(length(config_list))")
    println("Analysis type: $analysis_type")
    println()
    
    all_results = []
    
    for (i, config) in enumerate(config_list)
        vars, clauses, seed = config
        println("📋 Configuration $i/$(length(config_list)): $vars vars, $clauses clauses, seed $seed")
        
        try
            result = enhanced_research_pipeline(vars, clauses, seed=seed, analysis_type=analysis_type)
            push!(all_results, result)
            println("✅ Configuration $i completed\n")
        catch e
            @error "Failed configuration $i: $e"
            println("❌ Configuration $i failed\n")
        end
    end
    
    # Batch summary
    println("📊 BATCH SUMMARY")
    println("=" ^50)
    println("Total configurations: $(length(config_list))")
    println("Successful: $(length(all_results))")
    println("Failed: $(length(config_list) - length(all_results))")
    
    if !isempty(all_results) && analysis_type in ["sat", "both"]
        satisfiable = sum([r["sat_result"].satisfiable for r in all_results if haskey(r, "sat_result")])
        total_sat = length([r for r in all_results if haskey(r, "sat_result")])
        println("SAT Results: $satisfiable/$total_sat satisfiable")
    end
    
    return all_results
end

# Export main functions
export enhanced_research_pipeline, batch_enhanced_pipeline
export dimacs_to_graph, write_graph_file, print_research_summary

println("🚀 Enhanced Research Pipeline loaded! Available functions:")
println("   - enhanced_research_pipeline(vars, clauses; seed, interactive, analysis_type)")
println("   - batch_enhanced_pipeline(configs; analysis_type)")
println("   - Analysis types: 'sat', 'community', 'both' (default)")
println()
println("💡 Example usage:")
println("   enhanced_research_pipeline(5, 21, seed=123, analysis_type=\"both\")")
println("   batch_enhanced_pipeline([(3,5,42), (4,12,100), (5,21,200)])")
