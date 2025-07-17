#!/usr/bin/env julia
# End-to-end pipeline for 3-SAT research using markdown inputs

println("🔬 3-SAT Community Detection Research Pipeline")
println("=" ^50)

# Include our modules (relative to src directory)
include("sat3_markdown_generator.jl")
include("mini03.jl")

function research_pipeline(num_vars::Int, num_clauses::Int; seed=nothing, interactive=false)
    println("📋 Parameters:")
    println("   • Variables: $num_vars")
    println("   • Clauses: $num_clauses") 
    println("   • Ratio: $(round(num_clauses/num_vars, digits=2))")
    if seed !== nothing
        println("   • Seed: $seed")
    end
    println()
    
    # Step 1: Generate 3-SAT instance
    println("🎲 Step 1: Generating random 3-SAT instance...")
    instance = generate_random_3sat(num_vars, num_clauses, seed=seed)
    
    # Step 2: Save markdown (ensure research directory exists)
    research_dir = "research"
    if !isdir(research_dir)
        mkdir(research_dir)
    end
    
    filename_base = "research_$(num_vars)vars_$(num_clauses)clauses"
    if seed !== nothing
        filename_base *= "_seed$seed"
    end
    
    md_file = "$research_dir/$filename_base.md"
    graph_file = "$research_dir/$filename_base.txt"
    mapping_file = "$research_dir/$(filename_base)_mapping.txt"
    
    println("💾 Step 2: Saving files...")
    println("   - Markdown: $md_file")
    println("   - Graph: $graph_file")  
    println("   - Mapping: $mapping_file")
    
    # Save markdown
    md_content = to_markdown(instance, "Research Instance: $num_vars variables, $num_clauses clauses")
    open(md_file, "w") do f
        write(f, md_content)
    end
    
    # Save graph
    graph_content, node_mapping = sat3_to_graph(instance)
    open(graph_file, "w") do f
        write(f, graph_content)
    end
    
    # Save mapping
    open(mapping_file, "w") do f
        for (node, literal) in sort(collect(node_mapping))
            write(f, "Node $node: $literal\n")
        end
    end
    
    println("✅ Files saved successfully!")
    println()
    
    # Step 3: Analyze with community detection
    println("🔍 Step 3: Running community detection analysis...")
    
    if interactive
        println("   - Starting interactive analysis...")
        run_graph_interactive(graph_file)
    else
        println("   - Running automated analysis...")
        run_graph(graph_file)
    end
    
    println()
    println("🎉 Research pipeline completed!")
    println("📁 Generated files:")
    println("   - $md_file - Human-readable 3-SAT instance")
    println("   - $graph_file - Graph for community detection")
    println("   - $mapping_file - Node to literal mapping")
    
    return instance, graph_file, node_mapping
end

# Examples for different SAT solving difficulty regions
function run_research_examples()
    println("🔬 Running research examples for different SAT regions...")
    println()
    
    # Easy region (low clause/variable ratio)
    println("1. EASY REGION (ratio ≈ 2.0)")
    research_pipeline(5, 10, seed=100)
    println()
    
    # Critical region (around the phase transition)
    println("2. CRITICAL REGION (ratio ≈ 4.2)")
    research_pipeline(5, 21, seed=200)
    println()
    
    # Hard region (high clause/variable ratio)
    println("3. HARD REGION (ratio ≈ 6.0)")
    research_pipeline(5, 30, seed=300)
    println()
    
    println("🏁 All research examples completed!")
end

# Command line interface - only run when called as a script, not when included
if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) == 0
        println("🚀 Usage examples:")
        println("   julia research_pipeline.jl                    # Run research examples")
        println("   julia research_pipeline.jl 5 15              # 5 vars, 15 clauses")
        println("   julia research_pipeline.jl 5 15 123          # With seed")
        println("   julia research_pipeline.jl 5 15 123 interactive  # Interactive mode")
        println()
        
        print("🤔 Run research examples? (y/n): ")
        response = readline()
        if lowercase(strip(response)) in ["y", "yes", ""]
            run_research_examples()
        end
        
    elseif length(ARGS) >= 2
        num_vars = parse(Int, ARGS[1])
        num_clauses = parse(Int, ARGS[2])
        seed = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : nothing
        interactive = length(ARGS) >= 4 && ARGS[4] == "interactive"
        
        research_pipeline(num_vars, num_clauses, seed=seed, interactive=interactive)
    else
        println("❌ Error: Need at least 2 arguments (num_vars, num_clauses)")
        println("   Example: julia research_pipeline.jl 5 15")
    end
end
