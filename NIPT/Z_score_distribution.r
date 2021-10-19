library("ggplot2")
library("tidyverse")

args <- commandArgs(T)
out_pdf <- paste0(args[2],"/",args[4], "_",args[3],"_zscore_distribution.pdf")
Title = paste0(args[4], "_",args[3])
data <- read.table(args[1], header = T,sep = "\t", quote = "")
data2<-iris %>% pivot_longer(data = data,
             cols = c("chr1","chr2","chr3","chr4","chr5","chr6","chr7","chr8","chr9","chr10","chr11","chr12","chr13","chr14","chr15","chr16","chr17","chr18","chr19","chr20","chr21","chr22","chrX"),
             names_to = "chr",
             values_to = "z_score")
max = max(data2$z_score)
min = min(data2$z_score)
if(max(data2$z_score) > abs(min(data2$z_score))){
  min <- -max(data2$z_score)
  max <- max(data2$z_score)
}else{
  min <- min(data2$z_score)
  max <- -min(data2$z_score)
}

data2$chr <- factor(data2$chr,levels = c("chr1","chr2","chr3","chr4","chr5","chr6","chr7","chr8","chr9","chr10","chr11","chr12","chr13","chr14","chr15","chr16","chr17","chr18","chr19","chr20","chr21","chr22","chrX"))
pdf(out_pdf, width = 15, height = 6)
ggplot(data2,aes(x=chr,y=z_score))+
  stat_boxplot(geom = "errorbar",width=0.15)+ #由于自带的箱形图没有胡须末端没有短横线，使用误差条的方式补上
  geom_boxplot(size=0.5,outlier.alpha=0)+#size设置箱线图的边框线和胡须的线宽度，outline.alpha =0 ,不显示离群点
  geom_jitter(aes(color = index),width =0.2,size=1.5)+
  labs(title = Title)+theme(plot.title = element_text(hjust = 0.5))+
  ylim(-3.005,3.005)

dev.off()
