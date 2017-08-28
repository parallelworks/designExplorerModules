#!/bin/bash 


python      ../mexdex/writeDesignExplorerCsv.py \
	--imagesDirectory "../example_inputs/pyCone/results/case_{:d}" \
	../example_inputs/pyCone/cases.list ../example_inputs/pyCone/kpi.json .  ../example_outputs/pyCone/output.csv 
