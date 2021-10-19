#!/last/data/JunZhang/local/bin/Rscript
#load library
library("ggplot2") #ggplot
library("optparse")
library("plyr")
library("stringr")
library("DNAcopy")
library("grid")  #arrow for ubuntu 10.04
options(scipen=100) #disable scientific digits
getScriptPath <- function(){
	cmd.args <- commandArgs()
	m <- regexpr("(?<=^--file=).+", cmd.args, perl=TRUE)
	script.dir <- dirname(regmatches(cmd.args, m))
	if(length(script.dir) == 0) stop("can't determine script dir: please call the script with Rscript")
	if(length(script.dir) > 1) stop("can't determine script dir: more than one '--file' argument detected")
	return(script.dir)
}
path <-	getScriptPath()

source(paste(path,"function.R",sep="/")) #amplicon_index dnacopy_seg bins_seg insdel_region...
#parse args
option_list = list(
	make_option(c("-f", "--bin_file"), type="character", default=NULL, help="...", metavar="character"),
	make_option(c("-s", "--bin_size"), type="character", default=NULL, help="...", metavar="character"),
	make_option(c("-c", "--control_bin_file"), type="character", default=NULL, help="...", metavar="character"),
	make_option(c("-l", "--log_file"), type="character", default=NULL, help="...", metavar="character"),
	make_option(c("-d", "--data"), type="character", default=NULL, help="...", metavar="character"),
	make_option(c("--start"), type="integer", default=NULL, help="...", metavar="integer"),
	make_option(c("--end"), type="integer", default=NULL, help="...", metavar="integer")
);

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);


bin_size <- as.numeric(opt$bin_size)

if(length(opt$control_bin_file) == 0 ){
	opt$control_bin_file <- ""
}
amplicon <-	amplicon_index(opt$data,bin_size)
x1 <- bins_seg(opt$bin_file,opt$control_bin_file)
dnacopy_list <- dnacopy_seg(x1,sub("\\..*","",basename(opt$bin_file)))
del_region <- as.numeric(row.names(dnacopy_list$segment[dnacopy_list$segment$y <= -0.57,]))
dup_region <- as.numeric(row.names(dnacopy_list$segment[dnacopy_list$segment$y >=  0.57,]))

dels <- insdel_region(dnacopy_list,del_region)
dups <- insdel_region(dnacopy_list,dup_region)
del_info <- ""
dup_info <- ""

if(dels[1,1] != 0){
	del_info <- str_c(mapply(function(x){paste("[GRCh37/hg19](chrY:",dnacopy_list$segment[dels[x,"start"],"x1"] * bin_size,"-",(dnacopy_list$segment[dels[x,"end"],"x2"]+1) * bin_size,")del",sep="")},1:NROW(dels)),collapse = ";")
}
if(dups[1,1] != 0){
	dup_info <- str_c(mapply(function(x){paste("[GRCh37/hg19](chrY:",dnacopy_list$segment[dups[x,"start"],"x1"] * bin_size,"-",(dnacopy_list$segment[dups[x,"end"],"x2"]+1) * bin_size,")dup",sep="")},1:NROW(dups)),collapse = ";")
}

if(length(opt$log_file) !=0 ){
	write.table(file=opt$log_file,x=data.frame(sample=sub("\\..*$","",basename(opt$bin_file)),delinfo=del_info,dupinfo=dup_info),append=FALSE,sep="\t",col.names=FALSE,row.names=FALSE,quote=FALSE)
}else{
	cat(sprintf("Sample:%s\t%s\t%s\n",sub("\\..*$","",basename(opt$bin_file)),delinfo=del_info,dupinfo=dup_info),filt=stdout())
}
#pdf file
options(scipen=100) #disable scientific digits
xcoord <- seq(0,max(dnacopy_list$bins$index),max(dnacopy_list$bins$index)/10)
xlabels <- xcoord*bin_size
ylimits <- c(-4.5,5.5)
ybreaks <- c(seq(-4,4,2))
a1 <- 5
a2 <- a1-1
a3 <- a2-1
a4 <- a3-1
a5 <- a4-1
file_name=gsub(".depth.bins","",opt$bin_file)
pdf(file=paste(file_name,".pdf",sep=""),width=100,height=10)
#print(plotY(dnacopy_list$bins, amplicon,6 ,dnacopy_list$segment)+labs(title=paste("Sample: ",sub("\\..*$","",basename(opt$bin_file)),"\n",del_info,"\n",dup_info,sep=""))+ylab("log2ratio")+xlab(paste("index of bin(bin size = ",bin_size %/% 1000," Kbp)"))+theme(axis.title=element_text(size=rel(2)),plot.title=element_text(size=rel(2)),axis.text=element_text(size=rel(2)))+ylim(-4.5,7.5))
print(plotY(dnacopy_list$bins, amplicon,6 ,dnacopy_list$segment)+ylab("log2ratio")+xlab(paste("Position(bin size = ",bin_size %/% 1000," Kbp)"))+theme(axis.title=element_text(size=24),plot.title=element_text(size=24),axis.text=element_text(size=20))+geom_hline(yintercept=0.6,color="grey50",linetype=2)+geom_hline(yintercept=-0.6,color="grey50",linetype=2)+scale_x_continuous(breaks=xcoord,labels=xlabels)+scale_y_continuous(breaks=ybreaks,limits=ylimits))
dev.off()

#png file
png(type="cairo",file=paste(file_name,".png",sep=""),width=2620,height=1080,res=102)
#print(plotY(dnacopy_list$bins, amplicon,6 ,dnacopy_list$segment)+labs(title=paste("Sample: ",sub("\\..*$","",basename(opt$bin_file)),"\n",del_info,"\n",dup_info,sep=""))+ylab("log2ratio")+xlab(paste("index of bin(bin size = ",bin_size %/% 1000," Kbp)"))+theme(axis.title=element_text(size=rel(2)),plot.title=element_text(size=rel(2)),axis.text=element_text(size=rel(2)))+xlim(2649806%/% bin_size,29819361%/%bin_size) +ylim(-4.5,7.5))

newsegment <- dnacopy_list$segment
#p&q
#xlimits <- c(2649806%/% bin_size,29819361%/%bin_size)
#only AZF
#xlimits <- c(14252761 %/% bin_size,29819361 %/%bin_size)
xlimits <- c(opt$start %/% bin_size,opt$end %/%bin_size)
newsegment <- newsegment[newsegment$x2>=xlimits[1] & newsegment$x1<=xlimits[2],]
newsegment[newsegment$x1<xlimits[1],"x1"]=xlimits[1]
newsegment[newsegment$x2>xlimits[2],"x2"]=xlimits[2]
print(plotY(dnacopy_list$bins, amplicon,6 ,newsegment)+ylab("log2ratio")+xlab(paste("Position(bin size = ",bin_size %/% 1000," Kbp)"))+theme(axis.title=element_text(size=24),plot.title=element_text(size=24),axis.text=element_text(size=20))+geom_hline(yintercept=0.6,color="grey50",linetype=2)+geom_hline(yintercept=-0.6,color="grey50",linetype=2)+scale_x_continuous(breaks=xcoord,labels=xlabels,limits=c(xlimits))+scale_y_continuous(breaks=ybreaks,limits=ylimits))
dev.off()
