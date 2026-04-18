.PHONY: all scripts tangle report clean

all: scripts tangle report

scripts:
	julia --project=. src/DiningPhilosophers.jl

tangle:
	julia --project=. scripts/tangle.jl scripts/LITdining_philosophers.jl
	julia --project=. scripts/tangle.jl scripts/LITdining_philosophers_animation.jl
	julia --project=. scripts/tangle.jl scripts/LITdining_philosophers_report.jl

report:
	quarto render report.qmd --to pdf

clean:
	rm -rf data/sims/* plots/* markdown/* notebooks/*
