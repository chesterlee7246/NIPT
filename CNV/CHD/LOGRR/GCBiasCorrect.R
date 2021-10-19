args<-commandArgs(T)
x<-read.table(args[1],sep='\t',header=T)
model=loess(ReadsNumber~GC,data=x);
x$Fit <- model$fit;
Median1 <- median(x$ReadsNumber);
x$WeightValue <- (Median1/x$Fit)
x$RCgc <- x$ReadsNumber * x$WeightValue;
write.table(x,args[2],sep="\t",quote=F,row.name=F);
