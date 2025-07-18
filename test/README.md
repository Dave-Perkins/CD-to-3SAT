# Test Directory

This directory contains all test files for the CD-to-3SAT project, organized for better workspace management.

## Test File Organization

### Core Test Files
- `test_basic.jl` - Basic functionality tests
- `quick_test.jl` - Quick validation tests
- `simple_parse_test.jl` - Simple parsing tests
- `final_modularity_test.jl` - Final modularity validation

### Modularity Tests
- `test_modularity_analysis.jl` - Modularity analysis tests
- `test_correct_modularity.jl` - Modularity correctness tests
- `test_fixed_modularity.jl` - Fixed modularity implementation tests
- `test_sparse_modularity.jl` - Sparse modularity tests
- `test_ultra_sparse.jl` - Ultra-sparse graph tests
- `test_positive_modularity_instance.jl` - Positive modularity instances
- `test_custom_positive_mod.jl` - Custom positive modularity tests

### SAT Solver Tests
- `test_community_sat_solver.jl` - Community detection SAT solver tests
- `test_improved_solver.jl` - Improved solver implementation tests
- `test_full_solver.jl` - Full solver functionality tests
- `test_clean_solver.jl` - Clean solver implementation tests
- `test_fixed_sat_solver.jl` - Fixed SAT solver tests

### Analysis and Processing Tests
- `test_extreme_analysis.jl` - Extreme case analysis tests
- `test_formula_parsing.jl` - Formula parsing tests
- `test_degree_bug.jl` - Degree calculation bug tests
- `test_any_instance.jl` - General instance tests
- `test_multiple_instances.jl` - Multiple instance processing tests
- `test_fixed_real_instance.jl` - Fixed real instance tests

### Visualization and Output Tests
- `test_visualization.jl` - Visualization functionality tests
- `test_verbose_single.jl` - Verbose single instance tests

### Test Data
- `test_data/` - Directory containing test data files
  - `test_extreme_modularity.txt` - Extreme modularity test data
  - `test_positive_modularity.txt` - Positive modularity test data
  - `test_positive_modularity.md` - Positive modularity documentation

## Running Tests

### Individual Tests
```bash
cd test/
julia test_basic.jl
julia quick_test.jl
```

### From Project Root
```bash
julia test/test_basic.jl
julia test/quick_test.jl
```

### Batch Testing
To run multiple tests, you can create a test runner script or use the existing test infrastructure.

## Test Organization Notes

- All test files were moved from the project root to improve workspace organization
- Debug-specific tests remain in the `debug/` directory
- Test data files are organized in the `test_data/` subdirectory
- File paths in test files may need to be updated to reference project files correctly

## Maintenance

When adding new tests:
1. Place test scripts in this directory
2. Place test data in the `test_data/` subdirectory
3. Update this README if adding new test categories
4. Ensure test file paths correctly reference project files
