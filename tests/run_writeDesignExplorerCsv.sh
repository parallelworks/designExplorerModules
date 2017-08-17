#!/bin/bash 


python      ../mexdex/writeDesignExplorerCsv.py \
    --imagesDirectory "../example_inputs/pyCone/results/case_" \
	--includeOutputParamsFile ../example_inputs/pyCone/DEoutputParams.txt \
	../example_inputs/pyCone/cases.list ../example_inputs/pyCone/kpi.json .  ../example_outputs/output.csv 
