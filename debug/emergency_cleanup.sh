#!/bin/bash
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

echo "Cleaning package precompilation cache..."
rm -rf ~/.julia/scratchspaces/* 2>/dev/null || true

echo "Done! You can now start a fresh Julia session."
echo ""
echo "Available commands:"
echo "  julia -e 'include(\"mini03.jl\"); run_graph(\"graph03.txt\")'"
echo "  julia -e 'include(\"mini03.jl\"); run_graph_interactive(\"graph03.txt\")'"
echo "  julia launcher.jl"
