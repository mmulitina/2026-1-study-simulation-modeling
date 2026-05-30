.PHONY: all scripts tangle report clean

all: scripts tangle report


tangle:
	julia --project=. scripts/tangle.jl scripts/01_exponential_growth.jl
	julia --project=. scripts/tangle.jl scripts/02_exponential_growth.jl
	

report:
	quarto render report.qmd --to pdf

clean:
	rm -rf data/sims/* plots/* markdown/* notebooks/*
