using Documenter
using Oxygen

# escape and replace text as needed
function sanitizefile(filelines)
    content = ""
    skips = 0
    for line in filelines    
        if skips > 0
            skips -= 1
            continue
        elseif contains(line, "<!-- START HTML -->")
            content *= "```@raw html\n"
        elseif contains(line, "<!-- END HTML -->")
            content *= "```\n"
        elseif contains(line, "<!-- REPLACE")        
            _, replace_value, _ = split(line, r"\{\{|\}\}")
            content *= "$replace_value\n"
            skips += 1 
        else 
            content *= "$line\n"
        end
    end
    return content
end

# generate index.md and move assets
readme = readlines(open("../README.md"))
write("src/index.md", sanitizefile(readme))
cp("../oxygen.png", "./src/oxygen.png", force=true)

makedocs(
    sitename = "Oxygen.jl",
    format = Documenter.HTML(),
    modules = [Oxygen]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/ndortega/Oxygen.jl.git"
)


