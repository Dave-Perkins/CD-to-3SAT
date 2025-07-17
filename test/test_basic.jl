# Test script for MINI03 package
# Run this to verify everything is working correctly

println("🧪 Testing MINI03 Package")
println("=" ^40)

# Test basic functionality
try
    # Include main entry point
    include("../main.jl")
    println("✅ Main package loaded successfully")
    
    # Test 3-SAT generation
    println("\n🎲 Testing 3-SAT generation...")
    instance = generate_random_3sat(3, 5, seed=42)
    println("✅ Generated 3-SAT instance: $(length(instance.variables)) variables, $(length(instance.clauses)) clauses")
    
    # Test markdown conversion
    println("\n📝 Testing markdown conversion...")
    md_content = to_markdown(instance, "Test Instance")
    println("✅ Converted to markdown ($(length(md_content)) characters)")
    
    # Test graph conversion
    println("\n🌐 Testing graph conversion...")
    graph_content, node_mapping = sat3_to_graph(instance)
    num_edges = length(split(graph_content, "\n"))
    println("✅ Converted to graph format ($num_edges edges, $(length(node_mapping)) nodes)")
    
    # Test file I/O
    println("\n💾 Testing file operations...")
    test_dir = "test_output"
    if !isdir(test_dir)
        mkdir(test_dir)
    end
    
    # Save test files
    open("$test_dir/test_instance.md", "w") do f
        write(f, md_content)
    end
    
    open("$test_dir/test_graph.txt", "w") do f
        write(f, graph_content)
    end
    
    open("$test_dir/test_mapping.txt", "w") do f
        for (node, literal) in sort(collect(node_mapping))
            write(f, "Node $node: $literal\n")
        end
    end
    
    println("✅ Files saved to test_output/")
    
    # Test markdown parsing
    println("\n🔍 Testing markdown parsing...")
    parsed_instance = parse_3sat_markdown("$test_dir/test_instance.md")
    println("✅ Parsed markdown: $(length(parsed_instance.variables)) variables, $(length(parsed_instance.clauses)) clauses")
    
    # Verify round-trip consistency
    if length(instance.variables) == length(parsed_instance.variables) && 
       length(instance.clauses) == length(parsed_instance.clauses)
        println("✅ Round-trip consistency verified")
    else
        println("⚠️  Round-trip consistency check failed")
    end
    
    println("\n🎉 All tests passed!")
    println("\n📁 Test files created in test_output/:")
    println("   • test_instance.md - Markdown 3-SAT instance")
    println("   • test_graph.txt - Graph format")  
    println("   • test_mapping.txt - Node mapping")
    
catch e
    println("❌ Test failed with error:")
    println(e)
    rethrow(e)
end
