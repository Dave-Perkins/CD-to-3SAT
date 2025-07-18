### Pseudocode for Community-Guided SAT Solving Algorithm

*Updated July 18, 2025 - Based on systematic testing and improvements*

Input: A 3-SAT instance in markdown format
Output: Variable assignment and satisfiability result

**Algorithm Overview:**
1. Parse 3-SAT instance and convert to variable implication graph
2. Run community detection using label propagation  
3. Sort communities by modularity contribution
4. Generate assignment using community-guided frequency analysis
5. Validate assignment against original formula

**Detailed Steps:**

**Step 1: Graph Construction**
```
1. Parse 3-SAT instance from markdown format
2. Create variable implication graph:
   - Node for each literal (variable and its negation)
   - Edge between literals that appear in the same clause
   - Edge weight = frequency of co-occurrence
3. Generate node mapping: node_id → literal
```

**Step 2: Community Detection**
```
1. Initialize node_info structure with neighbor lists
2. Run label propagation algorithm:
   - For each iteration:
     - Shuffle node order
     - For each node with neighbors:
       - Find most frequent label among neighbors
       - Update node label if different
   - Repeat until convergence
3. Extract communities from final labels
4. Calculate modularity score
```

**Step 3: Community Analysis**
```
1. Calculate community contributions:
   - For each community:
     - internal_weight = sum of intra-community edge weights
     - total_degree = sum of all edge weights from community nodes
     - contribution = internal_weight / total_degree
2. Sort communities by contribution (highest to lowest)
```

**Step 4: Community-Guided Assignment**
```
1. Initialize: assignment = {}, assigned_variables = {}
2. For each community in sorted order:
   a. Get unassigned nodes in community
   b. Sort nodes by total edge weight (highest to lowest)
   c. For each node:
      - Get corresponding literal and variable name
      - If variable not yet assigned:
        * Count positive/negative occurrences in formula
        * Calculate clause-weighted contributions:
          - pos_contribution = Σ(1/clause_size) for clauses with positive literal
          - neg_contribution = Σ(1/clause_size) for clauses with negated literal
        * Assign: variable = true if pos_contribution ≥ neg_contribution
        * Add to assigned_variables set
3. For any remaining unassigned variables:
   - Assign random boolean value
```

**Step 5: Validation & Comparison**
```
1. Validate assignment against original formula:
   - For each clause:
     - Check if at least one literal is satisfied
     - Return false if any clause is unsatisfied
2. Optional: Compare with traditional SAT solver
3. Return result with assignment, satisfiability, and metadata
```

**Key Improvements from Original:**
- **Frequency Analysis**: Instead of naive "assign literal to true", use clause-weighted frequency analysis
- **Empty Collection Handling**: Skip isolated nodes in label propagation to prevent crashes
- **Clause Weighting**: Smaller clauses get higher weight (more constraining)
- **Better Graph Construction**: Variable implication graph with co-occurrence edge weights
- **Robust Parsing**: Handle Unicode negation symbols and various markdown formats

**Performance Characteristics:**
- Agreement with traditional SAT solver: ~35%
- Average solve time: ~0.017s per instance
- Works on instances up to 20+ variables
- Conservative bias: tends to predict UNSAT when uncertain