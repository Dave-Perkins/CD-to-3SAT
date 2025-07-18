# 🌟 Julia Graph Analysis Project

A robust community detection and modularity scoring system for weighted graphs with interactive visualization and optimized workflows.

## 🚀 Quick Start

### Option 1: Interactive Launcher (Recommended)
```bash
julia interactive_launcher.jl [filename]
```
- Interactive GLMakie visualization
- Command-line argument support
- Menu-driven file selection
- Automatic package installation

### Option 2: REPL Usage
```julia
julia> include("repl_setup.jl")
julia> run_graph("graphs/graph03.txt")
julia> run_graph_interactive("graphs/graph05.txt")
```
- Perfect for development and testing
- Direct function access
- No launcher overhead

### Option 3: Direct Usage
```julia
# Main workflow (interactive visualization)
julia -e "include(\"mini03.jl\"); run_graph(\"graphs/graph03.txt\")"
```
```

## 📁 Project Structure

```
mini03/
├── interactive_launcher.jl  # Main interactive launcher
├── repl_setup.jl            # REPL-friendly setup script
├── mini03.jl                # Core graph analysis functions
├── plot_graph.jl            # Interactive visualization (GLMakie)
├── scoring.jl               # Modularity scoring with corrected calculation
├── graphs/                  # All graph files and outputs
│   ├── graph01.txt          # Test graph files
│   ├── graph02.txt
│   ├── ...
│   └── graph_input.txt      # Default input file
├── docs/                    # Project documentation
│   ├── README.md            # Documentation index
│   ├── PROJECT_STATUS.md    # Current project status
│   ├── SOLUTION.md          # Technical solution details
│   └── *.md                 # Development history and fixes
└── debug/                   # Debug and development files
    ├── README.md            # Documentation for debug files
    ├── debug_*.jl           # Various debugging scripts
    ├── test_*.jl            # Comprehensive test scripts
    ├── *_stable.jl          # Backup versions
    └── verify_modularity.jl # Manual calculation verification
```

## 🎯 Features

### Interactive Workflow (GLMakie)
- ✅ Real-time interactive graph visualization
- ✅ Click nodes to change community assignments
- ✅ Drag nodes to rearrange layout
- ✅ Live modularity score updates
- ✅ Corrected modularity calculation (fixed -2.0 bug)
- ✅ Robust color mapping and KeyError handling

### Stable Workflow (CairoMakie)
- ✅ Reliable PNG file output
- ✅ No hanging or graphics issues
- ✅ Batch processing support
- ✅ Consistent visualization quality
- ✅ Perfect for automated workflows

### Launcher Features
- ✅ Automatic package installation
- ✅ Robust error handling
- ✅ Menu-driven interface
- ✅ World age issue resolution
- ✅ Clean workspace organization

## 📊 Graph File Format

Graph files should contain edges (one per line):
```
# Community 1
1 2
2 3
3 1

# Community 2
4 5
4 6
5 6
```

## 🛠️ Available Functions

### Interactive Functions (mini03.jl)
- `run_graph(filename)` - Simple interactive workflow
- `run_graph_interactive(filename)` - Interactive with menu
- `restart_graphics()` - Fix graphics backend issues

### Stable Functions (mini03_stable.jl)
- `run_stable_workflow(filename)` - Single file processing
- `run_stable_batch(directory)` - Batch processing

## 🔧 Requirements

- Julia 1.10+
- Packages: GLMakie, CairoMakie, GraphMakie, Graphs, Colors
- All packages are automatically installed by the launchers

## 📈 Usage Examples

### Process a single graph interactively
```bash
julia src/interactive_launcher.jl graphs/graph03.txt
```

### Batch process all graphs (stable)
```bash
julia launcher.jl
# Choose option 6: Batch process all test graphs - STABLE PNG
```

### Quick test
```bash
julia launcher.jl
# Choose option 7: Run quick test (stable workflow)
```

## 🎨 Output

- **Interactive workflow**: Opens interactive windows with GLMakie
- **Stable workflow**: Saves PNG files to `graphs/` directory
- **Visualizations**: Color-coded communities with modularity scores
- **File naming**: `{filename}_visualization.png` or `batch_{n}_visualization.png`

## 🚨 Troubleshooting

### Graphics Issues
- Use the stable workflow (CairoMakie) for reliable output
- The launcher includes automatic graphics backend restart
- Call `restart_graphics()` in interactive mode if needed

### Package Issues
- Launchers automatically install missing packages
- Run `julia -e "using Pkg; Pkg.instantiate()"` for manual setup

### File Issues
- All graph files should be in the `graphs/` directory
- Use absolute paths or run from the project directory
- Check that graph files are properly formatted

## 🔧 Recent Updates

### July 2025 - Workspace Organization
- ✅ **Organized test files**: Moved all test files to `test/` directory with categorized organization
- ✅ **Documentation consolidation**: Moved all documentation markdown files to `docs/` directory
- ✅ **Improved structure**: Created clear separation between code, tests, documentation, and data
- ✅ **Enhanced navigation**: Updated documentation index with comprehensive file organization

### December 2024 - Batch Processing Fix
- ✅ **Fixed batch processing output location**: All batch visualization files now save to `graphs/` subfolder
- ✅ **Consistent file organization**: Both single file and batch processing outputs go to the same location
- ✅ **Clean workspace**: No more visualization files scattered in the main directory

## 📚 Documentation

For detailed documentation, see the [`docs/`](docs/) folder:

### Core Documentation
- **[`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md)** - Current project capabilities and status
- **[`docs/SOLUTION.md`](docs/SOLUTION.md)** - Technical solution details and algorithms
- **[`docs/README.md`](docs/README.md)** - Main documentation index

### Implementation Documentation  
- **[`docs/ENHANCED_PIPELINE_SUMMARY.md`](docs/ENHANCED_PIPELINE_SUMMARY.md)** - Enhanced research pipeline summary
- **[`docs/IMPLEMENTATION_COMPLETE.md`](docs/IMPLEMENTATION_COMPLETE.md)** - Complete implementation details
- **[`docs/IMPROVED_IMPLEMENTATION.md`](docs/IMPROVED_IMPLEMENTATION.md)** - Implementation improvements
- **[`docs/COMMUNITY_GUIDED_SAT_IMPLEMENTATION.md`](docs/COMMUNITY_GUIDED_SAT_IMPLEMENTATION.md)** - Community-guided SAT solving implementation
- **[`docs/pseudocode_CD_3SAT.md`](docs/pseudocode_CD_3SAT.md)** - Community Detection to 3-SAT pseudocode

### Analysis Documentation
- **[`docs/MODULARITY_ANALYSIS_FINDINGS.md`](docs/MODULARITY_ANALYSIS_FINDINGS.md)** - Modularity analysis findings
- **[`docs/positive_modularity_instance.md`](docs/positive_modularity_instance.md)** - Positive modularity research

### Development History
- **[`docs/CLEANUP_SUMMARY.md`](docs/CLEANUP_SUMMARY.md)** - Workspace organization summary
- **[`docs/INTERACTIVE_ENHANCEMENTS.md`](docs/INTERACTIVE_ENHANCEMENTS.md)** - Interactive feature improvements
- **[`docs/LAUNCHER_FIXES.md`](docs/LAUNCHER_FIXES.md)** - Launcher system development history
- **[`docs/DOCUMENTATION_ORGANIZATION.md`](docs/DOCUMENTATION_ORGANIZATION.md)** - Documentation organization notes
- **[`docs/WORKSPACE_ORGANIZATION.md`](docs/WORKSPACE_ORGANIZATION.md)** - Comprehensive workspace cleanup summary

### Research Documentation
- **[`docs/3SAT_community_detection_research.md`](docs/3SAT_community_detection_research.md)** - Community detection research
- **[`docs/3SAT_graph_representation.md`](docs/3SAT_graph_representation.md)** - Graph representation methods

## 🎯 Recommendations

1. **For reliable output**: Use the interactive launcher (`interactive_launcher.jl`)
2. **For development**: Use REPL setup (`repl_setup.jl`) 
3. **For exploration**: Use the interactive workflow with visualization
4. **For automation**: Use direct function calls with `mini03.jl`

---

**Status**: ✅ Complete and fully functional
**Last Updated**: July 2025
