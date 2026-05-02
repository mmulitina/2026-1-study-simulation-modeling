# # Анимация детерминированной динамики SIR

using DrWatson
@quickactivate "project"

# Загрузка модуля SIRPetri и утилит
include(srcdir("SIRPetri.jl"))
using .SIRPetri: build_sir_network, simulate_deterministic
using DataFrames, CSV, Plots

# Задание параметров симуляции
β = 0.3
γ = 0.1
tmax = 100.0

# Детерминированная симуляция
net, u0, states = build_sir_network(β, γ)

df = simulate_deterministic(net, u0, (0.0, tmax), saveat = 0.2, rates = [β, γ])

# Создание анимации


println("Анимация сохранена в plots/sir_animation.gif")
