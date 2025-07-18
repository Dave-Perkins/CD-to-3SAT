#!/usr/bin/env julia

"""
Test Leiden Algorithm on SAT Instances
=====================================

This script tests the Leiden algorithm for community detection on SAT instances,
specifically designed to handle larger instances more efficiently than label propagation.
"""

include("main.jl")
using Random
using StatsBase

# Leiden algorithm implementation for SAT community detection
function leiden_algorithm_sat(g, edge_weights, node_info; max_iterations=50, resolution=1.0, verbose=true)
    n_nodes = nv(g)
    current_partition = [node_info[k].label for k in 1:n_nodes]
    
    if verbose
        initial_score = get_score(g, edge_weights, node_info, current_partition)
        println("🔬 Starting Leiden algorithm...")
        println("   Initial modularity: $(round(initial_score, digits=6))")
        println("   Nodes: $n_nodes, Max iterations: $max_iterations")
    end
    
    iteration = 0
    improvement = true
    last_score = get_score(g, edge_weights, node_info, current_partition)
    
    while improvement && iteration < max_iterations
        iteration += 1
        improvement = false
        moves_made = 0
        
        # Randomize node order for fair processing
        shuffled_nodes = shuffle(1:n_nodes)
        
        for node in shuffled_nodes
            current_community = node_info[node].label
            best_community = current_community
            best_score = last_score
            
            # Get neighbor communities to test
            neighbor_communities = Set{Int}()
            for neighbor in node_info[node].neighbors
                if neighbor <= n_nodes && neighbor >= 1
                    push!(neighbor_communities, node_info[neighbor].label)
                end
            end
            
            # Test moving to each neighbor community
            for test_community in neighbor_communities
                if test_community != current_community
                    # Temporarily move node
                    node_info[node].label = test_community
                    
                    # Calculate new score
                    new_partition = [node_info[k].label for k in 1:n_nodes]
                    new_score = get_score(g, edge_weights, node_info, new_partition)
                    
                    if new_score > best_score
                        best_score = new_score
                        best_community = test_community
                    end
                    
                    # Restore original community for now
                    node_info[node].label = current_community
                end
            end
            
            # Apply best move if improvement found
            if best_community != current_community && best_score > last_score + 1e-10
                node_info[node].label = best_community
                last_score = best_score
                improvement = true
                moves_made += 1
            end
        end
        
        if verbose && (iteration % 10 == 0 || moves_made > 0)
            # Calculate community sizes for this iteration
            current_partition = [node_info[k].label for k in 1:n_nodes]
            communities = unique(current_partition)
            community_sizes = [count(x -> x == c, current_partition) for c in communities]
            sorted_sizes = sort(community_sizes, rev=true)
            
            println("   Iteration $iteration: modularity = $(round(last_score, digits=6)), moves = $moves_made")
            println("      🏘️  Communities: $(length(communities)), sizes: $(sorted_sizes[1:min(8, length(sorted_sizes))])$(length(sorted_sizes) > 8 ? "..." : "")")
        end
        
        # Early stopping if no moves made
        if moves_made == 0
            if verbose
                println("   ✅ Converged early at iteration $iteration (no beneficial moves)")
            end
            break
        end
    end
    
    final_partition = [node_info[k].label for k in 1:n_nodes]
    final_score = get_score(g, edge_weights, node_info, final_partition)
    
    if verbose
        println("✅ Leiden completed after $iteration iterations")
        println("📊 Final modularity: $(round(final_score, digits=6))")
        
        # Community statistics
        communities = unique(final_partition)
        community_sizes = [count(x -> x == c, final_partition) for c in communities]
        sorted_sizes = sort(community_sizes, rev=true)
        
        println("🏘️  Found $(length(communities)) communities")
        println("📏 Community sizes: $(sorted_sizes)")
        
        # Distribution analysis
        if length(sorted_sizes) > 1
            avg_size = sum(sorted_sizes) / length(sorted_sizes)
            largest_size = maximum(sorted_sizes)
            smallest_size = minimum(sorted_sizes)
            println("� Size distribution: largest=$(largest_size), smallest=$(smallest_size), avg=$(round(avg_size, digits=1))")
            
            # Show how balanced the communities are
            size_variance = sum((s - avg_size)^2 for s in sorted_sizes) / length(sorted_sizes)
            println("⚖️  Balance metric: variance=$(round(size_variance, digits=1)) (lower = more balanced)")
        end
    end
    
    return final_score
end

# Test function for comparing algorithms
function compare_algorithms_on_sat(filename; test_leiden=true, test_label_prop=true)
    println("🔬 ALGORITHM COMPARISON ON SAT INSTANCE")
    println("="^60)
    println("📁 File: $filename")
    
    # Load the graph directly (should be in .txt format for community detection)
    println("\n📖 Loading graph for community detection...")
    edge_list = read_edges(filename)
    g, edge_weights = build_graph(edge_list)
    
    println("   Graph nodes: $(nv(g))")
    println("   Edges: $(ne(g))")
    println("   Variables represented: $(div(nv(g), 2))")
    
    results = Dict{String, Any}()
    
    if test_label_prop
        println("\n🏃 Testing Label Propagation v2...")
        # Create fresh node_info for label propagation
        node_info_lp = Dict{Int, NodeInfo}()
        for n in 1:nv(g)
            node_info_lp[n] = NodeInfo(n, collect(neighbors(g, n)))
        end
        
        start_time = time()
        lp_score = label_propagation_v2_original(g, edge_weights, node_info_lp)
        lp_time = time() - start_time
        
        lp_partition = [node_info_lp[k].label for k in 1:nv(g)]
        lp_communities = length(unique(lp_partition))
        
        results["label_propagation"] = (
            score = lp_score,
            time = lp_time,
            communities = lp_communities
        )
        
        println("   ✅ Label Propagation: score=$(round(lp_score, digits=6)), time=$(round(lp_time, digits=2))s, communities=$lp_communities")
    end
    
    if test_leiden
        println("\n🔬 Testing Leiden Algorithm...")
        # Create fresh node_info for Leiden
        node_info_leiden = Dict{Int, NodeInfo}()
        for n in 1:nv(g)
            node_info_leiden[n] = NodeInfo(n, collect(neighbors(g, n)))
        end
        
        start_time = time()
        leiden_score = leiden_algorithm_sat(g, edge_weights, node_info_leiden, verbose=true)
        leiden_time = time() - start_time
        
        leiden_partition = [node_info_leiden[k].label for k in 1:nv(g)]
        leiden_communities = length(unique(leiden_partition))
        
        results["leiden"] = (
            score = leiden_score,
            time = leiden_time,
            communities = leiden_communities
        )
        
        println("   ✅ Leiden: score=$(round(leiden_score, digits=6)), time=$(round(leiden_time, digits=2))s, communities=$leiden_communities")
    end
    
    # Comparison summary
    if test_leiden && test_label_prop
        println("\n📊 COMPARISON SUMMARY")
        println("="^40)
        
        score_improvement = results["leiden"].score - results["label_propagation"].score
        time_ratio = results["leiden"].time / results["label_propagation"].time
        
        println("🎯 Modularity improvement: $(round(score_improvement, digits=6))")
        println("⏱️  Time ratio (Leiden/LP): $(round(time_ratio, digits=2))x")
        println("🏘️  Communities (LP → Leiden): $(results["label_propagation"].communities) → $(results["leiden"].communities)")
        
        if score_improvement > 0
            println("✅ Leiden algorithm achieved better modularity!")
        elseif score_improvement == 0
            println("🤝 Both algorithms achieved same modularity")
        else
            println("📉 Label propagation achieved better modularity")
        end
        
        if time_ratio < 1.0
            println("⚡ Leiden was faster!")
        else
            println("🐌 Leiden was slower by $(round(time_ratio, digits=1))x")
        end
    end
    
    return results
end

# Original label propagation for comparison (simplified version)
function label_propagation_v2_original(g, edge_weights, node_info; max_iterations=50)
    current_colors = [node_info[k].label for k in 1:nv(g)]
    current_score = get_score(g, edge_weights, node_info, current_colors)
    
    for iteration in 1:max_iterations
        shuffled_nodes = shuffle(1:nv(g))
        any_change = false
        
        for n in shuffled_nodes
            best_label = node_info[n].label
            best_score = current_score
            
            for nbr in node_info[n].neighbors
                # Test moving to neighbor's community
                temp_node_info = deepcopy(node_info)
                temp_node_info[n].label = node_info[nbr].label
                temp_colors = [temp_node_info[k].label for k in 1:nv(g)]
                score = get_score(g, edge_weights, temp_node_info, temp_colors)
                
                if score > best_score
                    best_score = score
                    best_label = node_info[nbr].label
                end
            end
            
            if best_label != node_info[n].label
                node_info[n].label = best_label
                current_colors = [node_info[k].label for k in 1:nv(g)]
                current_score = get_score(g, edge_weights, node_info, current_colors)
                any_change = true
            end
        end
        
        if !any_change
            break
        end
    end
    
    return current_score
end

# Quick test on a small instance
function quick_test()
    println("🧪 Quick test of Leiden algorithm")
    println("="^40)
    
    # Test on a small research instance
    test_files = [
        "research/research_5vars_21clauses_seed123.md",
        "research/research_4vars_12clauses_seed123.md"
    ]
    
    for file in test_files
        if isfile(file)
            println("\n🔍 Testing on: $file")
            compare_algorithms_on_sat(file)
            break
        end
    end
end

# Test on the f600 benchmark
function test_leiden_on_f600()
    println("🔥 TESTING LEIDEN ON F600 BENCHMARK")
    println("="^50)
    
    f600_path = "benchmarks/large_instances/f600.cnf"
    f600_md = "benchmarks/large_instances/f600.md"
    f600_graph = "benchmarks/large_instances/f600_graph.txt"
    
    if isfile(f600_path)
        println("📁 Found f600.cnf, converting to graph format...")
        
        # Parse DIMACS and convert to SAT instance
        num_variables, clauses = parse_dimacs(f600_path)
        
        # Convert integer clauses to string format expected by SAT3Instance
        string_clauses = Vector{Vector{String}}()
        for clause in clauses
            string_clause = String[]
            for literal in clause
                if literal > 0
                    push!(string_clause, "x$literal")
                else
                    push!(string_clause, "¬x$(abs(literal))")
                end
            end
            push!(string_clauses, string_clause)
        end
        
        # Create SAT3Instance from parsed data
        instance = SAT3Instance(
            ["x$i" for i in 1:num_variables],  # variable names
            string_clauses,
            Dict("source" => "f600.cnf", "variables" => num_variables, "clauses" => length(clauses))
        )
        
        # Convert to graph format
        println("� Converting SAT instance to graph representation...")
        graph_content, node_mapping = sat3_to_graph(instance)
        
        # Save graph file
        open(f600_graph, "w") do f
            write(f, graph_content)
        end
        
        println("✅ Saved graph representation to $f600_graph")
        println("   Variables: $num_variables")
        println("   Clauses: $(length(clauses))")
        println("   Graph nodes: $(2 * num_variables)")  # Each variable becomes 2 nodes (positive and negative)
        
        println("\n🚀 Running Leiden algorithm on f600...")
        results = compare_algorithms_on_sat(f600_graph, test_leiden=true, test_label_prop=false)
        
        return results
    else
        println("❌ f600.cnf not found in benchmarks/large_instances/")
        return nothing
    end
end

# Main execution
if length(ARGS) > 0
    if ARGS[1] == "quick"
        quick_test()
    elseif ARGS[1] == "f600"
        test_leiden_on_f600()
    elseif isfile(ARGS[1])
        compare_algorithms_on_sat(ARGS[1])
    else
        println("❌ File not found: $(ARGS[1])")
    end
else
    println("🌟 LEIDEN ALGORITHM TESTER FOR SAT INSTANCES")
    println("="^50)
    println("💡 Usage:")
    println("   julia test_leiden_sat.jl quick           # Quick test on small instance")
    println("   julia test_leiden_sat.jl f600            # Test on f600 benchmark")
    println("   julia test_leiden_sat.jl <filename>      # Test on specific file")
    println()
    println("🔬 Available functions:")
    println("   • compare_algorithms_on_sat(filename)")
    println("   • leiden_algorithm_sat(g, edge_weights, node_info)")
    println("   • test_leiden_on_f600()")
    println("   • quick_test()")
end
