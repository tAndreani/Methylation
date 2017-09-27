library(methylKit)


readBismarkCytosineReport<-function(location,sample.id,assembly="unknown",treatment,
                                    context="CpG",min.cov=10){
  if(length(location)>1){
    stopifnot(length(location)==length(sample.id),
              length(location)==length(treatment))
  }
  
  result=list()
  for(i in 1:length(location)){
    df=fread.gzipped(location[[i]],data.table=FALSE)
    
    # remove low coverage stuff
    df=df[ (df[,4]+df[,5]) >= min.cov ,]
    
    
    
    
    # make the object (arrange columns of df), put it in a list
    result[[i]]= new("methylRaw",
                     data.frame(chr=df[,1],start=df[,2],end=df[,2],
                                strand=df[,3],coverage=(df[,4]+df[,5]),
                                numCs=df[,4],numTs=df[,5]),
                     sample.id=sample.id[[i]],
                     assembly=assembly,context=context,resolution="base"
    )
  }
  
  if(length(result) == 1){
    return(result[[1]])
  }else{
    
    new("methylRawList",result,treatment=treatment)
  }
}

# reads gzipped files,
fread.gzipped<-function(filepath,...){
  require(R.utils)
  require(data.table)
  
  
  
  # decompress first, fread can't read gzipped files
  if (R.utils::isGzipped(filepath)){
    
    if(.Platform$OS.type == "unix") {
      filepath=paste("zcat",filepath)
    } else {
      filepath <- R.utils::gunzip(filepath,temporary = FALSE, overwrite = TRUE,
                                  remove = FALSE)
    }
    
    
  }
  
  ## Read in the file
  fread(filepath,...)
  
}


########################################
###Read your Sample and Call DMRs#######
########################################
setwd("/gpfs/fs6/jgu-cbdm/andradeLab/scratch/tandrean/Data/WGBS/Gadd45.TKO/Gadd45.tko.Quality.Filter/Extraction/MethylKit")

#Files are the output of Bismarck i.e. the Cytosine Report Files (example Gadd45.tko1.CpG_report.txt) with a ToT CG of 43841737 in each file
file.list <- list("control1.myCpG.gz","test1.myCpG.gz","test2.myCpG.gz","test3.myCpG.gz")
myobj=readBismarkCytosineReport(file.list,sample.id=list("ctrl1","test1","test2","test3"),assembly="mm10",treatment=c(0,1,1,1))
tiles <- tileMethylCounts(myobj,cov.bases = 10, win.size = 200,step.size = 200)
meth=unite(tiles,destrand=TRUE)
pdf('All.samples.Correlation.Tiles.200.pdf')
getCorrelation(meth, plot = T)
dev.off()
pdf('All.samples.PCA.Tiles.200.pdf')
PCASamples(meth)
dev.off()
myDiff <- calculateDiffMeth(meth)
myDiff25p.hyper <- getMethylDiff(myDiff, difference = 15,qvalue = 0.05, type = "hyper")
myDiff25p.hypo <- getMethylDiff(myDiff, difference = 15,qvalue = 0.05, type = "hypo")
Hyper <- getData(myDiff25p.hyper)
Hypo <- getData(myDiff25p.hypo)
write.table(myDiff,"Background.Gadd45.TKO.cov.10.Tiles.200.delta.15.txt",quote=FALSE,col.names=T,row.names=F,sep="\t") ##For Backgroung
write.table(myDiff25p.hyper,"Hyper.DMRs.Gadd45.TKO.cov.10.Tiles.200.delta.15.txt",quote=FALSE,col.names=T,row.names=F,sep="\t")
write.table(myDiff25p.hypo,"Hypo.DMRs.Gadd45.TKO.cov.10.Tiles.200.delta.15.txt",quote=FALSE,col.names=T,row.names=F,sep="\t")