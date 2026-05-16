.PHONY: all scripts tangle report clean

all: tangle report

tangle:
	julia --project=. scripts/tangle.jl scripts/lit_mmc.jl
	julia --project=. scripts/tangle.jl scripts/lit_ross.jl

report:
	quarto render report.qmd --to pdf

clean:
	rm -rf data/sims/* plots/* markdown/* notebooks/*
