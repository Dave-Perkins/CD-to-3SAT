# 3-SAT Instance Designed for Positive Modularity

## Instance Metadata
- Variables: 6
- Clauses: 8
- Designed to create two distinct communities with minimal inter-connections

## Clauses

1. (x1 ∨ x2 ∨ ¬x3)
2. (¬x1 ∨ x2 ∨ x3)
3. (x1 ∨ ¬x2 ∨ x3)
4. (x4 ∨ x5 ∨ ¬x6)
5. (¬x4 ∨ x5 ∨ x6)
6. (x4 ∨ ¬x5 ∨ x6)
7. (x1 ∨ ¬x4 ∨ x2)
8. (¬x3 ∨ x6 ∨ ¬x5)

## Design Strategy

This instance is crafted to create two natural communities:
- **Community 1**: Variables {x1, x2, x3} appear together in clauses 1-3 and have dense interconnections
- **Community 2**: Variables {x4, x5, x6} appear together in clauses 4-6 and have dense interconnections  
- **Minimal bridge**: Only clauses 7-8 connect the two communities, creating weak inter-community links

This should result in a graph where:
- Nodes representing x1, x2, x3, ¬x1, ¬x2, ¬x3 form a tight community
- Nodes representing x4, x5, x6, ¬x4, ¬x5, ¬x6 form another tight community
- Few edges between the two communities
