# Custom 3-SAT Instance with High Modularity Communities

## Instance Metadata
- Variables: 4
- Clauses: 6
- Designed for positive modularity communities

## Clauses

1. (x1 ∨ x2 ∨ ¬x3)
2. (¬x1 ∨ ¬x2 ∨ x3)
3. (x1 ∨ ¬x2 ∨ x4)
4. (x3 ∨ x4 ∨ ¬x1)
5. (¬x3 ∨ ¬x4 ∨ x2)
6. (x2 ∨ x3 ∨ ¬x4)

## Design Strategy
This instance is designed so that:
- Variables x1, x2 appear together frequently (should form tight community)
- Variables x3, x4 appear together frequently (should form tight community)
- Few clauses mix variables from both groups
