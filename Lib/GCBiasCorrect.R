args<-commandArgs(T)
x<-read.table(args[1],sep='\t',header=T)
model=loess(ReadsNumber~GC,data=x);
x$Fit <- model$fit;
Median1 <- median(x$ReadsNumber);#校正前reads数的中位数
x$WeightValue <- (Median1/x$Fit)#fit是什么，用中位数除以fit的目的是什么
x$RCgc <- x$ReadsNumber * x$WeightValue;
write.table(x,args[2],sep="\t",quote=F,row.name=F);
