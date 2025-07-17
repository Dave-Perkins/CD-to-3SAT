# 3-SAT Graph Representation

## Definitions

### Variable
A **variable** is a Boolean entity that can take one of two values: true or false.
- Notation: x₁, x₂, x₃, ..., xₙ
- Example: x₁ (can be true or false)

### Literal  
A **literal** is either:
1. A **positive literal**: a variable itself (e.g., x₁)
2. A **negative literal**: the negation of a variable (e.g., ¬x₁)

Examples:
- If x₁ is a variable, then both x₁ and ¬x₁ are literals
- x₁ is satisfied when the variable x₁ is assigned true
- ¬x₁ is satisfied when the variable x₁ is assigned false

### Clause
A **clause** in 3-SAT is a disjunction (OR) of exactly 3 literals.
- Example: (x₁ ∨ ¬x₂ ∨ x₃)
- A clause is satisfied if at least one of its literals is satisfied

### 3-SAT Formula
A **3-SAT formula** is a conjunction (AND) of clauses.
- Example: (x₁ ∨ ¬x₂ ∨ x₃) ∧ (¬x₁ ∨ x₂ ∨ ¬x₃) ∧ (x₁ ∨ x₂ ∨ x₃)
- The formula is satisfied if ALL clauses are satisfied

---

## Graph Representation Approach for graph12.txt

### Literal Graph Representation
- **Nodes**: Each literal (both positive and negative for each variable)
- **Edges**: Connect two literals if they appear together in the same clause
- **Edge Weights**: Number of clauses in which the two literals appear together

### Example: 3-SAT Instance
Instance: (x₁ ∨ ¬x₂ ∨ x₃) ∧ (¬x₁ ∨ x₂ ∨ ¬x₃) ∧ (x₁ ∨ x₂ ∨ x₃)
Variables: x₁, x₂, x₃
Literals: x₁, x₂, x₃, ¬x₁, ¬x₂, ¬x₃
Clauses: 
- C₁: (x₁ ∨ ¬x₂ ∨ x₃)
- C₂: (¬x₁ ∨ x₂ ∨ ¬x₃)  
- C₃: (x₁ ∨ x₂ ∨ x₃)

### Node Mapping (Simplified)
1. x₁ (positive literal of variable 1)
2. x₂ (positive literal of variable 2)  
3. x₃ (positive literal of variable 3)
4. ¬x₁ (negative literal of variable 1)
5. ¬x₂ (negative literal of variable 2)
6. ¬x₃ (negative literal of variable 3)

### Edge Weight Calculation
- x₁ and x₃ appear together in C₁ and C₃ → weight = 2
- x₁ and ¬x₂ appear together in C₁ → weight = 1
- etc.
