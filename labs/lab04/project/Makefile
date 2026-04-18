.PHONY: all scripts tangle report clean

all: scripts tangle report

<<<<<<< HEAD


tangle:

	julia --project=. scripts/tangle.jl scripts/lit_sir_run_basic.jl
	julia --project=. scripts/tangle.jl scripts/lit_sir_migration_effect.jl
	julia --project=. scripts/tangle.jl scripts/lit_sir_optimize_parameters.jl
	julia --project=. scripts/tangle.jl scripts/lit_sir_visualize_dynamics.jl
=======
scripts:
	julia --project=. scripts/sir_ode.jl

tangle:
	julia --project=. scripts/tangle.jl scripts/sir_literate.jl
	julia --project=. scripts/tangle.jl scripts/lv_literate.jl
	julia --project=. scripts/tangle.jl scripts/sir_parametric.jl
>>>>>>> develop

report:
	quarto render report.qmd --to pdf

clean:
	rm -rf data/sims/* plots/* markdown/* notebooks/*
