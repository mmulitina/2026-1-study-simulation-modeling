using DrWatson
@quickactivate "project"
using DifferentialEquations, DataFrames, Plots, LaTeXStrings

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))

function sir_ode!(du, u, p, t)
    (S, I, R) = u
    (β, c, γ) = p
    N = S + I + R
    du[1] = -β * c * I / N * S
    du[2] = β * c * I / N * S - γ * I
    du[3] = γ * I
    nothing
end

p = [0.05, 10.0, 0.25]
prob_ode = ODEProblem(sir_ode!, [990.0, 10.0, 0.0], (0.0, 40.0), p)
sol_ode = solve(prob_ode, dt = 0.1)

df_ode = DataFrame(t=sol_ode.t, S=[u[1] for u in sol_ode.u], I=[u[2] for u in sol_ode.u], R=[u[3] for u in sol_ode.u])
plt1 = plot(df_ode.t, [df_ode.S df_ode.I df_ode.R], label=[L"S(t)" L"I(t)" L"R(t)"], title="SIR", lw=2)
savefig(plt1, plotsdir(script_name, "sir_main.png"))
println("✅ SIR базовый выполнен")
