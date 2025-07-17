#!/usr/bin/env julia

# Test script to run multiple graphs without getting stuck
# Usage: julia test_graphs.jl

#=
SOLUTIONS FOR THE "EVALUATING" ISSUE AND GRAPHICS PROBLEMS:

The "Evaluating" issue happens because GLMakie graphics backend can get stuck 
after closing and reopening windows. Here are several solutions:

1. USE THE TEST SCRIPT (RECOMMENDED):
   Instead of running `julia mini03.jl` directly, use:
   ```bash
   julia test_graphs.jl
   ```

2. RESTART GRAPHICS FUNCTION:
   If you get stuck, you need to load the functions first, then run:
   ```julia
   include("mini03.jl")    # Load the functions first!
   restart_graphics()      # Now this will work
   ```

3. MANUAL RESET COMMANDS:
   If the graphics get stuck, try these commands in the Julia REPL:
   ```julia
   using GLMakie           # Make sure GLMakie is loaded
   GLMakie.closeall()
   GLMakie.activate!()
   ```

4. FORCE RESTART (if needed):
   If Julia completely freezes, you might need to:
   - Kill the Julia process (Ctrl+C or close terminal)
   - Start a fresh Julia session
   - Run the script again

5. INTERACTIVE USAGE:
   For testing different graphs without restarting Julia:
   ```julia
   include("mini03.jl")           # Load functions first!
   run_graph("graph03.txt")       # First graph
   restart_graphics()             # Clean up
   run_graph("graph09.txt")       # Second graph
   restart_graphics()             # Clean up
   run_graph("graph10.txt")       # Third graph
   ```

6. WHY THE ISSUE HAPPENS:
   - GLMakie backend doesn't properly clean up after closing
   - Julia session retains some graphics state
   - Multiple display calls can conflict
   - OpenGL contexts can get corrupted

7. IMPROVEMENTS MADE TO FIX IT:
   - Better error handling around graphics operations
   - Automatic cleanup when windows close
   - Graphics restart function to reset state
   - Wrapper functions that catch errors gracefully
   - Progress messages to see where issues occur
   - Using Figure instead of Scene for better control

8. BEST PRACTICES:
   - Always use run_graph() instead of main() directly
   - Call restart_graphics() between runs if you notice slowdown
   - If testing many graphs, restart Julia session periodically
   - Keep terminal open to see error messages
   - Use Ctrl+C to interrupt if Julia gets stuck

9. TESTING DIFFERENT GRAPHS:
   Available graph files:
   - graph03.txt: Small graph for basic testing
   - graph05.txt: Triangle + Square with connecting edge
   - graph09.txt: 3 communities with weighted edges (good modularity)
   - graph10.txt: Complete graph K8 (negative modularity)

10. TROUBLESHOOTING:
    If you still have issues:
    - Try updating Julia: `juliaup update`
    - Try a different backend: use CairoMakie instead of GLMakie
    - Check system graphics drivers
    - On some systems, X11 forwarding issues can cause problems

11. COMMON ERROR FIXES:
    - "UndefVarError: restart_graphics not defined" 
      → Run: include("mini03.jl") first
    - "Package GLMakie not found"
      → Run: using Pkg; Pkg.add("GLMakie")
    - Julia stuck at "Evaluating" (even after restart_graphics())
      → This means Julia session is corrupted, must force restart

12. WHEN restart_graphics() DOESN'T WORK:
    If restart_graphics() doesn't stop the "Evaluating" state, the Julia session
    is too corrupted to recover. You MUST:
    
    a) FORCE KILL JULIA:
       - Press Ctrl+C multiple times in terminal
       - If that doesn't work, close the terminal window entirely
       - Or use: kill -9 <julia_process_id>
    
    b) START FRESH SESSION:
       - Open new terminal
       - Navigate to project directory: cd /path/to/mini03
       - Run: julia test_graphs.jl
    
    c) NUCLEAR OPTION (if still stuck):
       - Restart your computer
       - Clear Julia package precompilation cache:
         rm -rf ~/.julia/compiled
       - Reinstall packages if needed

13. EXTREME CORRUPTION - WHEN EVEN KILL DOESN'T WORK:
    If Julia still shows "Evaluating" after kill -9, this indicates:
    - Terminal itself is corrupted
    - System graphics drivers are locked
    - OpenGL context is stuck at system level
    
    IMMEDIATE SOLUTIONS:
    a) CLOSE TERMINAL COMPLETELY:
       - Don't just kill Julia - close the entire terminal application
       - On Mac: Cmd+Q to quit Terminal app entirely
       - On Linux: Close terminal window completely
    
    b) KILL ALL JULIA PROCESSES SYSTEM-WIDE:
       ```bash
       # In a NEW terminal window:
       sudo killall julia
       sudo killall Julia
       pkill -f julia
       ```
    
    c) RESTART GRAPHICS DRIVERS (Mac):
       ```bash
       sudo killall WindowServer
       # This will restart the graphics system (screen will flash)
       ```
    
    d) RESTART GRAPHICS DRIVERS (Linux):
       ```bash
       sudo systemctl restart display-manager
       # Or restart X11 entirely
       ```
    
    e) LAST RESORT - REBOOT:
       - If nothing else works, restart your computer
       - This always fixes graphics corruption issues

13. PREVENTION STRATEGIES:
    - Never run main() directly multiple times
    - Always use run_graph() wrapper function
    - Close graph windows properly (press Enter when prompted)
    - Restart Julia session every 5-10 graph runs
    - Use fresh terminal for each major testing session

14. SIGNS JULIA SESSION IS CORRUPTED:
    - Stuck at "Evaluating" for more than 30 seconds
    - restart_graphics() doesn't respond
    - Any GLMakie command hangs
    - Terminal becomes unresponsive
    → Time to force restart!

15. BETTER WORKFLOW:
    Instead of trying to recover a stuck session:
    - Kill Julia immediately when it gets stuck
    - Start fresh - it's faster than trying to fix corruption
    - Use separate terminal tabs for different tests
    - Save your work frequently (files are auto-saved anyway)
=#

# Include the main file to get access to all functions
include("mini03.jl")

# Alternative restart function if mini03.jl fails to load
function backup_restart_graphics()
    try
        using GLMakie
        GLMakie.closeall()
        GLMakie.activate!()
        println("Graphics backend restarted successfully (backup method).")
    catch e
        println("Could not restart graphics backend: $e")
        println("Please restart Julia manually.")
    end
end

# Emergency function for when Julia is deeply stuck
function emergency_exit()
    println("EMERGENCY: Julia session appears corrupted!")
    println("Force killing Julia process...")
    println("You should:")
    println("1. Close this terminal completely")
    println("2. Open a new terminal")
    println("3. Navigate back to this directory")
    println("4. Run: julia test_graphs.jl")
    
    # Try to force garbage collection and exit
    try
        GC.gc()
        GLMakie.closeall()
        exit(1)  # Force exit with error code
    catch
        # If even exit() doesn't work, print instructions
        println("If you see this message, Julia is completely stuck.")
        println("You must manually close the terminal window.")
    end
end

# System-level emergency cleanup script
function create_emergency_cleanup_script()
    script_content = """#!/bin/bash
# Emergency cleanup script for stuck Julia/GLMakie processes

echo "=== EMERGENCY JULIA CLEANUP ==="
echo "Killing all Julia processes..."

# Kill all Julia processes
sudo killall julia 2>/dev/null || true
sudo killall Julia 2>/dev/null || true  
pkill -f julia 2>/dev/null || true

# Wait a moment
sleep 2

# Check if any Julia processes remain
if pgrep -f julia > /dev/null; then
    echo "Some Julia processes are still running. Forcing kill..."
    sudo pkill -9 -f julia
fi

echo "Cleaning Julia compilation cache..."
rm -rf ~/.julia/compiled/* 2>/dev/null || true

echo "Done! You can now start a fresh Julia session."
echo "Run: julia test_graphs.jl"
"""
    
    open("emergency_cleanup.sh", "w") do f
        write(f, script_content)
    end
    
    # Make it executable
    run(`chmod +x emergency_cleanup.sh`)
    
    println("Created emergency_cleanup.sh script!")
    println("If Julia gets completely stuck, run in a NEW terminal:")
    println("  ./emergency_cleanup.sh")
end

function test_multiple_graphs()
    graphs = ["graph03.txt", "graph09.txt", "graph10.txt"]
    
    for graph in graphs
        println("\n" * "="^50)
        println("Testing $graph")
        println("="^50)
        
        try
            run_graph(graph)
            println("✓ Successfully completed $graph")
        catch e
            println("✗ Error with $graph: $e")
            println("Attempting to restart graphics...")
            restart_graphics()
        end
        
        println("\nReady for next graph...")
    end
end

function run_single_graph(filename="graph03.txt")
    println("Running $filename...")
    run_graph(filename)
end

# USAGE EXAMPLES:
# Uncomment one of these to test:

# Option 1: Test a single graph
run_single_graph("graph03.txt")

# Option 2: Test multiple graphs in sequence
# test_multiple_graphs()

# Option 3: Interactive testing (run these one by one in Julia REPL)
# include("test_graphs.jl")
# run_graph("graph03.txt")
# restart_graphics()  # if needed
# run_graph("graph09.txt")
# restart_graphics()  # if needed  
# run_graph("graph10.txt")

#=
GRAPH COMPARISONS:

graph03.txt: 
- Basic unweighted graph
- Good for testing basic functionality

graph09.txt:
- 3 communities with weighted edges
- Should show POSITIVE modularity score
- Strong intra-community connections (weight 3)
- Weak inter-community connections (weight 1-2)

graph10.txt:
- Complete graph K8 (every node connected to every other)
- Should show NEGATIVE modularity score (~-2.0)
- All edges have weight 1
- No meaningful community structure
- Good test for validating modularity calculation
=#
