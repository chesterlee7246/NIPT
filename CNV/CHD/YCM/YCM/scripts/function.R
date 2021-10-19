evenness <- function(x){
	#PMID:27074764
	C  <- mean(x)
	D2 <- x[x<=C]
	e  <- 1-(length(D2)-sum(D2)/C)/length(x)
	return(e)
}

isoutlier <- function(x){
	d <- c(quantile(x,1/4)-IQR(x),quantile(x,3/4)+IQR(x))
	return(x < d[1] |  x  > d[2])
}

isupperoutlier <- function(x){
	d <- c(quantile(x,1/4)-IQR(x),quantile(x,3/4)+IQR(x))
	return(x  > d[2])
}

parse_control <- function(files){
	control_bedcov <- list()
	for (file in files){
		sample_name=sub("\\.bedcov$","",basename(file))
		#Title:chr start end sts gc cp r_cp NA19239_depth_ave NA19239_depth_one
		temp <- read.table(file=file, header=TRUE)
		temp[,paste(sample_name,"depth_ave",sep="_")] <-temp[,paste(sample_name,"depth_ave",sep="_")]/median(temp[,paste(sample_name,"depth_ave",sep="_")])
		control_bedcov[[sample_name]] <- temp
	}
	if(length(files) == 1 ){
		print("Only one control file, remove outliers depend on 1.5xIQR rule.")
		bedcov_df    <- control_bedcov[[files[1]]]
		bedcov_df$control_depth <- bedcov_df[,paste(files[1],"depth_ave",sep="_")]/median(bedcov_df[,paste(files[1],"depth_ave",sep="_")])
		bedcov_df$ok <- rev(isoutlier(bedcov_df[,paste(files[1],"depth_ave",sep="_")])) 
		return(bedcov_df)
	}
	bedcov_df       <- Reduce(join,control_bedcov)
	sample_names    <- names(control_bedcov)
	sample_cols     <- sapply(sample_names,function(x){paste(x,"depth_ave",sep="_")})
#	print(sample_cols)
	bedcov_df$control_depth  <- apply(bedcov_df[,sample_cols],1,mean)
	bedcov_df$sd    <- apply(bedcov_df[,sample_cols],1,sd)
	bedcov_df$evenness    <- apply(bedcov_df[,sample_cols],1,evenness)
	bedcov_df$ok    <- bedcov_df$evenness >=0.85 &  ! isupperoutlier(bedcov_df$control_depth)
	bedcov_df$ok	 <-	! is.na(bedcov_df$control_depth)
	print(bedcov_df)
	return(bedcov_df)
}

parse_sample <- function(files){
	sample_bedcov <- list()
	for (file in files){
		sample_name=sub("\\.bedcov$","",basename(file))
		#Title:chr start end sts gc cp r_cp NA19239_depth_ave NA19239_depth_one
		temp <- read.table(file=file, header=TRUE)
		temp[,paste(sample_name,"depth_ave",sep="_")] <-temp[,paste(sample_name,"depth_ave",sep="_")]/median(temp[,paste(sample_name,"depth_ave",sep="_")])
		sample_bedcov[[sample_name]] <- temp
	}
	sample_bedcov_df       <- Reduce(join,sample_bedcov)
	return(sample_bedcov_df)
}

isdeletion <- function(x){
	return(x <= -0.7)
}

isduplication <- function(x){
	return(x >= 0.7)
}

bins_seg <- function(bins_file,control_file){
	bins <- read.table(bins_file,header=FALSE,sep="\t",fill=TRUE,col.names = c("chr","start","end","depth","index","ignore"))
	if(control_file =="" ){
		m1   <- median(bins[bins$ignore !='ignore' & bins$depth >0,"depth"])
		bins$log2ratio <- log2(bins$depth/m1)
		bins[is.infinite(bins$log2ratio) | bins$log2ratio < -4 ,"log2ratio"] <- -4
		return(bins)
	}
	df <- control_bin(control_file)
	bins <- join(bins,df)
	bins$log2ratio  <- NA
#	bins$depth <- bins$depth/ median(bins[bins$ignore !='ignore' & bins$depth >0 & bins$selected,"depth"])
#	bins$depth <- bins$depth/ median(bins[bins$ignore !='ignore' & bins$depth >0 & bins$selected & bins$start<5400000,"depth"])
	bins$depth <- bins$depth/ median(bins[bins$ignore !='ignore' & bins$depth >0 & bins$selected & bins$start<24000000,"depth"])
	bins[bins$mean!=0 &  bins$selected & bins$ignore!='ignore', "log2ratio"]  <- log2(bins[bins$mean!=0 & bins$selected & bins$ignore!='ignore',"depth"]/bins[bins$mean !=0 & bins$selected & bins$ignore!="ignore","mean"])
	bins[! is.na(bins$log2ratio) & (is.infinite(bins$log2ratio) | bins$log2ratio < -4) ,"log2ratio"] <- -4
	return(bins)
}

control_bin <- function(control_file){
	control <- list()
	files <- read.table(control_file,header=F,sep="\n")
	i=1
	for (file in files[,1]){
		temp <- read.table(file=file, header=F,col.names=c("chr","start","end",paste("depth",i,sep=""),"index","ignore"),fill=TRUE)
		temp[,paste("depth",i,sep="")] <- temp[,paste("depth",i,sep="")]/ median(temp[temp$ignore !='ignore' & temp[,paste("depth",i,sep="")] >0, paste("depth",i,sep="")])
		control[[i]] <- temp[,c("index",paste("depth",i,sep=""))]
		i <- i+1
	}
	 df <- Reduce(join,control)
	 df$mean <- apply(df[,2:NCOL(df)],1,median)
	 df$selected <- apply(df[,2:(NCOL(df)-1)],1,function(x){ ! 0 %in% x})
	 df$sd <- apply(df[,2:(NCOL(df)-2)],1,sd)
	 return(df[,c("index","mean","selected","sd")])
}


amplicon_index <- function(amplicon_file,bin){
	amplicon <- read.table(amplicon_file,header=TRUE,fill=TRUE,sep="\t")
	amplicon$start <-  floor(amplicon$hg19_start/bin)
	amplicon$end <- ceiling(amplicon$hg19_end/bin)
	return(amplicon)
}


dnacopy_seg<- function(x1,sampleid="Basecare.1"){
	options(scipen=100)
	library(DNAcopy)
	x1[x1$ignore!="ignore" & !is.na(x1$log2ratio),"index.new"] <- 1:NROW(x1[x1$ignore!="ignore" & !is.na(x1$log2ratio),])
	x1.object <- CNA(cbind(x1[x1$ignore!="ignore" & !is.na(x1$log2ratio),"log2ratio"]),x1[x1$ignore!="ignore" & !is.na(x1$log2ratio),"chr"],x1[x1$ignore!="ignore" & !is.na(x1$log2ratio) ,"index.new"],"logratio",sampleid = sampleid)
	x1.CNA.object <-  smooth.CNA(x1.object)
	print("OK")
	segment.smoothed.CNA.object <- segment(x1.CNA.object)
	segs <- data.frame (x1=x1[x1$index.new %in% segment.smoothed.CNA.object$output$loc.start,"index"],x2=x1[x1$index.new %in% segment.smoothed.CNA.object$output$loc.end,"index"],y=segment.smoothed.CNA.object$output$seg.mean)
	return(list(bins=x1,segment=segs,ssco=segment.smoothed.CNA.object))
}


plotY <- function(x1,amplicon,ymax,segs){
   library(ggplot2)
	library(grid)
	p  <- ggplot(x1,aes(x=index,y=log2ratio))+geom_point(size=1.5,color="black")+geom_segment(data=segs,aes(x=x1,xend=x2,y=y,yend=y),color="red")+theme_bw()
#	p  <- ggplot(x1,aes(x=index,y=log2ratio))+geom_point(size=1,color="black")+geom_segment(data=segs,aes(x=x1,xend=x2,y=y,yend=y),color="red")+ggthemes::theme_stata()
	a1 <- ymax-1
	p  <- p+ geom_segment(aes(x=start,xend=end,y=a1,yend=a1),data=amplicon[amplicon$level==1,])+geom_text(aes(x=(start+end)/2,y=a1+0.5,label=region),size=rel(6),data=amplicon[amplicon$level==1,])
	a2 <- a1-1
	p  <- p+geom_segment(aes(x=start,xend=end,y=a2,yend=a2),data=amplicon[amplicon$level==2,])+geom_text(aes(x=(start+end)/2,y=a2+0.5,label=region),size=rel(6),data=amplicon[amplicon$level==2,])
	a3 <- a2-1
	p  <- p+geom_segment(aes(x=start,xend=end,y=a3,yend=a3),data=amplicon[amplicon$level==3,])+geom_text(aes(x=(start+end)/2,y=a3+0.5,label=region),size=rel(6),data=amplicon[amplicon$level==3,])
	a4 <- a3-1
	p  <- p+geom_segment(aes(x=start,xend=end,y=a4,yend=a4),data=amplicon[amplicon$level==4,])+geom_text(aes(x=(start+end)/2,y=a4+0.5,label=region),size=rel(6),data=amplicon[amplicon$level==4,])
	a5 <- a4-1
	p  <- p+geom_segment(aes(x=end,xend=start,y=a5,yend=a5),color='red',arrow=arrow(length=unit(0.2,"cm")),data=amplicon[amplicon$level==5 &  amplicon$direction =='-',])+geom_text(aes(x=(start+end)/2,y=a5+0.5,label=region),angle=90,size=rel(6),data=amplicon[amplicon$level==5 & amplicon$direction =='-',])
#	p  <- p+geom_segment(aes(x=end,xend=start,y=a5,yend=a5),color='red',data=amplicon[amplicon$level==5 &  amplicon$direction =='-',])+geom_text(aes(x=(start+end)/2,y=a5+0.5,label=region),angle=90,size=rel(6),data=amplicon[amplicon$level==5 & amplicon$direction =='-',])
	p  <- p+geom_segment(aes(x=start,xend=end,y=a5,yend=a5),color="green",arrow=arrow(length=unit(0.2,"cm")),data=amplicon[amplicon$level==5 & amplicon$direction =='+',])+geom_text(aes(x=(start+end)/2,y=a5+0.5,label=region),angle=90,size=rel(6),data=amplicon[amplicon$level==5 & amplicon$direction =='+',])
#	p  <- p+geom_segment(aes(x=start,xend=end,y=a5,yend=a5),color="green",data=amplicon[amplicon$level==5 & amplicon$direction =='+',])+geom_text(aes(x=(start+end)/2,y=a5+0.5,label=region),angle=90,size=rel(6),data=amplicon[amplicon$level==5 & amplicon$direction =='+',])
	return(p)
}

insdel_region <- function(dnacopy_list,insdel_region){
	insdels <- data.frame(start=0,end=0)
	if(length(insdel_region) == 0)
		return(insdels)
	insdels_index <- 1
	flag <- 0
	for (i in 1:length(insdel_region)){
		#if("ignore" %in% dnacopy_list$bins[dnacopy_list$bins$index %in% dnacopy_list$segment[insdel_region[i],"x1"]:dnacopy_list$segment[insdel_region[i],"x2"],"ignore"])
		#	next
		if(flag ==0){
			insdels <- data.frame(start=insdel_region[i],end=insdel_region[i])
			flag <- 1
			next
		}
		if(insdel_region[i]-insdels[insdels_index,"end"]==1){
			insdels[insdels_index,"end"] <- insdel_region[i]
		}else{
			insdels_index <- insdels_index+1
			insdels[insdels_index,"start"] <- insdel_region[i]
			insdels[insdels_index,"end"] <- insdel_region[i]
		}
	}
	return(insdels)
}
