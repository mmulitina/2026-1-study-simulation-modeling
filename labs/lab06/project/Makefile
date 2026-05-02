.PHONY: all scripts tangle report clean

all: scripts tangle report

scripts:
	julia --project=. src/SIRPetri.jl

tangle:
	julia --project=. scripts/tangle.jl scripts/LIT_sirpetri_run.jl
	julia --project=. scripts/tangle.jl scripts/LIT_sirpetri_scan_parameters.jl
	julia --project=. scripts/tangle.jl scripts/LIT_sirpetri_animate.jl
	julia --project=. scripts/tangle.jl scripts/LIT_sirpetri_report.jl

report:
	quarto render report.qmd --to pdf

clean:
	rm -rf data/sims/* plots/* markdown/* notebooks/*
