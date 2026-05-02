# Changelog

All notable changes to this project will be documented in this file.

## [6.0.0] - 2026-05-03

### Added
- SIR Petri net module (`src/SIRPetri.jl`) with deterministic and stochastic simulation
- Base simulation script (`scripts/sirpetri_run.jl`)
- Parameter scanning for infection rate β (`scripts/sirpetri_scan_parameters.jl`)
- Animation script (`scripts/sirpetri_animate.jl`)
- Report script (`scripts/sirpetri_report.jl`)
- Complete lab report in Quarto (`Л06_Черная_отчет.qmd`)
- Presentation in Quarto (`Л06_Черная_презентация.qmd`)
- 23 screenshots (1-21, comparison, sensitivity)

### Fixed
- GKS graphics issue on headless systems (added `ENV["GKSwstype"] = "nul"`)
- Missing `using DataFrames` import in animation script

### Dependencies
- AlgebraicPetri.jl v0.10.0
- Catlab.jl v0.17.5
- DrWatson.jl
- OrdinaryDiffEq.jl
- Plots.jl
- DataFrames.jl
- CSV.jl
