#!/bin/bash 

# image path is specified as an input to the writeDesignExplorerCsv.py file:
python      ../mexdex/writeDesignExplorerCsv.py \
	--imagesDirectory "../example_inputs/pyCone/results/case_{:d}" \
    --casesList_paramValueDelimiter  ":"   \
	../example_inputs/pyCone/cases.list ../example_inputs/pyCone/kpi.json .  ../example_outputs/pyCone/output.csv 
