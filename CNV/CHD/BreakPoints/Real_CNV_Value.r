args<-commandArgs(T)
f<-read.table(args[1],sep='\t',header=T)

v1<-f$seg.mean
v2<-f$Runs.pvalue
v3<-c()
for(i in 1:length(v2)){
  if(v1[i]<=2.58 && v1[i]>=-2.58){
    v3<-c(v3,v1[i])
  }
}

x1<-median(v3)
x2<-mad(v3)
x3<-sd(v3)
x4<-mean(v3)

f$seg.dist<-abs(f$seg.mean-x1)
f$p.mad<-(f$seg.dist/x2)
new<-f
new$seg.dist<-abs(f$seg.mean-x4)
#f$p.sd<-pnorm(new$seg.dist/x3)
f$p.sd<-(new$seg.dist/x3)
write.table(f,args[2],sep="\t",quote=F,row.name=F)
