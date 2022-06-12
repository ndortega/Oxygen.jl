module FileUtil

using HTTP

export file, @hostfiles

"""
    file(filepath::String)

Reads a file as a String
"""
function file(filepath::String)
    return read(open(filepath), String)
end


"""
    getfiles(folder::String)

Return all files inside a folder (searches nested folders)
"""
function getfiles(folder::String)
    target_files::Array{String} = []
    for (root, _, files) in walkdir(folder)
        for file in files
            push!(target_files, joinpath(root, file))
        end
    end
    return target_files
end

"""
    @iteratefiles(folder::String, func::Function)

Walk through all files in a directory and apply a function to each file
"""
macro iteratefiles(folder::String, func)
    local target_files::Array{String} = getfiles(folder)
    quote
        local action = $(esc(func))
        for filepath in $target_files
            action(filepath)
        end
    end
end

"""
    hostfiles(folder::String, mountdir::String, addroute::Function)

This macro is used to discover files & register them to the router while  
leaving the `addroute` function to determine how to register the files
"""
macro hostfiles(folder::String, mountdir::String, addroute)
    quote 
        local folder = $folder
        local directory = $mountdir
        local separator = Base.Filesystem.path_separator

        @iteratefiles $folder function(filepath::String)

            # remove the first occurrence of the root folder from the filepath before "mounting"
            local cleanedmountpath = replace(filepath, "$(folder)$(separator)" => "", count=1)

            # generate the path to mount the file to
            local mountpath = "/$directory/$cleanedmountpath"

            # load file into memory on sever startup
            local body = file(filepath)

            # precalculate content type 
            local content_type = HTTP.sniff(body)
            local headers = ["Content-Type" => content_type]

            # register the file route
            addroute(mountpath, headers, filepath)

            # also register file to the root of each subpath if this file is an index.html
            if endswith(mountpath, "/index.html")
                result = findfirst("/index.html", mountpath)
                index = first(result) - 1
                trimmedpath = mountpath[begin:index]
                addroute(trimmedpath, headers, filepath)
            end

        end
    end
    
end

end
