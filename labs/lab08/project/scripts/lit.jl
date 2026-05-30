using DrWatson
# Активируем проектное окружение (поиск по названию или маркерным файлам)
@quickactivate "project"

# Подключаем кастомный модуль с логикой SIR-модели из папки src/
include(srcdir("sir_model.jl"))

# Загружаем необходимые библиотеки для симуляции, анализа данных и визуализации
using Random
using StatsPlots     # Для построения графиков на основе DataFrame
using BenchmarkTools # Для точной оценки производительности кода
using CSV            # Для экспорта результатов в табличный формат
using Dates          # Для работы с датами и временем

# --- НАСТРОЙКА ПЛОТТИНГА ДЛЯ PNG/SVG ---
gr()  # Используем GR backend (поддерживает PNG/SVG)
ENV["GKSwstype"] = "nul"  # Отключаем интерактивный вывод

# --- Настройка глобальных параметров симуляции ---
const T_MAX = 40.0   # Максимальное время моделирования (дней/недель)

# Начальное состояние популяции: [S (Восприимчивые), I (Инфицированные), R (Переболевшие)]
const U0_BASE = [990, 10, 0] 

# Параметры модели: [β (инфекционность), c (количество контактов), γ (скорость выздоровления)]
const P_BASE = [0.05, 10.0, 0.25] 

# Фиксируем seed для воспроизводимости стохастических процессов
Random.seed!(1234)

# ==============================================================================
# БАЗОВАЯ СТОХАСТИЧЕСКАЯ МОДЕЛЬ SIR
# ==============================================================================
println("=== ЗАПУСК БАЗОВОЙ МОДЕЛИ SIR ===")

# Инициализируем и запускаем базовую дискретно-событийную (DES) модель
des_model = MakeSIRModel(U0_BASE, P_BASE)
activate(des_model)
sir_run(des_model, T_MAX)

# Извлекаем полученные временные ряды (DataFrame)
data_des = out(des_model)

# --- Визуализация динамики базовой модели ---
if nrow(data_des) > 0
    p1 = @df data_des plot(
        :t,
        [:S :I :R],
        labels = ["S" "I" "R"],
        xlab = "Время",
        ylab = "Численность",
        title = "Дискретно-событийная SIR модель",
        lw = 2
    )

    savefig(p1, plotsdir("sir_des.png"))
    println("График сохранен в: $(plotsdir("sir_des.png"))")
end

# --- Экспорт результатов в CSV ---
filename = "sir_res.csv"
CSV.write(datadir("sims", filename), data_des)
println("Результаты сохранены в: $(datadir("sims", filename))")

# ==============================================================================
# ДОПОЛНИТЕЛЬНОЕ ЗАДАНИЕ 8.5.1: АНАЛИЗ ЧУВСТВИТЕЛЬНОСТИ К ПАРАМЕТРАМ
# ==============================================================================
println("\n=== ДОПОЛНИТЕЛЬНОЕ ЗАДАНИЕ 8.5.1: АНАЛИЗ ЧУВСТВИТЕЛЬНОСТИ К ПАРАМЕТРАМ ===")

betas = [0.03, 0.05, 0.07]
cs = [5.0, 10.0, 15.0]
gammas = [0.2, 0.25, 0.33]

# Вспомогательная локальная функция для исключения дублирования кода при анализе
function run_sensitivity_step(p_param, label, value)
    m = MakeSIRModel(U0_BASE, p_param)
    activate(m)
    sir_run(m, T_MAX)
    data = out(m)
  
    peak_I = maximum(data.I)
    peak_time = data.t[argmax(data.I)]
    final_R = data.R[end]
    
    println("  $label=$value: пик I=$peak_I, время пика=$peak_time, итоговая R=$final_R")
end

println("Варьирование β (вероятность передачи):")
for β in betas
    run_sensitivity_step([β, 10.0, 0.25], "β", β)
end

println("\nВарьирование c (интенсивность контактов):")
for c in cs
    run_sensitivity_step([0.05, c, 0.25], "c", c)
end

println("\nВарьирование γ (скорость выздоровления):")
for γ in gammas
    run_sensitivity_step([0.05, 10.0, γ], "γ", γ)
end

# ==============================================================================
# ДОПОЛНИТЕЛЬНОЕ ЗАДАНИЕ 8.5.2: ДЕТЕРМИНИРОВАННАЯ ДЛИТЕЛЬНОСТЬ БОЛЕЗНИ
# ==============================================================================
println("\n=== ДОПОЛНИТЕЛЬНОЕ ЗАДАНИЕ 8.5.2: ДЕТЕРМИНИРОВАННАЯ ДЛИТЕЛЬНОСТЬ БОЛЕЗНИ ===")

Random.seed!(1234) # Сброс генератора для чистоты сравнения

# Инициализируем детерминированную версию (фиксированное время выздоровления)
det_model = MakeSIRModel(U0_BASE, P_BASE)
activate(det_model)
sir_run(det_model, T_MAX)
data_det = out(det_model)

# --- Построение сравнительного графика ---
if nrow(data_des) > 0 && nrow(data_det) > 0
    p2 = plot(data_des.t, data_des.I, label="Стохастическая", xlab="Время", ylab="Инфицированные", title="Сравнение стохастической и детерминированной длительности болезни", lw=2)
    plot!(p2, data_det.t, data_det.I, label="Детерминированная", lw=2, linestyle=:dash)
    savefig(p2, plotsdir("sir_comparison.png"))
    println("Сравнительный график сохранен в: $(plotsdir("sir_comparison.png"))")
end

# ==============================================================================
# ДОПОЛНИТЕЛЬНОЕ ЗАДАНИЕ 8.5.3: ОЦЕНКА ПРОИЗВОДИТЕЛЬНОСТИ
# ==============================================================================
println("\n=== ДОПОЛНИТЕЛЬНОЕ ЗАДАНИЕ 8.5.3: ОЦЕНКА ПРОИЗВОДИТЕЛЬНОСТИ ===")

# Масштабируем популяцию до 10 000 индивидов
u0_large = [9990, 10, 0]
large_model = MakeSIRModel(u0_large, P_BASE)
activate(large_model)

println("Бенчмарк для популяции 10000 индивидов (ограничено до 3 замеров):")
# Интерполируем внешние переменные через $ для корректного замера макросом @benchmark
benchmark_result = @benchmark sir_run($large_model, $T_MAX) samples=3
println(benchmark_result)

# ==============================================================================
# ДОПОЛНИТЕЛЬНОЕ ЗАДАНИЕ 8.5.5: ДОБАВЛЕНИЕ ДЕМОГРАФИЧЕСКИХ СОБЫТИЙ
# ==============================================================================
println("\n=== ДОПОЛНИТЕЛЬНОЕ ЗАДАНИЕ 8.5.5: ДОБАВЛЕНИЕ ДЕМОГРАФИЧЕСКИХ СОБЫТИЙ ===")

# Набор параметров с учетом рождаемости/смертности: [β, c, γ, μ, birth_rate]
p_demo = [0.05, 10.0, 0.25, 0.05, 0.05]

try
    demo_model = MakeSIRModel(U0_BASE, p_demo, use_demography=true)
    activate(demo_model)
    sir_run(demo_model, T_MAX)
    data_demo = out(demo_model)
    
    if nrow(data_demo) > 0
        p3 = @df data_demo plot(
            :t,
            [:S :I :R],
            labels = ["S" "I" "R"],
            xlab = "Время",
            ylab = "Численность",
            title = "SIR модель с демографическими событиями",
            lw = 2
        )
        savefig(p3, plotsdir("sir_demography.png"))
        println("График с демографией сохранен в: $(plotsdir("sir_demography.png"))")
    else
        println("Нет данных для демографической модели")
    end
catch e
    println("Ошибка при запуске демографической модели: $e")
end

# ==============================================================================
# ДОПОЛНИТЕЛЬНОЕ ЗАДАНИЕ 8.5.6: ВАКЦИНАЦИЯ
# ==============================================================================
println("\n=== ДОПОЛНИТЕЛЬНОЕ ЗАДАНИЕ 8.5.6: ВАКЦИНАЦИЯ ===")

try
    vax_model = MakeSIRModel(U0_BASE, P_BASE)
    activate(vax_model)

    if isdefined(Main, :add_vaccination)
        add_vaccination(vax_model, 5.0, 0.5)
    else
        println("Предупреждение: Функция `add_vaccination` отсутствует в контексте Main.")
    end
    
    sir_run(vax_model, T_MAX)
    data_vax = out(vax_model)
    
    if nrow(data_vax) > 0
        p4 = @df data_vax plot(
            :t,
            [:S :I :R],
            labels = ["S" "I" "R"],
            xlab = "Время",
            ylab = "Численность",
            title = "SIR модель с вакцинацией",
            lw = 2
        )
        savefig(p4, plotsdir("sir_vaccination.png"))
        println("График с вакцинацией сохранен в: $(plotsdir("sir_vaccination.png"))")
    else
        println("Нет данных для модели с вакцинацией")
    end
catch e
    println("Ошибка при запуске модели с вакцинацией: $e")
end

# ==============================================================================
# ДОПОЛНИТЕЛЬНОЕ ЗАДАНИЕ 8.5.7: МОДЕЛЬ SEIR
# ==============================================================================
println("\n=== ДОПОЛНИТЕЛЬНОЕ ЗАДАНИЕ 8.5.7: МОДЕЛЬ SEIR ===")

try
    u0_seir = [990, 10, 0]  
    p_seir = [0.05, 10.0, 0.25, 0.1]  
    
    seir_model = MakeSIRModel(u0_seir, p_seir, use_seir=true)
    activate(seir_model)
    sir_run(seir_model, T_MAX)
    data_seir = out(seir_model)
    
    if nrow(data_seir) > 0 && hasproperty(data_seir, :E)
        p5 = @df data_seir plot(
            :t,
            [:S :I :R :E],
            labels = ["S" "I" "R" "E (Латентные)"],
            xlab = "Время",
            ylab = "Численность",
            title = "SEIR модель (с латентным периодом)",
            lw = 2
        )
        savefig(p5, plotsdir("sir_seir.png"))
        println("График SEIR модели сохранен в: $(plotsdir("sir_seir.png"))")
    else
        println("Нет данных для SEIR модели или колонка :E отсутствует")
    end
catch e
    println("Ошибка при запуске SEIR модели: $e")
end

println("\n=== ВСЕ ЗАДАНИЯ ВЫПОЛНЕНЫ ===")
