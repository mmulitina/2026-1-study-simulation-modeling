using DrWatson
@quickactivate "project"

include(srcdir("SIRPetri.jl"))
using .SIRPetri: build_sir_network, simulate_deterministic
using DataFrames, CSV, Plots

β = 0.3
γ = 0.1
tmax = 100.0

net, u0, states = build_sir_network(β, γ)

df = simulate_deterministic(net, u0, (0.0, tmax), saveat = 0.2, rates = [β, γ])

println("Анимация сохранена в plots/sir_animation.gif")
