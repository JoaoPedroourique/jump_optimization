module file_reader
using Graphs

# read file contents and return graph defined by it
function graphReader(filepath::String)
    g = SimpleGraph(0)
    open(filepath) do f

        # line_number
        line = 0

        # read till end of file
        while !eof(f)
            # read a new / next line for every iteration          
            s = readline(f)
            words = split(s, ' ')
            if (line == 0)
                n = parse(Int, words[1]) # n is number of vertices

                add_vertices!(g, n)
            else
                origin = parse(Int, words[1])
                destiny = parse(Int, words[2])

                add_edge!(g, origin, destiny)
            end
            line += 1
        end

    end
    return g
end

end

# function main()
#     g = graphReader("instancias/instance_50_60.dat")
#     for v in vertices(g)
#         println("$v ")
#     end
#     for edge in edges(g)
#         println("$edge ")
#     end

# end

# main()