import "stdlib.v2";

type file;

# ------ INPUT / OUTPUT DEFINITIONS -------#

string sweepParamsFileName  = arg("sweepParamFile", "sweepParams_fast.run");

file fsweepParams		    <strcat("inputs/",sweepParamsFileName)>;

file outhtml <arg("html","DE.html")>;
file outcsv <arg("csv","DE.csv")>;


# directory definitions
string outDir               = "outputs/";
string errorsDir            = strcat(outDir, "errorFiles/");
string logsDir              = strcat(outDir, "logFiles/");
string salPortsDir          = strcat(logsDir, "salPortNums/");
string simFilesDir          = strcat(outDir, "simParamFiles/");
#string meshFilesDir         = strcat(outDir, "meshFiles/case"); 
string meshFilesDir         = strcat(outDir, "case"); 
string pngOutDirRoot        = strcat(outDir,"png/");
string caseDirRoot          = strcat(outDir, "case"); 

string runPath = getEnv("PWD");

# Script files and utilities
file meshScript             <"utils/beadOnPlate_inputFile.py">;
file preFbdFile             <"utils/bead_pre.fbd">;
file getCcxInpScript        <"utils/writeCCXinpFile_beadOnPlate.py">;
file writeFortranFileScript <"utils/writeDFluxFile.py">;
file materialLibFile        <"inputs/materialLib.mat">;  # Also need to change the ccx input file changing the name
file metrics2extract        <"inputs/beadOnPlateKPI_short.json">;
file outputsList4DE         <"DEoutputParams.txt">;

file utils[] 		        <filesys_mapper;location="utils", pattern="?*.*">;
file mexdex[] 		        <filesys_mapper;location="mexdex", pattern="?*.*">;

# ------- Funciton definitions--------------#

(string nameNoSuffix) trimSuffix (string nameWithSuffix){
   int suffixStartLoc = lastIndexOf(nameWithSuffix, ".", -1);
   nameNoSuffix = substring(nameWithSuffix, 0, suffixStartLoc); 
}

# ------ APP DEFINITIONS --------------------#

app (file cases, file[] simFileParams) writeCaseParamFiles (file sweepParams, string simFilesDir, file[] mexdex, file[] utils) {
    python2 "mexdex/prepinputs.py" "--SR_valueDelimiter" " " "--SR_paramsDelimiter" "\n" "--noParamTag" "--CL_paramValueDelimiter" "="  filename(sweepParams) filename(cases);
	python "utils/writeSimParamFiles.py" filename(cases) simFilesDir "caseParamFile";
}

app (file fmesh, file ferr, file fout) makeMesh (file meshScript, int caseindex, file utils[], 
                                                               file fsimParams, file preFbdFile) {
    bashSalome "utils/runSalome.sh" caseindex  filename(meshScript) filename(fsimParams)
         filename(fmesh) filename(fout) filename(ferr);
    bashCGX "utils/runUnicalCgx.sh" caseindex filename(fmesh) filename(preFbdFile) filename(fout) filename(ferr);
}

app (file fccxInp) getCcxInp (file getCcxInpScript, file fsimParams, file utils[]){
	python filename(getCcxInpScript) filename(fsimParams) filename(fccxInp);
}

app (file ccxBin, file dfluxfile) compileCcx (file writeFortranFileScript, file fsimParams, string caseDir, file utils[]){
    bash "utils/compileCcx3.sh" filename(writeFortranFileScript) filename(fsimParams) caseDir;
}

app (file MetricsOutput, file[] fpngs, file fOut, file ferr, file fsol) 
                                            runSimExtractMetrics (file ccxBin, file fmsh4ccx,
                                                                  file fInp, file matLibFile, file metrics2extract,
                                                                  string extractOutDir, file utils[], file mexdex[]){
    bashRunSim "utils/runSim.sh" filename(ccxBin)  filename(fInp) filename(matLibFile) 
                stderr=filename(ferr) stdout=filename(fOut);
    bashPVExtract  "mexdex/PVExtract.sh" filename(fInp) filename(metrics2extract) extractOutDir
         filename(MetricsOutput) stderr=filename(ferr) stdout=filename(fOut);
}

app (file outcsv, file outhtml, file so, file se) designExplorer (string runPath, file caselist, file metrics2extract, string pngOutDirRoot, string caseDirRoot, file[] MetricsFiles, file outputsList4DE, file mexdex[])
{
  bash "mexdex/addDesignExplorer.sh" filename(outcsv) filename(outhtml) runPath  filename(caselist) filename(metrics2extract) pngOutDirRoot caseDirRoot filename(outputsList4DE) stdout=filename(so) stderr=filename(se);
}

 
#----------------workflow-------------------#

# Read parameters from the sweepParams file and write to case files
file caseFile 	            <strcat(outDir,"cases.list")>;
file[] simFileParams        <filesys_mapper; location = simFilesDir>;
(caseFile, simFileParams) = writeCaseParamFiles(fsweepParams, simFilesDir, mexdex, utils);


file[] fmeshes;
foreach fsimParams,i in simFileParams{
    file meshErr       <strcat(errorsDir, "mesh", i, ".err")>;                          
    file meshOut       <strcat(logsDir, "mesh", i, ".out")>;                          
   	file fmesh  	   <strcat(meshFilesDir, i, "/allinone.inp")>;
    (fmesh, meshErr, meshOut) = makeMesh(meshScript, i, utils, fsimParams, preFbdFile);
    fmeshes[i] = fmesh;
}

# Generate ccx input (.inp) files
file[] fCcxInpFiles;
string[] caseOutDirs;
foreach fsimParams,i in simFileParams{
	caseOutDirs[i]   = strcat(caseDirRoot, i,"/");
	file finp        <strcat(caseOutDirs[i], "solve.inp")>;
	finp = getCcxInp(getCcxInpScript, fsimParams, utils);
	fCcxInpFiles[i] = finp;
}


# Write dflux.f files and use them to compile ccx files for each case
# Will most likely remove this part later ....
file[] ccxBinaries;
foreach fsimParams,i in simFileParams{
    file ccxBin               <strcat(caseOutDirs[i], "/ccx-212-patch/src/ccx_2.12")>;
    file dfluxfile            <strcat(caseOutDirs[i], "/dflux.f")>;
    (ccxBin, dfluxfile) = compileCcx(writeFortranFileScript, fsimParams, caseOutDirs[i], utils );
    ccxBinaries[i] = ccxBin;
}

# Run ccx and extract metrics for each case
file[] MetricsFiles;
foreach ccxBin,i in ccxBinaries{
    file MetricsOutput  <strcat(caseOutDirs[i], "metrics.csv")>;
    string pngOutDir = strcat(pngOutDirRoot,"/",i,"/");
    file fextractPng[]	 <filesys_mapper;location=pngOutDir>;	
	file fRunOut       <strcat(logsDir, "extractRun", i, ".out")>;
	file fRunErr       <strcat(errorsDir, "extractRun", i ,".err")>;

	file fsol         <strcat(trimSuffix(filename(fCcxInpFiles[i])),".exo")>;

    (MetricsOutput, fextractPng, fRunOut, fRunErr, fsol) = runSimExtractMetrics(ccxBin, fmeshes[i], fCcxInpFiles[i],
                                                                          materialLibFile, metrics2extract,
                                                                          pngOutDir, utils, mexdex);
    MetricsFiles[i] = MetricsOutput;                                                                       
}

file fDEout       <strcat(logsDir, "DE.out")>; 
file fDEerr       <strcat(errorsDir, "DE.err")>;


(outcsv,outhtml,fDEout, fDEerr) = designExplorer(runPath, caseFile, metrics2extract, pngOutDirRoot, caseDirRoot, MetricsFiles, outputsList4DE, mexdex);
