#!/bin/bash 

# image path is specified in the kpi-2.json file
python      ../mexdex/writeDesignExplorerCsv.py \
    --casesList_paramValueDelimiter  ":"   \
	../example_inputs/pyCone/cases.list ../example_inputs/pyCone/kpi-2.json .  ../example_outputs/pyCone/output.csv 
