using DrWatson
@quickactivate "project"  # Активация проекта DrWatson

using DifferentialEquations
using DataFrames
using Plots
using JLD2
using BenchmarkTools

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

function exponential_growth!(du, u, p, t)
    α = p.α  # **ИЗМЕНЕНИЕ:** Параметры теперь передаются как именованный кортеж
    du[1] = α * u[1]
end

base_params = Dict(
    :u0 => [1.0],           # начальная популяция
    :α => 0.3,              # скорость роста
    :tspan => (0.0, 10.0),  # интервал времени
    :solver => Tsit5(),     # метод решения
    :saveat => 0.1,         # шаг сохранения результатов
    :experiment_name => "base_experiment"
)

println("Базовые параметры эксперимента:")
for (key, value) in base_params
    println("  $key = $value")
end

function run_single_experiment(params::Dict)
    @unpack u0, α, tspan, solver, saveat = params
    prob = ODEProblem(exponential_growth!, u0, tspan, (α=α,))
    sol = solve(prob, solver; saveat=saveat)
    final_population = last(sol.u)[1] # Анализ результатов
    doubling_time = log(2) / α
    return Dict(
        "solution" => sol,
        "time_points" => sol.t,
        "population_values" => first.(sol.u),
        "final_population" => final_population,
        "doubling_time" => doubling_time,
        "parameters" => params  # Сохраняем исходные параметры
    ) # Используем строки как ключи для совместимости с DrWatson
end

data, path = produce_or_load(
    datadir(script_name, "single"),      # Папка для сохранения
    base_params,            # Параметры эксперимента
    run_single_experiment,  # Функция для выполнения
    prefix = "exp_growth",  # Префикс имени файла
    tag = false,            # Не добавлять git-тег
    verbose = true
)

println("\nРезультаты базового эксперимента:")
println("  Финальная популяция: ", data["final_population"])
println("  Время удвоения: ", round(data["doubling_time"]; digits=2))
println("  Файл результатов: ", path)

param_grid = Dict(
    :u0 => [[1.0]],           # фиксируем начальное условие
    :α => [0.1, 0.3, 0.5, 0.8, 1.0],  # исследуемые значения скорости роста
    :tspan => [(0.0, 10.0)],  # фиксируем интервал времени
    :solver => [Tsit5()],     # фиксируем метод решения
    :saveat => [0.1],         # фиксируем шаг сохранения
    :experiment_name => ["parametric_scan"]
)

all_params = dict_list(param_grid)

println("\n" * "="^60)
println("ПАРАМЕТРИЧЕСКОЕ СКАНИРОВАНИЕ")
println("Всего комбинаций параметров: ", length(all_params))
println("Исследуемые значения α: ", param_grid[:α])
println("="^60)

all_results = []
all_dfs = []

for (i, params) in enumerate(all_params)
    println("Прогресс: $i/$(length(all_params)) | α = $(params[:α])")

    data, path = produce_or_load(
        datadir(script_name, "parametric_scan"),  # Данные
        params,                      # Текущий набор параметров
        run_single_experiment,       # Функция для выполнения
        prefix = "scan",             # Префикс имени файла
        tag = false,
        verbose = false              # Не выводить подробности для каждого запуска
    ) # Автоматическое сохранение/загрузка каждого эксперимента

    result_summary = merge(
        params,
        Dict(
            :final_population => data["final_population"],
            :doubling_time => data["doubling_time"],
            :filepath => path  # Путь к сохраненным данным
        )
    ) # Сохраняем сводные результаты (используем символы для параметров, но данные из data - строки)

    push!(all_results, result_summary)

    df = DataFrame(
        t = data["time_points"],
        u = data["population_values"],
        α = fill(params[:α], length(data["time_points"]))
    ) # Сохраняем полные данные для визуализации
    push!(all_dfs, df)
end

results_df = DataFrame(all_results)
println("\nСводная таблица результатов:")
println(results_df[!, [:α, :final_population, :doubling_time]])

println("\n" * "="^60)
println("Бенчмаркинг для разных значений α")
println("="^60)

benchmark_results = []
for α_value in param_grid[:α]

    bench_params = Dict(
        :u0 => [1.0],
        :α => α_value,
        :tspan => (0.0, 10.0),
        :solver => Tsit5(),
        :saveat => 0.1
    ) # Подготавливаем параметры для бенчмарка

    function benchmark_run() # Функция для бенчмарка
        prob = ODEProblem(exponential_growth!,
                         bench_params[:u0],
                         bench_params[:tspan],
                         (α=bench_params[:α],))
        return solve(prob, bench_params[:solver];
                     saveat=bench_params[:saveat])
    end

    println("\nБенчмарк для α = $α_value:")
    b = @benchmark $benchmark_run() samples=100 evals=1 # Запуск бенчмарка
    push!(benchmark_results, (α=α_value, time=median(b).time/1e9))  # время в секундах

    println("  Среднее время: ", round(median(b).time/1e9; digits=4), " сек")
end

bench_df = DataFrame(benchmark_results)

println("\n" * "="^60)
println("ЛАБОРАТОРНАЯ РАБОТА ЗАВЕРШЕНА")
println("="^60)
println("\nРезультаты сохранены в:")
println("  • data/$(script_name)/single/              - базовый эксперимент")
println("  • data/$(script_name)/parametric_scan/     - параметрическое сканирование")
println("  • data/$(script_name)/all_results.jld2     - сводные данные")
println("  • plots/$(script_name)/                    - все графики")
println("  • data/$(script_name)/all_plots.jld2      - объекты графиков")
println("\nДля анализа результатов используйте:")
println("  using JLD2, DataFrames")
println("  @load \"data/$(script_name)/all_results.jld2\"")
println("  println(results_df)")
