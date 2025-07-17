#!/usr/bin/env julia

# Interactive Graph Analysis Launcher
# Only loads GLMakie/GraphMakie for interactive windows
# Usage: 
#   From command line: julia interactive_launcher.jl [filename]
#   From Julia REPL: include("repl_setup.jl")

using Pkg
using Printf

println("📊 INTERACTIVE GRAPH ANALYSIS LAUNCHER")
println("="^50)
println("💡 REPL USERS: Use include(\"repl_setup.jl\") instead!")
println("="^50)

function ensure_interactive_packages()
    """Ensure interactive packages are installed."""
    
    required_packages = ["GLMakie", "GraphMakie", "Graphs"]
    
    println("📦 Checking interactive packages...")
    
    packages_to_install = []
    
    for package in required_packages
        try
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

function main()
    """Main function."""
    
    if !ensure_interactive_packages()
        println("❌ Failed to install required packages. Exiting.")
        return
    end
    
    # Load the interactive workflow
    try
        println("📄 Loading interactive workflow...")
        include("mini03.jl")
        println("✅ Interactive workflow loaded successfully")
        
        if !isdefined(Main, :run_graph)
            println("⚠️  Warning: run_graph function not found")
            return
        end
        
        println("✅ Interactive functions are available")
        
    catch e
        println("❌ Failed to load interactive workflow: $e")
        println("💡 Make sure mini03.jl exists and is valid")
        return
    end
    
    # Check if filename was passed as command line argument
    if length(ARGS) > 0
        filename = ARGS[1]
        
        # If filename doesn't include path, check in graphs folder
        if !isfile(filename) && isfile(joinpath("graphs", filename))
            filename = joinpath("graphs", filename)
        end
        
        if isfile(filename)
            println("🚀 Processing $filename with INTERACTIVE workflow...")
            try
                Base.invokelatest(run_graph, filename)
                println("✅ Processing completed successfully!")
            catch workflow_error
                println("❌ Error during processing: $workflow_error")
            end
        else
            println("❌ File not found: $filename")
            # Suggest files in graphs folder
            graphs_files = filter(f -> endswith(f, ".txt") && startswith(f, "graph"), readdir("graphs", join=false))
            if !isempty(graphs_files)
                println("💡 Available files in graphs/ folder:")
                for file in sort(graphs_files)
                    println("   - $file")
                end
            end
        end
        return
    end
    
    # Show available graphs for interactive selection
    available_graphs = get_available_graphs()
    
    if isempty(available_graphs)
        println("❌ No graph files found in graphs/ directory")
        return
    end
    
    println("\n📁 Available graph files:")
    for (i, file) in enumerate(available_graphs)
        println("   $i. $file")
    end
    println()
    
    print("Enter graph number or filename: ")
    flush(stdout)  # Ensure prompt is displayed
    
    try
        input = strip(readline(stdin))
        
        if isempty(input)
            println("❌ No input provided")
            return
        end
        
        println("📝 You entered: '$input'")
        
        # Check if it's a number
        try
            graph_idx = parse(Int, input)
            if 1 <= graph_idx <= length(available_graphs)
                filename = available_graphs[graph_idx]
                println("🚀 Processing $filename with INTERACTIVE workflow...")
                try
                    Base.invokelatest(run_graph, filename)
                    println("✅ Processing completed successfully!")
                catch workflow_error
                    println("❌ Error during processing: $workflow_error")
                end
            else
                println("❌ Invalid graph number. Please enter 1-$(length(available_graphs))")
            end
        catch parse_error
            # Treat as filename
            # Try different path variations
            test_paths = [
                input,
                joinpath("graphs", input),
                joinpath("graphs", input * ".txt")
            ]
            
            filename_found = nothing
            for test_path in test_paths
                if isfile(test_path)
                    filename_found = test_path
                    break
                end
            end
            
            if filename_found !== nothing
                println("🚀 Processing $filename_found with INTERACTIVE workflow...")
                try
                    Base.invokelatest(run_graph, filename_found)
                    println("✅ Processing completed successfully!")
                catch workflow_error
                    println("❌ Error during processing: $workflow_error")
                end
            else
                println("❌ File not found: $input")
                println("💡 Available files:")
                for (i, file) in enumerate(available_graphs)
                    println("   $i. $file")
                end
            end
        end
        
    catch input_error
        println("❌ Error reading input: $input_error")
        println("💡 Try running the script from command line instead:")
        println("   julia interactive_launcher.jl graphs/graph03.txt")
    end
end

# Run the main function
main()
