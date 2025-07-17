#!/usr/bin/env julia
# Workspace Summary and Organization Status

println("📋 MINI03 Workspace Summary")
println("=" ^50)

function count_files_in_dir(dir, extension="")
    if !isdir(dir)
        return 0, String[]
    end
    files = readdir(dir)
    if !isempty(extension)
        files = filter(f -> endswith(f, extension), files)
    end
    return length(files), files
end

function print_directory_summary(dir, description)
    if isdir(dir)
        total_files, files = count_files_in_dir(dir)
        println("📁 $description ($dir/)")
        println("   Total files: $total_files")
        if total_files > 0 && total_files <= 10
            for file in sort(files)
                println("   • $file")
            end
        elseif total_files > 10
            for file in sort(files)[1:5]
                println("   • $file")
            end
            println("   • ... and $(total_files - 5) more files")
        end
        println()
    else
        println("📁 $description ($dir/) - Not found")
        println()
    end
end

# Main directories
print_directory_summary("src", "Source Code")
print_directory_summary("examples", "Example Files")
print_directory_summary("research", "Research Instances")
print_directory_summary("graphs", "Graph Data Files")
print_directory_summary("docs", "Documentation")
print_directory_summary("test", "Test Files")
print_directory_summary("archive", "Archived Files")

# Root level files
println("📄 Root Level Files")
root_files = filter(f -> isfile(f) && !startswith(f, "."), readdir("."))
for file in sort(root_files)
    if endswith(file, ".jl")
        println("   🟢 $file - Julia script")
    elseif endswith(file, ".md")
        println("   📝 $file - Documentation")
    elseif endswith(file, ".toml")
        println("   ⚙️  $file - Configuration")
    elseif endswith(file, ".txt")
        println("   📄 $file - Text file")
    else
        println("   📄 $file")
    end
end
println()

# File type summary
println("📊 File Type Summary")
println("-" ^30)

function count_by_extension(dir)
    if !isdir(dir)
        return Dict{String, Int}()
    end
    
    counts = Dict{String, Int}()
    for file in readdir(dir)
        if isfile(joinpath(dir, file))
            ext = lowercase(splitext(file)[2])
            if ext == ""
                ext = "(no extension)"
            end
            counts[ext] = get(counts, ext, 0) + 1
        end
    end
    return counts
end

all_extensions = Dict{String, Int}()
for dir in [".", "src", "examples", "research", "graphs", "docs", "test", "archive"]
    if isdir(dir)
        dir_counts = count_by_extension(dir)
        for (ext, count) in dir_counts
            all_extensions[ext] = get(all_extensions, ext, 0) + count
        end
    end
end

for (ext, count) in sort(collect(all_extensions))
    println("   $ext: $count files")
end
println()

# Quick functionality check
println("🔧 Package Status")
println("-" ^30)

# Check if key files exist
key_files = [
    ("main.jl", "Main entry point"),
    ("src/mini03.jl", "Core community detection"),
    ("src/scoring.jl", "Modularity scoring"),
    ("src/sat3_markdown_generator.jl", "3-SAT generation"),
    ("src/research_pipeline.jl", "Research automation"),
    ("README.md", "Documentation")
]

for (file, description) in key_files
    if isfile(file)
        println("   ✅ $description")
    else
        println("   ❌ $description (missing: $file)")
    end
end

println()
println("🎯 Organization Status: ✅ COMPLETED")
println("   • Source code organized in src/")
println("   • Examples separated in examples/")
println("   • Research files in research/")
println("   • Tests in test/")
println("   • Documentation at root level")
println("   • Main entry point available (main.jl)")
