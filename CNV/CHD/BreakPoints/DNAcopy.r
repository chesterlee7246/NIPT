library(DNAcopy)

Args <- commandArgs(T)
f <-read.table(Args[1],,sep='\t',header=T)
id=Args[2]
SDV=as.numeric(Args[4])

CNA.object <- CNA(cbind(f$ZScore),f$Chromosome,f$Start,sampleid=id)

smoothed.CNA.object <- smooth.CNA(CNA.object)

sdundo.CNA.object <- segment(smoothed.CNA.object, undo.splits = "sdundo", undo.SD = SDV, min.width = 2,verbose=0)

sink(Args[3])
sdundo.CNA.object
sink()

