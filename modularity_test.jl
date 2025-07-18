#!/usr/bin/env julia

# Simple Modularity Test - Small Examples
include("main.jl")

println("🔬 MODULARITY ANALYSIS TEST")
println("="^40)
println("📊 Testing community detection modularity on small instances")
println()

# Test on small research instances first
small_files = [
    "research/research_3vars_5clauses_seed42.md",
    "research/research_4vars_8clauses_seed888.md", 
    "research/research_5vars_15clauses.md"
]

results = []

for (i, file) in enumerate(small_files)
    if isfile(file)
        print("$(i)/$(length(small_files)) $(basename(file)): ")
        try
            # Parse the instance to get basic info
            content = read(file, String)
            vars_match = match(r"Variables: (\d+)", content)
            clauses_match = match(r"Clauses: (\d+)", content)
            vars = vars_match !== nothing ? parse(Int, vars_match[1]) : 0
            clauses = clauses_match !== nothing ? parse(Int, clauses_match[1]) : 0
            
            # Solve with our algorithm
            start = time()
            result = solve_3sat(file)
            solve_time = time() - start
            
            # Extract modularity (this might need adjustment based on result structure)
            modularity = haskey(result, :modularity) ? result[:modularity] : 
                        hasproperty(result, :modularity) ? result.modularity : "N/A"
            
            sat_status = result.satisfiable ? "SAT" : "UNSAT"
            println("$(sat_status) | Mod: $(typeof(modularity) == String ? modularity : round(modularity, digits=3)) | $(round(solve_time, digits=3))s")
            
            push!(results, (
                file = basename(file),
                vars = vars,
                clauses = clauses,
                satisfiable = result.satisfiable,
                modularity = modularity,
                time = solve_time
            ))
            
        catch e
            println("ERROR: $e")
        end
    else
        println("$(i)/$(length(small_files)) $(basename(file)): FILE NOT FOUND")
    end
end

println()
println("📊 MODULARITY SUMMARY:")
println("="^40)
for r in results
    if r.modularity != "N/A"
        println("$(r.file): $(r.vars)v, $(r.clauses)c → Mod: $(typeof(r.modularity) == String ? r.modularity : round(r.modularity, digits=3))")
    end
end

if !isempty(results)
    valid_modularity = [r.modularity for r in results if r.modularity != "N/A" && typeof(r.modularity) <: Number]
    if !isempty(valid_modularity)
        println()
        println("📈 Modularity Stats:")
        println("   Average: $(round(sum(valid_modularity)/length(valid_modularity), digits=3))")
        println("   Range: $(round(minimum(valid_modularity), digits=3)) - $(round(maximum(valid_modularity), digits=3))")
    end
end

println("\n🏁 Modularity test complete!")
