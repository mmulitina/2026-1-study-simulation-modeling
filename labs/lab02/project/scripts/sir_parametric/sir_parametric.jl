using DrWatson
@quickactivate "project"
using DifferentialEquations, DataFrames, Plots

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))

function sir_ode!(du, u, p, t)
    S, I, R = u
    β, c, γ = p
    N = S + I + R
    du[1] = -β * c * I / N * S
    du[2] = β * c * I / N * S - γ * I
    du[3] = γ * I
    nothing
end

beta_values = [0.02, 0.05, 0.08, 0.12]
plt = plot(title="Влияние β на I(t)", xlabel="Время", ylabel="I(t)")

for β in beta_values
    prob = ODEProblem(sir_ode!, [990.0, 10.0, 0.0], (0.0, 40.0), [β, 10.0, 0.25])
    sol = solve(prob, Tsit5())
    plot!(plt, sol.t, [u[2] for u in sol.u], label="β = $β", lw=2)
end

savefig(plt, plotsdir(script_name, "beta_sens.png"))
