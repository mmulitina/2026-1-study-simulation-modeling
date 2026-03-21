.PHONY: all scripts tangle report clean

all: scripts tangle report



tangle:
	julia --project=. scripts/tangle.jl scripts/lit_daisyworld.jl
	julia --project=. scripts/tangle.jl scripts/lit_daisyworld-count.jl
	julia --project=. scripts/tangle.jl scripts/lit_daisyworld-count__param.jl
	julia --project=. scripts/tangle.jl scripts/lit_daisyworld-luminosity.jl
	julia --project=. scripts/tangle.jl scripts/lit_daisyworld-luminosity__param.jl
	julia --project=. scripts/tangle.jl scripts/lit_daisyworld__param.jl

report:
	quarto render report.qmd --to pdf

clean:
	rm -rf data/sims/* plots/* markdown/* notebooks/*
