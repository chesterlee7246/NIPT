Args<-commandArgs()
Title<-Args[6]
Numbers<-as.numeric(Args[7])
Gender<-as.numeric(Args[8])
Name<-Args[9]

x<-1:Numbers
y<-rep(NA,Numbers)

png(Name,width =2400,height = 1200)
plot(x,y,ylim=c(-2,2),xaxt="n",yaxt="n",xlab="Sliding Window Bin",ylab="",main=Title,cex.main=3,cex.lab=2,xaxs = "i", yaxs = "i",bty="l")
axis(2,at=c(-2,-1,0,1,2),label=c(-2,-1,0,1,2),cex.axis=2,font.axis=2)

len<-c();
All=0

for(i in 1:Gender)
{
j=i+9
f<-read.table(Args[j])
x1<-t(f[6])
y1<-t(f[4])
z1<-t(f[5])
All=All+length(x1)
len<-c(len,All)
if(i%%4==1) {points(y1~x1,col="green",pch=16)}
if(i%%4==2) {points(y1~x1,col="yellow",pch=16)}
if(i%%4==3) {points(y1~x1,col="Violet",pch=16)}
if(i%%4==0) {points(y1~x1,col="Cyan",pch=16)}
points(z1~x1,cex=0.5,col="black",pch=16)
}

if(Gender==23) {axis(1,at=c(len[1]/2,((len[2]-len[1])/2+len[1]),((len[3]-len[2])/2+len[2]),((len[4]-len[3])/2+len[3]),((len[5]-len[4])/2+len[4]),((len[6]-len[5])/2+len[5]),((len[7]-len[6])/2+len[6]),((len[8]-len[7])/2+len[7]),((len[9]-len[8])/2+len[8]),((len[10]-len[9])/2+len[9]),((len[11]-len[10])/2+len[10]),((len[12]-len[11])/2+len[11]),((len[13]-len[12])/2+len[12]),((len[14]-len[13])/2+len[13]),((len[15]-len[14])/2+len[14]),((len[16]-len[15])/2+len[15]),((len[17]-len[16])/2+len[16]),((len[18]-len[17])/2+len[17]),((len[19]-len[18])/2+len[18]),((len[20]-len[19])/2+len[19]),((len[21]-len[20])/2+len[20]),((len[22]-len[21])/2+len[21]),((len[23]-len[22])/2+len[22])),label=c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,"X"),cex.axis=2,font.axis=2,las=2)}
if(Gender==24) {axis(1,at=c(len[1]/2,((len[2]-len[1])/2+len[1]),((len[3]-len[2])/2+len[2]),((len[4]-len[3])/2+len[3]),((len[5]-len[4])/2+len[4]),((len[6]-len[5])/2+len[5]),((len[7]-len[6])/2+len[6]),((len[8]-len[7])/2+len[7]),((len[9]-len[8])/2+len[8]),((len[10]-len[9])/2+len[9]),((len[11]-len[10])/2+len[10]),((len[12]-len[11])/2+len[11]),((len[13]-len[12])/2+len[12]),((len[14]-len[13])/2+len[13]),((len[15]-len[14])/2+len[14]),((len[16]-len[15])/2+len[15]),((len[17]-len[16])/2+len[16]),((len[18]-len[17])/2+len[17]),((len[19]-len[18])/2+len[18]),((len[20]-len[19])/2+len[19]),((len[21]-len[20])/2+len[20]),((len[22]-len[21])/2+len[21]),((len[23]-len[22])/2+len[22]),((len[24]-len[23])/2+len[23])),label=c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,"X","Y"),cex.axis=2,font.axis=2,las=2)}


abline(h=0, col=gray(0.3))
abline(h=0.4854268,lty=2,col="snow4",lwd=2)
abline(h=-0.7369656,lty=2,col="snow4",lwd=2)

dev.off()
