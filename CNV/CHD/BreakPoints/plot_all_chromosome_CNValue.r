Args<-commandArgs()
Title<-Args[6]
Numbers<-as.numeric(Args[7])
Gender<-as.numeric(Args[8])
Name<-Args[9]

x<-1:Numbers
y<-rep(NA,Numbers)

png(Name,width =2400,height = 1200)
#plot(x,y,ylim=c(0,8),xaxt="n",yaxt="n",xlab="Sliding Window Bin",ylab="",main=Title,cex.main=3,cex.lab=2,xaxs = "i", yaxs = "i",bty="l")
plot(x,y,ylim=c(0,6),xaxt="n",yaxt="n",xlab="",ylab="",main=Title,cex.main=3,cex.lab=2,xaxs = "i", yaxs = "i",bty="l")
axis(2,at=c(0,2,4,6),label=c(0,2,4,6),cex.axis=2,font.axis=2)

len<-c();
All=0

Red<-rgb(red=237,green=28,blue=36,max=255)
Green<-rgb(red=34,green=177,blue=76,max=255)

for(i in 1:Gender)
{
j=i+9
f<-read.table(Args[j])
x1<-t(f[6])
y1<-t(f[4])
z1<-t(f[5])
All=All+length(x1)
len<-c(len,All)
if(i%%4==1) {points(y1~x1,col="IndianRed1",pch=16)}
if(i%%4==2) {points(y1~x1,col="SeaGreen3",pch=16)}
if(i%%4==3) {points(y1~x1,col="IndianRed1",pch=16)}
if(i%%4==0) {points(y1~x1,col="SeaGreen3",pch=16)}
points(z1~x1,cex=0.5,col="black",pch=16)
}


if(Gender==22) {axis(1,at=c(len[1]/2,((len[2]-len[1])/2+len[1]),((len[3]-len[2])/2+len[2]),((len[4]-len[3])/2+len[3]),((len[5]-len[4])/2+len[4]),((len[6]-len[5])/2+len[5]),((len[7]-len[6])/2+len[6]),((len[8]-len[7])/2+len[7]),((len[9]-len[8])/2+len[8]),((len[10]-len[9])/2+len[9]),((len[11]-len[10])/2+len[10]),((len[12]-len[11])/2+len[11]),((len[13]-len[12])/2+len[12]),((len[14]-len[13])/2+len[13]),((len[15]-len[14])/2+len[14]),((len[16]-len[15])/2+len[15]),((len[17]-len[16])/2+len[16]),((len[18]-len[17])/2+len[17]),((len[19]-len[18])/2+len[18]),((len[20]-len[19])/2+len[19]),((len[21]-len[20])/2+len[20]),((len[22]-len[21])/2+len[21])),label=c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22),cex.axis=2,font.axis=2,las=2)}
if(Gender==23) {axis(1,at=c(len[1]/2,((len[2]-len[1])/2+len[1]),((len[3]-len[2])/2+len[2]),((len[4]-len[3])/2+len[3]),((len[5]-len[4])/2+len[4]),((len[6]-len[5])/2+len[5]),((len[7]-len[6])/2+len[6]),((len[8]-len[7])/2+len[7]),((len[9]-len[8])/2+len[8]),((len[10]-len[9])/2+len[9]),((len[11]-len[10])/2+len[10]),((len[12]-len[11])/2+len[11]),((len[13]-len[12])/2+len[12]),((len[14]-len[13])/2+len[13]),((len[15]-len[14])/2+len[14]),((len[16]-len[15])/2+len[15]),((len[17]-len[16])/2+len[16]),((len[18]-len[17])/2+len[17]),((len[19]-len[18])/2+len[18]),((len[20]-len[19])/2+len[19]),((len[21]-len[20])/2+len[20]),((len[22]-len[21])/2+len[21]),((len[23]-len[22])/2+len[22])),label=c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,"X"),cex.axis=2,font.axis=2,las=2)}
if(Gender==24) {axis(1,at=c(len[1]/2,((len[2]-len[1])/2+len[1]),((len[3]-len[2])/2+len[2]),((len[4]-len[3])/2+len[3]),((len[5]-len[4])/2+len[4]),((len[6]-len[5])/2+len[5]),((len[7]-len[6])/2+len[6]),((len[8]-len[7])/2+len[7]),((len[9]-len[8])/2+len[8]),((len[10]-len[9])/2+len[9]),((len[11]-len[10])/2+len[10]),((len[12]-len[11])/2+len[11]),((len[13]-len[12])/2+len[12]),((len[14]-len[13])/2+len[13]),((len[15]-len[14])/2+len[14]),((len[16]-len[15])/2+len[15]),((len[17]-len[16])/2+len[16]),((len[18]-len[17])/2+len[17]),((len[19]-len[18])/2+len[18]),((len[20]-len[19])/2+len[19]),((len[21]-len[20])/2+len[20]),((len[22]-len[21])/2+len[21]),((len[23]-len[22])/2+len[22]),((len[24]-len[23])/2+len[23])),label=c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,"X","Y"),cex.axis=2,font.axis=2,las=2)}

abline(h=1,lty=2,col="snow4",lwd=2)
abline(h=2,lty=2,col="snow4",lwd=2)
abline(h=3,lty=2,col="snow4",lwd=2)
abline(h=4,lty=2,col="snow4",lwd=2)
abline(h=5,lty=2,col="snow4",lwd=2)
abline(h=6,lty=2,col="snow4",lwd=2)
#abline(h=7,lty=2,col="snow4",lwd=2)
#abline(h=8,lty=2,col="snow4",lwd=2)

dev.off()