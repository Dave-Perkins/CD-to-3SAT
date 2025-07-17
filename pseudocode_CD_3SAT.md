### Pseudocode for how we will use community detection results to satisfy the correponding 3-SAT instance 

Input: A Boolean formula and its graph version
Output: An assignment (that may or may not satisfy the formula)

1. Initialize all nodes as "unassigned".
2. Use modularity to score the graph.
3. Sort the communities by the amount they contributed to the modularity score, from highest to lowest.
4. Loop through the sorted communities:
   1. Sort the unassigned nodes in the current community by total edge weight.
   2. Loop through the sorted nodes:
      1. Assign the current node to "true".
      2. Assign its negation to "false" (no matter what community it is in). 
5. Check if the resulting assignment satisfies the given Boolean formula.