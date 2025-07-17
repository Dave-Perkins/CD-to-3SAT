# MINI03 - Community Detection for 3-SAT Research

A Julia package for analyzing community structure in 3-SAT problems using graph-based methods.

## 🚀 Quick Start

```bash
# Clone and enter directory
cd mini03

# Start Julia and load the package
julia main.jl

# Basic usage
julia> run_graph("graphs/graph03.txt")
julia> research_pipeline(5, 15, seed=123)
```

## ⚡ Quick Reference

### Most Common Commands
```bash
# Start the package
julia main.jl

# Analyze any graph file interactively
julia> run_graph_interactive("path/to/file.txt")

# Generate and analyze new research instance
julia> research_pipeline(5, 15, seed=123)

# One-liner analysis (no prompts)
julia -e "include(\"main.jl\"); run_graph_interactive(\"research/your_file.txt\")"

# Analyze specific research files
julia> run_graph_interactive("research/research_5vars_10clauses_seed100.txt")   # Easy
julia> run_graph_interactive("research/research_5vars_21clauses_seed200.txt")   # Critical
julia> run_graph_interactive("research/research_5vars_30clauses_seed300.txt")   # Hard
```

## 📁 Directory Structure

```
mini03/
├── main.jl                 # Main entry point
├── src/                    # Core source code
│   ├── mini03.jl          # Main community detection engine
│   ├── scoring.jl         # Modularity calculation
│   ├── plot_graph.jl      # Visualization components
│   ├── sat3_markdown_generator.jl  # 3-SAT instance generation
│   ├── research_pipeline.jl       # Research automation
│   ├── interactive_launcher.jl    # Interactive interface
│   └── repl_setup.jl      # REPL configuration
├── examples/              # Example files and outputs
├── research/             # Research instances and results
├── graphs/               # Graph data files
├── docs/                 # Documentation
├── test/                 # Test files
└── archive/              # Archived development files
```

## 🔬 Core Functionality

### Community Detection
- **Modularity-based optimization** for finding community structure
- **Interactive visualization** with manual refinement capabilities
- **Automatic clustering** using greedy modularity optimization

### 3-SAT Research Pipeline
- **Markdown-based SAT instances** for human-readable research
- **Automated generation** across different difficulty regions
- **Graph conversion** from SAT clauses to community detection format
- **Systematic studies** with reproducible seeding

## 📊 Research Features

### SAT Difficulty Regions
- **Easy Region** (ratio ≈ 2.0): Under-constrained, typically satisfiable
- **Critical Region** (ratio ≈ 4.2): Phase transition, hardest to solve
- **Hard Region** (ratio ≈ 6.0): Over-constrained, typically unsatisfiable

### Analysis Workflow
1. Generate 3-SAT instances in markdown format
2. Convert to weighted graphs (literals as nodes, clause co-occurrence as edges)
3. Apply community detection to identify variable relationships
4. Visualize and refine clustering interactively

## 🛠️ Usage Examples

### Basic Graph Analysis
```julia
# Load and analyze a graph file
julia> run_graph("graphs/graph03.txt")

# Interactive analysis with manual refinement
julia> run_graph_interactive("graphs/graph03.txt")
```

### 3-SAT Research
```julia
# Generate single research instance
julia> research_pipeline(5, 15, seed=123)

# Run systematic study across SAT regions
julia> research_pipeline(5, 10, seed=100)  # Easy
julia> research_pipeline(5, 21, seed=200)  # Critical  
julia> research_pipeline(5, 30, seed=300)  # Hard
```

### Analyzing Research Files
```julia
# Interactive analysis of generated research instances
julia> run_graph_interactive("research/research_5vars_10clauses_seed100.txt")

# Compare different difficulty regions
julia> run_graph_interactive("research/research_5vars_21clauses_seed200.txt")  # Critical
julia> run_graph_interactive("research/research_5vars_30clauses_seed300.txt")  # Hard

# One-liner for quick analysis
julia -e "include(\"main.jl\"); run_graph_interactive(\"research/your_file.txt\")"
```

### Custom 3-SAT Generation
```julia
# Generate instance
julia> instance = generate_random_3sat(4, 10, seed=42)

# Convert to markdown
julia> md_content = to_markdown(instance, "My Research Instance")

# Save to file
julia> open("my_instance.md", "w") do f
           write(f, md_content)
       end

# Convert to graph format
julia> graph_content, mapping = sat3_to_graph(instance)
```

## 📋 File Formats

### Markdown 3-SAT Format
```markdown
# Research Instance: 3 variables, 5 clauses

## Variables
- x1
- x2  
- x3

## Clauses
1. (x1 ∨ ¬x2 ∨ x3)
2. (¬x1 ∨ x2 ∨ ¬x3)
3. (x1 ∨ x2 ∨ x3)
4. (¬x1 ∨ ¬x2 ∨ ¬x3)
5. (x1 ∨ ¬x3 ∨ x2)

## Metadata
- Variables: 3
- Clauses: 5
- Ratio: 1.67 (clauses/variables)
- Generated: random
- Seed: 42
```

### Graph Format
```
1 2 3
1 3 2
2 4 1
3 4 2
```
Format: `node1 node2 weight` (one edge per line)

## 🎯 Research Applications

- **SAT Solver Analysis**: Understanding variable relationships in hard instances
- **Phase Transition Studies**: Analyzing community structure across difficulty regions
- **Algorithm Development**: Testing community detection methods on structured problems
- **Educational Research**: Visualizing Boolean satisfiability concepts

## 📈 Modularity Scoring

The package uses modularity to measure community quality:
- **Higher modularity** indicates stronger community structure
- **Interactive refinement** allows manual optimization
- **Automatic optimization** finds good initial clustering

## 🔧 Dependencies

- Julia 1.10+
- GLMakie.jl (for visualization)
- Random.jl (for instance generation)
- StatsBase.jl (for analysis utilities)

## 📝 License

This project is part of the MINI03 research initiative exploring community detection in computational problems.
