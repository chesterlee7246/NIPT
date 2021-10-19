library(cghFLasso)

Args <- commandArgs(T)
f <-read.table(Args[1],sep='\t',header=T)


ve <- cghFLasso(f$ZScore,chromosome=f$Chromosome)

f$CopyN <- ve$Esti.CopyN

write.table(f,Args[2],sep="\t",quote=F,row.name=F);
#warnings()
