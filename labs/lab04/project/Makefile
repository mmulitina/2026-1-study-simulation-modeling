.PHONY: all scripts tangle report clean

all: scripts tangle report

scripts:
	julia --project=. scripts/sir_ode.jl

tangle:
	julia --project=. scripts/tangle.jl scripts/sir_literate.jl
	julia --project=. scripts/tangle.jl scripts/lv_literate.jl
	julia --project=. scripts/tangle.jl scripts/sir_parametric.jl

report:
	quarto render report.qmd --to pdf

clean:
	rm -rf data/sims/* plots/* markdown/* notebooks/*
