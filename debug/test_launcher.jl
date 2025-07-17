#!/usr/bin/env julia

"""
Test script to verify the launcher handles EOF and interrupts correctly.
"""

function test_launcher_with_piped_input()
    """Test launcher with piped input (should not hang)."""
    
    println("🧪 Testing launcher with piped input...")
    
    # Test with option 4 (quick test)
    cmd = `echo "4" | julia launcher.jl`
    
    try
        # Run with timeout to prevent hanging
        result = run(cmd, wait=false)
        
        # Wait up to 30 seconds for completion
        for i in 1:30
            sleep(1)
            if !process_running(result)
                println("✅ Launcher exited normally after $i seconds")
                return true
            end
        end
        
        # If we get here, it's hanging
        println("❌ Launcher appears to be hanging - killing process")
        kill(result, 9)
        return false
        
    catch e
        println("❌ Error running launcher: $e")
        return false
    end
end

function test_launcher_interrupt()
    """Test launcher response to Ctrl-C."""
    
    println("🧪 Testing launcher interrupt handling...")
    println("⚠️  This test requires manual intervention:")
    println("   1. The launcher will start")
    println("   2. Press Ctrl-C to interrupt it")
    println("   3. Check that it exits cleanly")
    
    print("Press Enter to start the test...")
    readline()
    
    # Start the launcher
    cmd = `julia launcher.jl`
    run(cmd)
    
    println("✅ Test completed - check that the launcher exited cleanly")
end

# Run tests
if !isempty(ARGS) && ARGS[1] == "pipe"
    test_launcher_with_piped_input()
elseif !isempty(ARGS) && ARGS[1] == "interrupt"
    test_launcher_interrupt()
else
    println("Usage:")
    println("  julia test_launcher.jl pipe      # Test piped input")
    println("  julia test_launcher.jl interrupt # Test interrupt handling")
end
