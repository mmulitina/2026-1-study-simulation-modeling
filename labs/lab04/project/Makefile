.PHONY: all scripts tangle report clean

all: scripts tangle report



tangle:

	julia --project=. scripts/tangle.jl scripts/lit_sir_run_basic.jl
	julia --project=. scripts/tangle.jl scripts/lit_sir_migration_effect.jl
	julia --project=. scripts/tangle.jl scripts/lit_sir_optimize_parameters.jl
	julia --project=. scripts/tangle.jl scripts/lit_sir_visualize_dynamics.jl

report:
	quarto render report.qmd --to pdf

clean:
	rm -rf data/sims/* plots/* markdown/* notebooks/*
