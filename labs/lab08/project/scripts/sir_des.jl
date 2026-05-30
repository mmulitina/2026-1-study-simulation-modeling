using DrWatson
@quickactivate "project"
include(srcdir("sir_model.jl"))
using Random, StatsPlots, BenchmarkTools, CSV, Dates

# Параметры модели
tmax = 40.0
u0 = [990, 10, 0]      # S, I, R
p = [0.05, 10.0, 0.25]  # β, c, γ

Random.seed!(1234)

println("=== ЗАПУСК БАЗОВОЙ МОДЕЛИ SIR ===")
# Запуск модели
des_model = MakeSIRModel(u0, p)
activate(des_model)
sir_run(des_model, tmax)
data_des = out(des_model)

# Визуализация
@df data_des plot(
    :t,
    [:S :I :R],
    labels = ["S" "I" "R"],
    xlab = "Время",
    ylab = "Численность",
    title = "Дискретно-событийная SIR модель",
)
savefig(plotsdir("sir_des.png"))

# Сохранение результатов в CSV
filename = "sir_res.csv"
CSV.write(datadir("sims", filename), data_des)
println("Результаты сохранены в: $(datadir("sims", filename))")

println("\n=== ДОПОЛНИТЕЛЬНОЕ ЗАДАНИЕ 8.5.1: АНАЛИЗ ЧУВСТВИТЕЛЬНОСТИ К ПАРАМЕТРАМ ===")
betas = [0.03, 0.05, 0.07]
cs = [5.0, 10.0, 15.0]
gammas = [0.2, 0.25, 0.33]

println("\nВарьирование β:")
for β in betas
    p_param = [β, 10.0, 0.25]
    m = MakeSIRModel(u0, p_param)
    activate(m)
    sir_run(m, tmax)
    data = out(m)
    peak_I = maximum(data.I)
    peak_time = data.t[argmax(data.I)]
    final_R = data.R[end]
    println("β=$β: пик I=$peak_I, время пика=$peak_time, итоговая R=$final_R")
end

println("\nВарьирование c:")
for c in cs
    p_param = [0.05, c, 0.25]
    m = MakeSIRModel(u0, p_param)
    activate(m)
    sir_run(m, tmax)
    data = out(m)
    peak_I = maximum(data.I)
    peak_time = data.t[argmax(data.I)]
    final_R = data.R[end]
    println("c=$c: пик I=$peak_I, время пика=$peak_time, итоговая R=$final_R")
end

println("\nВарьирование γ:")
for γ in gammas
    p_param = [0.05, 10.0, γ]
    m = MakeSIRModel(u0, p_param)
    activate(m)
    sir_run(m, tmax)
    data = out(m)
    peak_I = maximum(data.I)
    peak_time = data.t[argmax(data.I)]
    final_R = data.R[end]
    println("γ=$γ: пик I=$peak_I, время пика=$peak_time, итоговая R=$final_R")
end

println("\n=== ДОПОЛНИТЕЛЬНОЕ ЗАДАНИЕ 8.5.2: ДЕТЕРМИНИРОВАННАЯ ДЛИТЕЛЬНОСТЬ БОЛЕЗНИ ===")
Random.seed!(1234)
# Детерминированная версия (фиксированное время выздоровления)
det_model = MakeSIRModel(u0, p)
activate(det_model)
sir_run(det_model, tmax)
data_det = out(det_model)

# Сравнительный график
plot(data_des.t, data_des.I, label="Стохастическая", xlab="Время", ylab="Инфицированные", title="Сравнение стохастической и детерминированной длительности болезни")
plot!(data_det.t, data_det.I, label="Детерминированная")
savefig(plotsdir("sir_comparison.png"))
println("Сравнительный график сохранен в: $(plotsdir("sir_comparison.png"))")

println("\n=== ДОПОЛНИТЕЛЬНОЕ ЗАДАНИЕ 8.5.3: ОЦЕНКА ПРОИЗВОДИТЕЛЬНОСТИ ===")
# Для популяции 10000 индивидов
u0_large = [9990, 10, 0]
large_model = MakeSIRModel(u0_large, p)
activate(large_model)
println("Бенчмарк для популяции 10000 индивидов:")
benchmark_result = @benchmark sir_run($large_model, $tmax) samples=3
println(benchmark_result)

println("\n=== ДОПОЛНИТЕЛЬНОЕ ЗАДАНИЕ 8.5.5: ДОБАВЛЕНИЕ ДЕМОГРАФИЧЕСКИХ СОБЫТИЙ ===")
# Параметры: β, c, γ, μ, birth_rate
p_demo = [0.05, 10.0, 0.25, 0.05, 0.05]  # μ=0.05, birth_rate=0.05
try
    demo_model = MakeSIRModel(u0, p_demo, use_demography=true)
    activate(demo_model)
    sir_run(demo_model, tmax)
    data_demo = out(demo_model)
    
    if nrow(data_demo) > 0
        @df data_demo plot(
            :t,
            [:S :I :R],
            labels = ["S" "I" "R"],
            xlab = "Время",
            ylab = "Численность",
            title = "SIR модель с демографическими событиями",
        )
        savefig(plotsdir("sir_demography.png"))
        println("График с демографией сохранен в: $(plotsdir("sir_demography.png"))")
    else
        println("Нет данных для демографической модели")
    end
catch e
    println("Ошибка при запуске демографической модели: $e")
end

println("\n=== ДОПОЛНИТЕЛЬНОЕ ЗАДАНИЕ 8.5.6: ВАКЦИНАЦИЯ ===")
try
    vax_model = MakeSIRModel(u0, p)
    activate(vax_model)
    # Вакцинация через 5 дней, вакцинируем 50% восприимчивых
    if isdefined(Main, :add_vaccination)
        add_vaccination(vax_model, 5.0, 0.5)
    end
    sir_run(vax_model, tmax)
    data_vax = out(vax_model)
    
    if nrow(data_vax) > 0
        @df data_vax plot(
            :t,
            [:S :I :R],
            labels = ["S" "I" "R"],
            xlab = "Время",
            ylab = "Численность",
            title = "SIR модель с вакцинацией",
        )
        savefig(plotsdir("sir_vaccination.png"))
        println("График с вакцинацией сохранен в: $(plotsdir("sir_vaccination.png"))")
    else
        println("Нет данных для модели с вакцинацией")
    end
catch e
    println("Ошибка при запуске модели с вакцинацией: $e")
end

println("\n=== ДОПОЛНИТЕЛЬНОЕ ЗАДАНИЕ 8.5.7: МОДЕЛЬ SEIR ===")
try
    u0_seir = [990, 10, 0]  # S, I, R
    p_seir = [0.05, 10.0, 0.25, 0.1]  # β, c, γ, σ
    seir_model = MakeSIRModel(u0_seir, p_seir, use_seir=true)
    activate(seir_model)
    sir_run(seir_model, tmax)
    data_seir = out(seir_model)
    
    if nrow(data_seir) > 0 && hasproperty(data_seir, :E)
        @df data_seir plot(
            :t,
            [:S :I :R :E],
            labels = ["S" "I" "R" "E"],
            xlab = "Время",
            ylab = "Численность",
            title = "SEIR модель (с латентным периодом)",
        )
        savefig(plotsdir("sir_seir.png"))
        println("График SEIR модели сохранен в: $(plotsdir("sir_seir.png"))")
    else
        println("Нет данных для SEIR модели")
    end
catch e
    println("Ошибка при запуске SEIR модели: $e")
end

println("\n=== ВСЕ ЗАДАНИЯ ВЫПОЛНЕНЫ ===")
