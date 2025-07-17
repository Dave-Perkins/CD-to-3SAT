# REPL-friendly graph analysis functions
# Use this when you're already in the Julia REPL

using Pkg

function ensure_packages()
    """Ensure required packages are available."""
    required_packages = ["GLMakie", "GraphMakie", "Graphs", "Colors"]
    
    println("📦 Checking packages...")
    
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

function load_graph_functions()
    """Load the main graph analysis functions."""
    try
        include("mini03.jl")
        println("✅ Graph analysis functions loaded!")
        return true
    catch e
        println("❌ Failed to load mini03.jl: $e")
        return false
    end
end

function list_graphs()
    """List available graph files."""
    graphs_dir = "graphs"
    
    if !isdir(graphs_dir)
        println("❌ graphs/ directory not found")
        return String[]
    end
    
    graph_files = []
    for file in readdir(graphs_dir)
        if endswith(file, ".txt") && startswith(file, "graph")
            push!(graph_files, file)
        end
    end
    
    if isempty(graph_files)
        println("❌ No graph files found in graphs/ directory")
        return String[]
    end
    
    println("📁 Available graph files:")
    for (i, file) in enumerate(sort(graph_files))
        println("   $i. $file")
    end
    
    return sort(graph_files)
end

function quick_setup()
    """Quick setup for REPL use."""
    println("🚀 REPL GRAPH ANALYSIS SETUP")
    println("="^40)
    
    if !ensure_packages()
        return false
    end
    
    if !load_graph_functions()
        return false
    end
    
    println("\n💡 Available functions:")
    println("   • run_graph(\"graphs/filename.txt\") - Run analysis")
    println("   • run_graph_interactive(\"graphs/filename.txt\") - Interactive mode")
    println("   • list_graphs() - Show available files")
    println("   • restart_graphics() - Fix graphics issues")
    
    println("\n🎯 Quick examples:")
    println("   julia> run_graph(\"graphs/graph03.txt\")")
    println("   julia> run_graph_interactive(\"graphs/graph05.txt\")")
    
    list_graphs()
    
    return true
end

# Auto-run setup when this file is included
quick_setup()
