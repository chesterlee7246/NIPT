Args<-commandArgs()
f<-read.table(Args[6])
Title<-Args[7]
Name<-Args[8]
Numbers<-as.numeric(Args[9])

x<-t(c(1:Numbers))
y<-t(f[4])
z<-t(f[5])

png(Name,width =1200,height = 600)

plot(y~x,type="p",col="snow4",pch=16,ylim=c(-2,2),yaxt="n",xlab="Sliding Window Bin",ylab="",main=Title,cex.main=3,cex.lab=2,xaxs = "i", yaxs = "i",bty="l",cex.axis=2)
axis(2,at=c(-2,-1,0,1,2),label=c(-2,-1,0,1,2),cex.axis=2)
points(z~x,cex=0.5,col="blue",pch=16,type="l")
abline(h=0, col=gray(0.3))
abline(h=0.4854268,lty=2,col="black",lwd=2)
abline(h=-0.7369656,lty=2,col="black",lwd=2)

dev.off()