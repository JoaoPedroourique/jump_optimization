include("./file_reader.jl")
using .file_reader
using JuMP
using GLPK
using Graphs

# arquivos que não dão erro de memória
for file in [
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
]

    graph = file_reader.graphReader(file)
    n = nv(graph) # total de vértices
    m = ne(graph)

    model = Model(GLPK.Optimizer)

    # limite de tempo
    set_time_limit_sec(model, 35 * 60.0)

    # Definiçao das variaveis
    @variable(model, x[1:n], Bin)
    @variable(model, y[1:n, 1:n, 1:n], Bin)
    @variable(model, b[1:n, 1:n], Int)

    # Definiçao da funçao objetivo
    @objective(model, Max, sum(x[j] for j in 1:n))

    # Restriçoes

    # não há caixa no vértice de origem
    @constraint(model, x[1] == 0)

    #= 
    condição para assegurar que o modelo tenta encontrar caminhos apenas
    em arestas que existem no grafo
    =#
    for i in 1:n
        for j in 1:n
            for k in 1:n
                if !has_edge(graph, i, j)
                    @constraint(model,
                        y[i, j, k] == 0
                    )
                end
            end
        end
    end

    #= 
    o fluxo no vértice de origem,
    no cenário em que  j é o destino, é -1 se o vértice j tem uma caixa, 0 se não tem.
    =#
    for j in 1:n
        @constraint(model, b[1, j] == -x[j])
    end

    #= 
    fluxo em vértices intermediários é sempre 0
    =#
    for i in 1:n
        for j in 1:n
            if i != 1 && i != j
                @constraint(model,
                    b[i, j] == 0
                )
                #= 
                    fluxo no vértice de destino, no cenário em que  j é o destino,
                    é 1 se o vértice j tem uma caixa,  0 se não tem
                =#
            elseif i != 1 && i == j
                @constraint(model,
                    b[i, j] == x[j]
                )
            end
        end
    end

    #= 
    quando o vértice k é o destino, 
    o fluxo que entra em qualquer vértice i menos o fluxo que sai de qualquer vértice i é igual
    ao fluxo desejado para aquele vértice.
    =#
    for i in 1:n
        for k in 1:n
            @constraint(model,
                sum(y[j, i, k] for j in 1:n)
                -
                sum(y[i, j, k] for j in 1:n)
                ==
                b[i, k]
            )
        end
    end

    #= 
    quando o vértice k é o destino, 
    arestas que levem a um vértice j (diferente de k)
    só podem fazer parte do caminho se não tiverem caixas
    =#
    for i in 1:n
        for j in 1:n
            for k in 1:n
                if j != k
                    @constraint(model,
                        x[j] + y[i, j, k] <= 1
                    )
                end
            end
        end
    end

    optimize!(model)
    if termination_status(model) == MOI.OPTIMAL
        println("Solução ótima encontrada!")
        @show objective_value(model)
        ans = objective_value(model)
        open("meus_resultados.dat", "a") do file
            write(file, "\n$n $m $ans Sim")
        end
        println("$n $m $ans Sim")
    else
        s = termination_status(model)
        println("Solução ótima não encontrada", ". STATUS: $s")
        if has_values(model)
            @show objective_value(model)
            ans = objective_value(model)
            println("$n $m $ans Não")
            open("meus_resultados.dat", "a") do file
                write(file, "\n$n $m $ans Não")
            end
        else
            println("$n $m Sem valores")
            open("meus_resultados.dat", "a") do file
                write(file, "\n$n $m - Não")
            end
        end
    end
end