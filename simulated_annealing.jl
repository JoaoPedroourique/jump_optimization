using JuMP

mutable struct Instance
    has_box::Bool
    is_reached::Bool
    adjacent_vertices::Array{Int}
end

function graphReader(filepath::String)
    graph = Instance[]
    open(filepath) do f

        # line_number
        line = 0
        n = 0

        # read till end of file
        while !eof(f)
            # read a new / next line for every iteration          
            s = readline(f)
            words = split(s, ' ')
            if line == 0
                n = parse(Int, words[1]) # n is number of vertices
                for i = 1:n
                    instance = Instance(false, false, Int[])
                    push!(graph, instance)
                end
            else
                push!(graph[parse(Int, words[1])].adjacent_vertices, parse(Int, words[2]))
            end
            line += 1
        end
    end
    return graph, size(graph, 1)
end

function local_search(graph::Array{Instance}, number_of_vertices::Int)
    state = graph
    solution_value = 0
    actual_solution_value = 0
    improved = true
    while improved
        improved = false
        for index = 2:number_of_vertices
            state[index].has_box = !state[index].has_box
            if is_valid(state)
                actual_solution_value = 0
                actual_solution_value = calculate_solution_value(state)
            else
                state[index].has_box = !state[index].has_box
                continue
            end
            if actual_solution_value > solution_value
                improved = true
                solution_value = actual_solution_value
            else
                improved = false
                break
            end
        end
    end
    return state
end

function is_valid(state::Array{Instance})
    number_of_boxes = 0
    number_of_boxes_reached = 0
    state[1].is_reached = true
    for i = 2:size(state, 1)
        state[i].is_reached = false
    end
    for vertex in state
        if vertex.has_box
            number_of_boxes += 1
            if vertex.is_reached
                number_of_boxes_reached += 1
            end
        elseif !isempty(vertex.adjacent_vertices)
            for adjacent in vertex.adjacent_vertices
                state[adjacent].is_reached = true
            end
        end
    end
    if number_of_boxes == number_of_boxes_reached
        return true
    end
    return false
end

function simulated_annealing(initial_state::Array{Instance}, initial_temperature::Float64, final_temperature::Float64, iteration_number::Int, decrease_ratio::Float64)
    actual_temperature = initial_temperature
    best_solution = initial_state
    actual_solution = initial_state
    best_solution_value = calculate_solution_value(initial_state)
    actual_solution_value = best_solution_value

    while actual_temperature >= final_temperature
        for i = 0:iteration_number
            actual_solution, actual_solution_value = metropolis_algorithm(actual_solution, actual_temperature)
            if actual_solution_value > best_solution_value
                best_solution_value = actual_solution_value
                best_solution = actual_solution
            end
            actual_temperature = actual_temperature * decrease_ratio
        end
    end
    return best_solution, best_solution_value
end

function metropolis_algorithm(initial_solution::Array{Instance}, temperature::Float64)
    stop_index = 1000
    index = 0
    best_solution = Array{Instance}
    actual_solution = initial_solution
    number_of_vertices = size(initial_solution, 1)
    best_solution_value = 0
    actual_solution_value = calculate_solution_value(actual_solution)

    while index < stop_index
        i = rand(2:number_of_vertices)
        actual_solution[i].has_box = !actual_solution[i].has_box
        if is_valid(actual_solution)
            actual_solution_value = calculate_solution_value(actual_solution)
            delta = actual_solution_value - best_solution_value
            if delta >= 0
                best_solution = actual_solution
                best_solution_value = calculate_solution_value(actual_solution)
            else
                p = exp(((delta) / temperature))
                if rand() <= p
                    best_solution = actual_solution
                    best_solution_value = calculate_solution_value(actual_solution)
                end
            end
        else
            actual_solution[i].has_box = !actual_solution[i].has_box
            continue
        end
        index += 1
    end
    return best_solution, best_solution_value
end

function calculate_solution_value(state::Array{Instance})
    solution_value = 0
    for vertex in state
        solution_value += vertex.has_box
    end
    return solution_value
end

for file in [
    "instancias/instance_12_17.dat",
    "instancias/instance_50_60.dat",
    "instancias/instance_50_85.dat",
    "instancias/instance_50_120.dat",
    "instancias/instance_50_300.dat",
    "instancias/instance_100_180.dat",
    "instancias/instance_100_245.dat",
    "instancias/instance_100_490.dat",
    "instancias/instance_100_1225.dat",
    "instancias/instance_150_555.dat",
    "instancias/instance_150_1110.dat",
    "instancias/instance_150_2775.dat",
    "instancias/instance_200_990.dat",
    "instancias/instance_200_1980.dat",
    "instancias/instance_200_4950.dat",
    "instancias/instance_300_565.dat",
    "instancias/instance_500_6225.dat",
    "instancias/instance_500_12450.dat",
    "instancias/instance_500_31125.dat",
    "instancias/instance_1500_2920.dat",
    "instancias/instance_1000_19800.dat",
]
    graph = Instance[]
    n = 0
    graph, n = graphReader(file)
    initial_solution = local_search(graph, n)
    solution, solution_value = simulated_annealing(initial_solution, 100.0, 20.0, 15000, 0.85)

    print(file)
    print(": ")
    println(solution_value)
end