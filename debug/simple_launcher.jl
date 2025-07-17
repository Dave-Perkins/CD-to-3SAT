#!/usr/bin/env julia

# Simple launcher script for stable graph analysis

println("🌟 STABLE GRAPH ANALYSIS LAUNCHER")
println("="^50)

function safe_readline(prompt="")
    """Safely read a line from stdin with proper error handling."""
    
    if !isempty(prompt)
        print(prompt)
    end
    
    try
        if eof(stdin)
            return nothing
        end
        return readline()
    catch e
        if isa(e, InterruptException)
            println("\n🛑 Interrupted by user")
            return nothing
        elseif isa(e, EOFError)
            println("\n📄 End of input reached")
            return nothing
        else
            println("\n❌ Error reading input: $e")
            return nothing
        end
    end
end

function show_menu()
    """Show the main menu."""
    
    println("\n🎯 CHOOSE AN OPTION:")
    println("="^30)
    println("1. Process graph_input.txt")
    println("2. Process specific graph file")
    println("3. Batch process all test graphs")
    println("4. Run quick test")
    println("5. Exit")
    println()
end

function get_available_graphs()
    """Get list of available graph files."""
    
    graph_files = []
    for file in readdir(".")
        if endswith(file, ".txt") && startswith(file, "graph")
            push!(graph_files, file)
        end
    end
    
    return sort(graph_files)
end

function main_menu()
    """Main interactive menu."""
    
    # Try to load the stable workflow
    try
        include("mini03_stable.jl")
        println("✅ Stable workflow loaded successfully")
    catch e
        println("❌ Failed to load stable workflow: $e")
        println("Make sure mini03_stable.jl exists in the current directory")
        return
    end
    
    try
        while true
            show_menu()
            
            choice_input = safe_readline("Enter your choice (1-5): ")
            if choice_input === nothing
                println("👋 Exiting...")
                break
            end
            
            choice = strip(choice_input)
            
            if choice == "1"
                println("\n🚀 Processing graph_input.txt...")
                try
                    run_stable_workflow("graph_input.txt")
                catch e
                    println("❌ Error: $e")
                end
                
            elseif choice == "2"
                available_graphs = get_available_graphs()
                
                if isempty(available_graphs)
                    println("❌ No graph files found in current directory")
                    continue
                end
                
                println("\n📁 Available graph files:")
                for (i, file) in enumerate(available_graphs)
                    println("   $i. $file")
                end
                println()
                
                input_result = safe_readline("Enter graph number or filename: ")
                if input_result === nothing
                    println("👋 Exiting...")
                    break
                end
                
                input = strip(input_result)
                
                # Check if it's a number
                try
                    graph_idx = parse(Int, input)
                    if 1 <= graph_idx <= length(available_graphs)
                        filename = available_graphs[graph_idx]
                        println("🚀 Processing $filename...")
                        run_stable_workflow(String(filename))
                    else
                        println("❌ Invalid graph number")
                    end
                catch
                    # Treat as filename
                    if isfile(input)
                        println("🚀 Processing $input...")
                        run_stable_workflow(String(input))
                    else
                        println("❌ File not found: $input")
                    end
                end
                
            elseif choice == "3"
                available_graphs = get_available_graphs()
                
                if isempty(available_graphs)
                    println("❌ No graph files found in current directory")
                    continue
                end
                
                println("📦 Starting batch processing...")
                try
                    batch_process_graphs(available_graphs)
                catch e
                    println("❌ Error during batch processing: $e")
                end
                
            elseif choice == "4"
                println("🧪 Running quick test...")
                test_graphs = ["graph03.txt", "graph05.txt", "graph09.txt", "graph10.txt"]
                
                for graph_file in test_graphs
                    if isfile(graph_file)
                        println("🔍 Testing: $graph_file")
                        try
                            run_stable_workflow(graph_file)
                        catch e
                            println("   💥 Error: $e")
                        end
                        println()
                    else
                        println("⚠️  Skipping $graph_file (not found)")
                    end
                end
                
            elseif choice == "5"
                println("👋 Goodbye!")
                break
                
            else
                println("❌ Invalid choice. Please enter 1-5.")
            end
            
            println("\n" * "="^50)
            continue_result = safe_readline("Press Enter to continue...")
            if continue_result === nothing
                println("👋 Exiting...")
                break
            end
        end
    catch e
        if isa(e, InterruptException)
            println("\n🛑 Interrupted by user. Exiting...")
        else
            println("\n❌ Unexpected error: $e")
        end
    end
end

# Run the main menu
println("📦 Loading required packages and modules...")
try
    main_menu()
catch e
    if isa(e, InterruptException)
        println("\n🛑 Process interrupted. Exiting...")
        exit(1)
    else
        println("\n❌ Fatal error: $e")
        exit(1)
    end
end
