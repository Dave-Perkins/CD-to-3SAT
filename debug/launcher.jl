#!/usr/bin/env julia

# Launcher script for stable graph analysis
# Handles package installation and provides user-friendly interface

using Pkg
using Printf

# Try to load basic packages only
BASIC_PACKAGES_LOADED = false
try
    @eval using Pkg
    @eval using Printf
    global BASIC_PACKAGES_LOADED = true
    println("✅ Basic packages loaded successfully")
catch e
    println("⚠️  Basic packages not loaded: $e")
end

println("🌟 STABLE GRAPH ANALYSIS LAUNCHER")
println("="^50)

# Add signal handler for proper cleanup
function handle_signals()
    """Set up signal handlers for clean exit."""
    # Handle Ctrl-C gracefully
    ccall(:jl_exit_on_sigint, Cvoid, (Cint,), 0)
end

function ensure_packages()
    """Ensure all required packages are installed."""
    
    required_packages = ["CairoMakie", "Colors", "GLMakie", "GraphMakie", "Graphs"]
    
    println("📦 Checking required packages...")
    
    packages_to_install = []
    
    for package in required_packages
        try
            # Simple check: try to find the package in the environment
            Pkg.status(package; io=devnull)
            println("   ✅ $package: Available")
        catch
            println("   ⚠️  $package: Not found")
            push!(packages_to_install, package)
        end
    end
    
    if !isempty(packages_to_install)
        println("📥 Installing missing packages: $(join(packages_to_install, ", "))")
        try
            Pkg.add(packages_to_install)
            println("✅ All packages installed successfully")
        catch install_error
            println("❌ Failed to install packages: $install_error")
            return false
        end
    else
        println("✅ All required packages are available")
    end
    
    return true
end

function show_menu()
    """Show the main menu."""
    
    println("\n🎯 CHOOSE AN OPTION:")
    println("="^50)
    println("📊 INTERACTIVE WORKFLOWS (GLMakie - opens in windows)")
    println("1. Process single graph (graphs/graph_input.txt) - INTERACTIVE")
    println("2. Process specific graph file - INTERACTIVE")
    println("3. Batch process all test graphs - INTERACTIVE")
    println()
    println("📄 STABLE WORKFLOWS (CairoMakie - saves PNG files)")
    println("4. Process single graph (graphs/graph_input.txt) - STABLE PNG")
    println("5. Process specific graph file - STABLE PNG")
    println("6. Batch process all test graphs - STABLE PNG")
    println()
    println("🧪 TESTING & UTILITIES")
    println("7. Run quick test (stable workflow)")
    println("8. Exit")
    println()
    print("Enter your choice (1-8): ")
end

function get_available_graphs()
    """Get list of available graph files."""
    
    graph_files = []
    graphs_dir = "graphs"
    
    if !isdir(graphs_dir)
        # Fallback to current directory if graphs folder doesn't exist
        graphs_dir = "."
    end
    
    for file in readdir(graphs_dir)
        if endswith(file, ".txt") && startswith(file, "graph")
            push!(graph_files, joinpath(graphs_dir, file))
        end
    end
    
    return sort(graph_files)
end

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

function main_menu()
    """Main interactive menu."""
    
    if !ensure_packages()
        println("❌ Failed to install required packages. Exiting.")
        return
    end
    
    # Load packages if not already loaded
    if !BASIC_PACKAGES_LOADED
        try
            println("📦 Loading basic packages...")
            @eval using Pkg
            @eval using Printf
            println("✅ Basic packages loaded successfully")
        catch e
            println("❌ Failed to load basic packages: $e")
            return
        end
    end
    
    # Load both workflows (they will load their own packages)
    try
        println("📄 Loading interactive workflow...")
        include("mini03.jl")
        println("✅ Interactive workflow loaded successfully")
        
        println("📄 Loading stable workflow...")
        include("mini03_stable.jl")
        println("✅ Stable workflow loaded successfully")
        
        # Test that the main functions are available
        if !isdefined(Main, :run_graph_interactive)
            println("⚠️  Warning: run_graph_interactive function (interactive) not found")
        end
        
        if !isdefined(Main, :run_stable_workflow)
            println("⚠️  Warning: run_stable_workflow function not found")
        end
        
        if isdefined(Main, :run_graph_interactive) && isdefined(Main, :run_stable_workflow)
            println("✅ Both interactive and stable workflows are available")
        end
        
    catch e
        println("❌ Failed to load workflows: $e")
        println("💡 Make sure mini03.jl and mini03_stable.jl exist and are valid")
        return
    end
    
    try
        while true
            show_menu()
            
            choice_input = safe_readline()
            if choice_input === nothing
                println("👋 Exiting...")
                break
            end
            
            choice = strip(choice_input)
            
            if choice == "1"
                println("\n🚀 Processing graphs/graph_input.txt with INTERACTIVE workflow...")
                try
                    # Use Base.invokelatest to handle world age issues
                    Base.invokelatest(run_graph_interactive, "graphs/graph_input.txt")
                    println("✅ Processing completed successfully!")
                    println("💡 Check for any interactive windows that opened")
                catch workflow_error
                    println("❌ Error during processing: $workflow_error")
                    println("💡 Check that graphs/graph_input.txt exists and is properly formatted.")
                end
                
            elseif choice == "2"
                available_graphs = get_available_graphs()
                
                if isempty(available_graphs)
                    println("❌ No graph files found in graphs/ directory")
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
                        println("🚀 Processing $filename with INTERACTIVE workflow...")
                        try
                            # Use Base.invokelatest to handle world age issues
                            Base.invokelatest(run_graph_interactive, filename)
                            println("✅ Processing completed successfully!")
                            println("💡 Check for any interactive windows that opened")
                        catch workflow_error
                            println("❌ Error during processing: $workflow_error")
                            println("💡 Check the error details above.")
                        end
                    else
                        println("❌ Invalid graph number")
                    end
                catch parse_error
                    # Treat as filename
                    if isfile(input)
                        println("🚀 Processing $input with INTERACTIVE workflow...")
                        try
                            # Use Base.invokelatest to handle world age issues
                            Base.invokelatest(run_graph_interactive, input)
                            println("✅ Processing completed successfully!")
                            println("💡 Check for any interactive windows that opened")
                        catch workflow_error
                            println("❌ Error during processing: $workflow_error")
                            println("💡 Check the error details above.")
                        end
                    else
                        println("❌ File not found: $input")
                    end
                end
                
            elseif choice == "3"
                available_graphs = get_available_graphs()
                
                if isempty(available_graphs)
                    println("❌ No graph files found in graphs/ directory")
                    continue
                end
                
                println("📦 Starting INTERACTIVE batch processing...")
                println("💡 This will open multiple interactive windows!")
                
                for (i, filename) in enumerate(available_graphs)
                    println("🔄 Processing $i/$(length(available_graphs)): $filename")
                    try
                        # Use Base.invokelatest to handle world age issues
                        Base.invokelatest(run_graph_interactive, filename)
                        println("   ✅ $filename completed")
                    catch e
                        println("   ❌ $filename failed: $e")
                    end
                end
                println("✅ Interactive batch processing completed!")
                
            elseif choice == "4"
                println("\n🚀 Processing graphs/graph_input.txt with STABLE workflow...")
                try
                    # Use Base.invokelatest to handle world age issue
                    Base.invokelatest(run_stable_workflow, "graphs/graph_input.txt")
                    println("✅ Processing completed successfully!")
                catch workflow_error
                    println("❌ Error during processing: $workflow_error")
                    println("💡 Check that graphs/graph_input.txt exists and is properly formatted.")
                end
                
            elseif choice == "5"
                available_graphs = get_available_graphs()
                
                if isempty(available_graphs)
                    println("❌ No graph files found in graphs/ directory")
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
                        println("🚀 Processing $filename with STABLE workflow...")
                        try
                            Base.invokelatest(run_stable_workflow, filename)
                            println("✅ Processing completed successfully!")
                        catch workflow_error
                            println("❌ Error during processing: $workflow_error")
                            println("💡 Check the error details above.")
                        end
                    else
                        println("❌ Invalid graph number")
                    end
                catch parse_error
                    # Treat as filename
                    if isfile(input)
                        println("🚀 Processing $input with STABLE workflow...")
                        try
                            Base.invokelatest(run_stable_workflow, input)
                            println("✅ Processing completed successfully!")
                        catch workflow_error
                            println("❌ Error during processing: $workflow_error")
                            println("💡 Check the error details above.")
                        end
                    else
                        println("❌ File not found: $input")
                    end
                end
                
            elseif choice == "6"
                available_graphs = get_available_graphs()
                
                if isempty(available_graphs)
                    println("❌ No graph files found in graphs/ directory")
                    continue
                end
                
                println("📦 Starting STABLE batch processing...")
                try
                    Base.invokelatest(batch_process_graphs, String.(available_graphs))
                    println("✅ Batch processing completed successfully!")
                catch batch_error
                    println("❌ Error during batch processing: $batch_error")
                    println("💡 Check the error details above.")
                end
                
            elseif choice == "7"
                println("🧪 Running quick test...")
                include("test_stable.jl")
                
            elseif choice == "8"
                println("👋 Goodbye!")
                break
                
            else
                println("❌ Invalid choice. Please enter 1-8.")
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

# Set up signal handlers and run the main menu
try
    handle_signals()
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
