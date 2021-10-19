library(ggplot2)
library(plyr)
library(reshape2)
library(readr)
library(stringi)
library(dplyr)

args=commandArgs(T)

#COLORS = c('red'='#f8766d', 'blue'='#00bfc4')
#COLORS = c('#f8766d', '#00bfc4')
Red<-rgb(red=237,green=28,blue=36,max=255)
Green<-rgb(red=34,green=177,blue=76,max=255)
COLORS = c(Red, Green)

COLORS2 = c('#EFEFEF', 'white')

chrom_data <- function(gender){
	if(gender==24){
        chroms <- read.csv(text="
chr1,249250621
chr2,243199373
chr3,198022430
chr4,191154276
chr5,180915260
chr6,171115067
chr7,159138663
chr8,146364022
chr9,141213431
chr10,135534747
chr11,135006516
chr12,133851895
chr13,115169878
chr14,107349540
chr15,102531392
chr16,90354753
chr17,81195210
chr18,78077248
chr19,59128983
chr20,63025520
chr21,48129895
chr22,51304566
chrX,155270560
chrY,59373566", col.names=c("chr", 'max'), header=FALSE)

        chroms$chr <- factor(chroms$chr, levels=paste("chr", c(1:22, "X", "Y"), sep=""))
	}else{
chroms <- read.csv(text="
chr1,249250621
chr2,243199373
chr3,198022430
chr4,191154276
chr5,180915260
chr6,171115067
chr7,159138663
chr8,146364022
chr9,141213431
chr10,135534747
chr11,135006516
chr12,133851895
chr13,115169878
chr14,107349540
chr15,102531392
chr16,90354753
chr17,81195210
chr18,78077248
chr19,59128983
chr20,63025520
chr21,48129895
chr22,51304566
chrX,155270560", col.names=c("chr", 'max'), header=FALSE)
	chroms$chr <- factor(chroms$chr, levels=paste("chr", c(1:22, "X"), sep=""))
	}
    chroms <- chroms[order(chroms$chr), ]
    chroms$cumsum <- c(0, cumsum(as.numeric(chroms$max))[-NROW(chroms)])
    chroms$cumstart <- c(0, cumsum(as.numeric(chroms$max))[-NROW(chroms)]) + 1
    chroms$cumend <- cumsum(as.numeric(chroms$max))
    return(chroms)
}


read_reference <- function(input){
        df <- read_delim(file=input, col_names=c('chr','start','end','logrr','zscore'), delim="\t", skip =1)
        return(df)
}

read_segments <- function(input){
	df <- read_delim(file=input, delim="\t", skip=1)
	return(df)	
}

plot_data <- function(df, segments, chroms, title_name, gender){
        colors <- rep(COLORS, length(levels(df$chr)))
		colors2 <- rep(COLORS2, length(levels(df$chr)))
        coord = ddply(chroms, .(chr), summarise, newcoord=(cumstart+cumend)/2)
		segments$newseg = 2*2^segments$seg.mean
		df$CN = 2*2^df$logrr
		if(gender ==24){
			df[df$chr %in% c('chrX', 'chrY'), 'CN'] = 2*2^df[df$chr %in% c('chrX', 'chrY'), 'logrr'] - 1
			segments[segments$chrom  %in% c('chrX', 'chrY'), 'newseg'] = 2*2^segments[segments$chrom  %in% c('chrX', 'chrY'), 'seg.mean'] - 1
		}
        p <- ggplot() +
        scale_y_continuous(limits=c(0, 6), breaks=seq(0, 6, 2), labels=c(" 0 ", ' 2 ',' 4 ',' 6 '), expand=c(0,0)) +
        scale_x_continuous(limits=c(0,max(chroms$cumend)), breaks=coord$newcoord, labels=stri_replace_all(coord$chr, regex='chr', replacement=""), expand=c(0,0))
        for (ik in 1:NROW(chroms)){
                cumstart <- chroms[ik, 'cumstart']
                cumend <- chroms[ik, 'cumend']
                p <- p + annotate(geom='segment', x=cumstart, xend=cumend, y=0, yend=0, color=colors[ik],lty = 2, size=0.2)# +
        }
	p <- p + theme(text=element_text(size=14,family="ArialNarrow"))
        p <- p + theme(legend.position='none', panel.grid=element_blank(), plot.title = element_text(hjust = 0.5,size=18),panel.background=element_blank(), title=element_text(hjust=0.5), axis.ticks.x=element_line(color='black',size=0.5), text=element_text(size=14),panel.border=element_rect(color='black',size=0.5,fill='transparent')) +
		geom_point(data=df, aes(fakepos, CN, color=chr, group=chr), size=0.1)+# alpha=0.5) +
        scale_color_manual(values=colors[1:gender]) +
        ylab("") + 
		xlab("") + geom_segment(aes(x = fakestart, y = newseg, xend = fakeend, yend = newseg), color='black', data=segments, lty = 1, size=0.3)+
       	ggtitle(args[4])+
		theme(axis.line = element_line(color='black',size=0.3), axis.text.y=element_text(hjust=-1))+
		geom_vline(xintercept = c(0,0),color='black',size=0.3)+
#		geom_hline(yintercept = seq(4,7,1),color='grey',linetype="dotted",size=0.05)+
                geom_hline(yintercept = seq(1,7,1),color='grey',linetype="dotted",size=0.2)
        png(sprintf("%s.png", title_name), width=2400, height=600, res=180)
#	png(sprintf("%s.png", title_name), width=6000, height=1000, res=400)
        print(p)
		dev.off()
}

#main
xfile = args[1]
tb=read.table(xfile,sep="\t",header=1)
gender=dim((distinct(tb["Chromosome"])))[1]
segfile = args[2]

chroms <- chrom_data(gender)
df <- read_reference(xfile)
segments <- read_segments(segfile)
if(gender==24){
	df$chr <- factor(df$chr, levels=paste("chr", c(1:22, "X", "Y"), sep=""))
	df <- df[order(df$chr, df$start), ]
	segments$chrom <- factor(segments$chrom, levels=paste("chr", c(1:22, "X", "Y"), sep=""))
	segments <- segments[order(segments$chrom, segments$loc.start), ]
}else{
	df$chr <- factor(df$chr, levels=paste("chr", c(1:22, "X"), sep=""))
	df <- df[order(df$chr, df$start), ]
	segments$chrom <- factor(segments$chrom, levels=paste("chr", c(1:22, "X"), sep=""))
	segments <- segments[order(segments$chrom, segments$loc.start), ]
}

newdf <- merge(df, chroms[,c('chr', 'cumsum')], by='chr', sort=TRUE)
segments <- merge(segments,chroms, by.x='chrom', by.y='chr')

segments$fakestart = segments$loc.start + segments$cumsum
segments$fakeend = segments$loc.end + segments$cumsum
newdf$fakepos = newdf$start + newdf$cumsum

plot_data(newdf, segments, chroms, args[3],gender)
