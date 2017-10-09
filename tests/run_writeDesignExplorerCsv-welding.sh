#!/bin/bash

outcsv=../example_outputs/welding/DE.csv   						
outhtml=../example_outputs/welding/DE.html 							
rpath=example_outputs/welding										
caseslistFile=../example_inputs/welding/outputs/cases.list 				
metrics_json=../example_inputs/welding/inputs/beadOnPlateKPI_short.json  
pngOutDirRoot=""  #../example_inputs/welding/outputs/png/ 						
caseDirRoot=../example_inputs/welding/outputs/case						

colorby="sliceNT_ave"

if [[ "$rpath" == *"/efs/job_working_directory"* ]];then
	basedir="$(echo /download$rpath | sed "s|/efs/job_working_directory||g" )"
	DEbase="/preview"  
else
	basedir="$(echo /download$rpath | sed "s|/export/galaxy-central/database/job_working_directory||g" )"
	DEbase="/preview"  
fi 

# Works with both python2 and python3 
# echo python      ../mexdex/writeDesignExplorerCsv.py \
# 	--casesList_paramValueDelimiter "=" \
# 	--imagesDirectory $pngOutDirRoot{:d} \
# 	--MEXCsvPathTemplate  $caseDirRoot{:d}/metrics.csv \
# 	--excludeParams Width1,Width2,EllipseW,EllipseH,Temp0,weld_x0,weld_y0,weld_z0,weld_vx,weld_vy,weld_vz,weld_a,weld_b,weld_c,weld_Q,sim_totalTime,sim_dt,highResWidth,meshScale,highResMeshScale \
# 	$caseslistFile $metrics_json $basedir $outcsv

basedir="."

python      ../mexdex/writeDesignExplorerCsv.py \
	--casesList_paramValueDelimiter "=" \
	--MEXCsvPathTemplate  $caseDirRoot{:d}/metrics.csv \
	--excludeParams Width1,Width2,EllipseW,EllipseH,Temp0,weld_x0,weld_y0,weld_z0,weld_vx,weld_vy,weld_vz,weld_a,weld_b,weld_c,weld_Q,sim_totalTime,sim_dt,highResWidth,meshScale,highResMeshScale \
	$caseslistFile $metrics_json $basedir $outcsv


baseurl="$DEbase/DesignExplorer/index.html?datafile=$basedir/$outcsv&colorby=$colorby"
echo '<html style="overflow-y:hidden;background:white"><a style="font-family:sans-serif;z-index:1000;position:absolute;top:15px;right:0px;margin-right:20px;font-style:italic;font-size:10px" href="'$baseurl'" target="_blank">Open in New Window</a><iframe width="100%" height="100%" src="'$baseurl'" frameborder="0"></iframe></html>' > $outhtml


