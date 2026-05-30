using ResumableFunctions, ConcurrentSim, Distributions, DataFrames, Random

# Вспомогательные функции для обновления массивов состояния
function increment!(a::Array{Int64})
    push!(a, a[length(a)] + 1)
end
function decrement!(a::Array{Int64})
    push!(a, a[length(a)] - 1)
end
function carryover!(a::Array{Int64})
    push!(a, a[length(a)])
end

# Структуры данных
mutable struct SIRPerson
    id::Int64
    status::Symbol  # :S, :I, :R, :E (для SEIR), :D (для демографии)
end

mutable struct SIRModel
    sim::ConcurrentSim.Simulation
    β::Float64
    c::Float64
    γ::Float64
    σ::Float64  # для SEIR (латентный период)
    μ::Float64  # для демографии (смертность)
    birth_rate::Float64  # для демографии (рождаемость)
    ta::Array{Float64}
    Sa::Array{Int64}
    Ia::Array{Int64}
    Ra::Array{Int64}
    Ea::Array{Int64}  # для SEIR
    allIndividuals::Array{SIRPerson}
    use_seir::Bool
    use_demography::Bool
end

# Функции обновления статистики при событиях
function infection_update!(sim::ConcurrentSim.Simulation, m::SIRModel)
    push!(m.ta, ConcurrentSim.now(sim))
    decrement!(m.Sa)
    increment!(m.Ia)
    carryover!(m.Ra)
    if m.use_seir
        carryover!(m.Ea)
    end
end

function recovery_update!(sim::ConcurrentSim.Simulation, m::SIRModel)
    push!(m.ta, ConcurrentSim.now(sim))
    carryover!(m.Sa)
    decrement!(m.Ia)
    increment!(m.Ra)
    if m.use_seir
        carryover!(m.Ea)
    end
end

function exposure_update!(sim::ConcurrentSim.Simulation, m::SIRModel)
    push!(m.ta, ConcurrentSim.now(sim))
    decrement!(m.Sa)
    carryover!(m.Ia)
    carryover!(m.Ra)
    if m.use_seir
        increment!(m.Ea)
    end
end

function latency_update!(sim::ConcurrentSim.Simulation, m::SIRModel)
    push!(m.ta, ConcurrentSim.now(sim))
    carryover!(m.Sa)
    increment!(m.Ia)
    carryover!(m.Ra)
    if m.use_seir
        decrement!(m.Ea)
    end
end

function death_update!(sim::ConcurrentSim.Simulation, m::SIRModel, status::Symbol)
    push!(m.ta, ConcurrentSim.now(sim))
    if status == :S
        decrement!(m.Sa)
    elseif status == :I
        decrement!(m.Ia)
    elseif status == :R
        decrement!(m.Ra)
    elseif status == :E && m.use_seir
        decrement!(m.Ea)
    end
    carryover!(m.Sa)
    carryover!(m.Ia)
    carryover!(m.Ra)
    if m.use_seir
        carryover!(m.Ea)
    end
end

function birth_update!(sim::ConcurrentSim.Simulation, m::SIRModel)
    push!(m.ta, ConcurrentSim.now(sim))
    increment!(m.Sa)
    carryover!(m.Ia)
    carryover!(m.Ra)
    if m.use_seir
        carryover!(m.Ea)
    end
end

# Основная логика жизни индивида
@resumable function live(env::ConcurrentSim.Simulation, individual::SIRPerson, m::SIRModel)
    # Демография: смертность
    if m.use_demography && m.μ > 0
        @yield timeout(env, rand(Exponential(1/m.μ)))
        death_update!(env, m, individual.status)
        return  # индивид умирает
    end
    
    while individual.status == :S
        @yield timeout(env, rand(Exponential(1/m.c)))
        alter = individual
        while alter == individual
            N = length(m.allIndividuals)
            index = rand(DiscreteUniform(1, N))
            alter = m.allIndividuals[index]
        end
        if alter.status == :I
            if rand(Uniform(0, 1)) < m.β
                if m.use_seir
                    individual.status = :E
                    exposure_update!(env, m)
                    # Латентный период
                    @yield timeout(env, rand(Exponential(1/m.σ)))
                    individual.status = :I
                    latency_update!(env, m)
                else
                    individual.status = :I
                    infection_update!(env, m)
                end
            end
        end
    end
    
    if individual.status == :I
        # Детерминированная или стохастическая длительность болезни
        if m.γ > 0
            @yield timeout(env, 1/m.γ)  # детерминированная версия
        else
            @yield timeout(env, rand(Exponential(1/abs(m.γ))))
        end
        individual.status = :R
        recovery_update!(env, m)
    end
end

# Процесс рождаемости
@resumable function birth_process(env::ConcurrentSim.Simulation, m::SIRModel)
    while true
        @yield timeout(env, rand(Exponential(1/m.birth_rate)))
        new_id = length(m.allIndividuals) + 1
        push!(m.allIndividuals, SIRPerson(new_id, :S))
        birth_update!(env, m)
    end
end

# Функции создания и запуска модели
function MakeSIRModel(u0, p; use_seir=false, use_demography=false)
    (S, I, R) = u0
    N = S + I + R
    if use_seir
        (β, c, γ, σ) = p
        μ = 0.0
        birth_rate = 0.0
    elseif use_demography
        (β, c, γ, μ, birth_rate) = p
        σ = 0.0
    else
        (β, c, γ) = p
        σ = 0.0
        μ = 0.0
        birth_rate = 0.0
    end
    
    sim = ConcurrentSim.Simulation()
    allIndividuals = SIRPerson[]
    for i = 1:S
        push!(allIndividuals, SIRPerson(i, :S))
    end
    for i = (S+1):(S+I)
        push!(allIndividuals, SIRPerson(i, :I))
    end
    for i = (S+I+1):N
        push!(allIndividuals, SIRPerson(i, :R))
    end
    
    ta = Float64[0.0]
    Sa = Int64[S]
    Ia = Int64[I]
    Ra = Int64[R]
    Ea = Int64[0]
    
    SIRModel(sim, β, c, γ, σ, μ, birth_rate, ta, Sa, Ia, Ra, Ea, allIndividuals, use_seir, use_demography)
end

function activate(m::SIRModel)
    [@process live(m.sim, individual, m) for individual in m.allIndividuals]
    if m.use_demography && m.birth_rate > 0
        @process birth_process(m.sim, m)
    end
end

function sir_run(m::SIRModel, tf::Float64)
    ConcurrentSim.run(m.sim, tf)
end

function out(m::SIRModel)
    result = DataFrame()
    result[!, :t] = m.ta
    result[!, :S] = m.Sa
    result[!, :I] = m.Ia
    result[!, :R] = m.Ra
    if m.use_seir
        result[!, :E] = m.Ea
    end
    return result
end

# Вакцинация
@resumable function vaccinate(env::ConcurrentSim.Simulation, m::SIRModel, time::Float64, fraction::Float64)
    @yield timeout(env, time)
    N = length(m.allIndividuals)
    susceptible_indices = findall(ind -> ind.status == :S, m.allIndividuals)
    n_to_vaccinate = min(round(Int, length(susceptible_indices) * fraction), length(susceptible_indices))
    
    if n_to_vaccinate > 0
        to_vaccinate = sample(susceptible_indices, n_to_vaccinate, replace=false)
        for idx in to_vaccinate
            m.allIndividuals[idx].status = :R
        end
        # Обновляем статистику
        push!(m.ta, ConcurrentSim.now(env))
        new_S = m.Sa[end] - n_to_vaccinate
        push!(m.Sa, new_S)
        new_R = m.Ra[end] + n_to_vaccinate
        push!(m.Ra, new_R)
        carryover!(m.Ia)
    end
end

function add_vaccination(m::SIRModel, time::Float64, fraction::Float64)
    @process vaccinate(m.sim, m, time, fraction)
end
