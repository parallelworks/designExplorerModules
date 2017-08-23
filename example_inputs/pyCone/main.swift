# Cone generator parameter sweep
type file;
############################################
# ------ INPUT / OUTPUT DEFINITIONS -------#
############################################

# workflow inputs
# comment this line out when running under dakota
file params         <arg("paramFile","params.run")>; 
file kpi            <"kpi_tmp.json">;

# add models
file[] mexdex       <Ext;exec="utils/mapper.sh",root="models/mexdex">;
file[] coneGen       <Ext;exec="utils/mapper.sh",root="models/coneGenerator">;

# other inputs
string outdir      = "results/";
string casedir     = strcat(outdir,"case");
string kpi_header  = "cone";

# workflow outputs
file outhtml        <arg("html","results/output.html")>;
file outcsv         <arg("csv","results/output.csv")>;
string path        = toString(@java("java.lang.System","getProperty","user.dir"));

##############################
# ---- APP DEFINITIONS ----- #
##############################

app (file out) prepInputs (file params, file s[])
{
  python2 "models/mexdex/prepInputs.py" @params @out;
}

app (file volAndLat, file stlFile, file so, file se) createCone (string heightAndRadius, file[] coneGen)
{
  python2 "models/coneGenerator/createCone.py" heightAndRadius @volAndLat @stlFile stdout=@so stderr=@se;
}

app (file csvFile, file[] pngFiles, file so, file se) createConeImage (file stlFile, file kpi, string kpi_header, file[] mexdex, string extractOutDir)
{
  bash "models/mexdex/extract_ED.sh" "models/mexdex/extract.sh" "models/mexdex/extract.py" @stlFile @kpi @csvFile extractOutDir kpi_header stdout=filename(so) stderr=filename(se);
}

app (file outcsv, file outhtml, file so, file se) postProcess (file[] t, string rpath, file caselist, file kpi, string kpi_header, file[] mexdex) {
  bash "models/mexdex/postprocess.sh" filename(outcsv) filename(outhtml) rpath @kpi kpi_header stdout=filename(so) stderr=filename(se);
}


######################
# ---- WORKFLOW ---- #
######################

file caselist <"cases.list">;

# comment this line out when running under dakota
caselist = prepInputs(params,mexdex);

string[] cases = readData(caselist);

tracef("\n%i Cases in Simulation\n\n",length(cases));

file[] metrics;
foreach heightAndRadius,i in cases{
    trace(i,heightAndRadius);
    # generate the geometry step file
    file volAndLat     <strcat(casedir,"_",i,"/volAndLat.txt")>;
    file stlFile     <strcat(casedir,"_",i,"/cone.stl")>;
    file cco 	            <strcat("logs/case_",i,"/createCone.out")>;
    file cce         	      <strcat("logs/case_",i,"/createCone.err")>;
    (volAndLat,stlFile,cco,cce)=createCone(heightAndRadius,coneGen);
    metrics[i]=volAndLat;

    file ccio                 <strcat("logs/case_",i,"/createConeImage.out")>;
    file ccie                   <strcat("logs/case_",i,"/createConeImage.err")>;
    file csvFile     <strcat(casedir,"_",i,"/",kpi_header,".csv")>; # csvFile and pngFile must be on the dame folder
#    file pngFile     <strcat(casedir,"_",i,"/out_",kpi_header,".png")>;
#    file gifFile     <strcat(casedir,"_",i,"/out_",kpi_header,".gif")>;
    string extractOutDir = strcat(casedir,"_",i,"/");
    file fextractPng[]	 <filesys_mapper;location=extractOutDir>;	
    (csvFile,fextractPng,ccio,ccie)=createConeImage(stlFile,kpi,kpi_header,mexdex,extractOutDir);
}

file spout <"logs/post.out">;
file sperr <"logs/post.err">;
(outcsv,outhtml,spout,sperr) = postProcess(metrics,path,caselist,kpi,kpi_header,mexdex);
