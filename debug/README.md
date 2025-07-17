# Debug and Development Files

This folder contains various debug, test, and development files created during the development of the graph analysis project.

## File Categories

### Debug Scripts
- `debug_*.jl` - Various debugging scripts for specific issues
- `verify_modularity.jl` - Manual modularity calculation verification

### Test Scripts
- `test_*.jl` - Comprehensive test scripts for different components
- `test_modularity_comprehensive.jl` - Extensive modularity testing

### Backup Files
- `*_stable.jl` - Stable backup versions of main files
- `scoring_standard.jl` - Alternative modularity implementation for comparison

### Development Launchers
- `simple_*.jl` - Simplified launcher versions
- `launcher.jl` - Old launcher version

### Utilities
- `emergency_cleanup.sh` - Emergency cleanup script

## Usage

These files are kept for reference and debugging purposes. The main project files are in the parent directory:
- `mini03.jl` - Main graph analysis code
- `interactive_launcher.jl` - Interactive launcher
- `repl_setup.jl` - REPL-friendly setup
- `scoring.jl` - Modularity scoring function
- `plot_graph.jl` - Interactive visualization

## Notes

Most debug files reference the main project files using relative paths like `include("../mini03.jl")`. If you need to run them, make sure the paths are correct or run them from the parent directory.
