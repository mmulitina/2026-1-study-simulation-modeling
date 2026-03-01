# # Модель Лотки-Вольтерры
# Уравнения:
# $$
# \begin{cases}
# \frac{dx}{dt} = \alpha x - \beta x y \\
# \frac{dy}{dt} = \delta x y - \gamma y
# \end{cases}
# $$

using DrWatson
@quickactivate "project"
using DifferentialEquations, DataFrames, Plots, LaTeXStrings

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))

function lotka_volterra!(du, u, p, t)
    x, y = u
    α, β, δ, γ = p
    du[1] = α*x - β*x*y
    du[2] = δ*x*y - γ*y
    nothing
end

prob_lv = ODEProblem(lotka_volterra!, [40.0, 9.0], (0.0, 200.0), [0.1, 0.02, 0.01, 0.3])
sol_lv = solve(prob_lv, Tsit5(), dt=0.1)

df_lv = DataFrame(t=sol_lv.t, prey=[u[1] for u in sol_lv.u], pred=[u[2] for u in sol_lv.u])

plt1 = plot(df_lv.t, [df_lv.prey df_lv.pred], label=[L"x" L"y"], title="Динамика", lw=2)
savefig(plt1, plotsdir(script_name, "lv_dyn.png"))

plt2 = plot(df_lv.prey, df_lv.pred, title="Фазовый портрет", xlabel="Жертвы", ylabel="Хищники", lw=2)
savefig(plt2, plotsdir(script_name, "lv_phase.png"))
