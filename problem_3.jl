include("./file_reader.jl")
using .file_reader
using JuMP
using GLPK
using Graphs

graph = file_reader.graphReader("instancias/instance_12_17.dat")
n = nv(graph) # total de vértices

model = Model(GLPK.Optimizer)

# 5 min de limite de tempo
set_time_limit_sec(model, 300.0)

# Definiçao das variaveis
@variable(model, x[1:n], Bin)
@variable(model, y[1:n, 1:n, 1:n], Bin)
@variable(model, b[1:n, 1:n], Bin)

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
    @show value.(x)
else
    s = termination_status(model)
    println("Infactível ou ilimitado", ". STATUS: $s")
end
