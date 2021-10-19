#!/usr/bin/perl -w
use strict;

my $file=$ARGV[0]; ##Nbin文件
my $sp=$ARGV[1]; ##scripts path

# . 点号用于连接两个字符串
my $USEFUL=$sp."/Autosomal_Evenness_Info_FNAN_ChrXY.txt";
my $Rbin=$sp."/hg19_20kb_bin.txt";
my $Equal1=$sp."/Female_Merge_All_Reads_Equal_10M.txt";
my $Equal2=$sp."/Female_Merge_All_Reads_Equal_2M.txt";
my $R2M=$sp."/Autosomal_Mean_SD_Nor_2Mb.txt";
my $R10M=$sp."/Autosomal_Female_Mean_SD_10Mb.txt";

my $s1=$sp."/no_N_no_zero_bin.pl";
system("perl $s1 $USEFUL $file $sp");#输出矫正GC含量后的reads数，去掉没有测到reads的bin
my $o1=$file; $o1=~s/MAPQ60_Nbin.txt$/MAPQ60_Fbin_GC.txt/;

my $s2=$sp."/extract_all_bin.pl";#所有窗口校正后的reads数
system("perl $s2 $o1 $Rbin");
my $o2=$o1; $o2=~s/.txt$/_All.txt/;

my $s3=$sp."/Normalized_Each_Chromosome.pl"; # $Equal1：10M窗口 $o1:_MAPQ60_Fbin_GC.txt
system("perl $s3 $Equal1 $o1"); # 
my $o3=$o1; $o3=~s/.txt$/_Per.txt/; ##

my $s4=$sp."/Merge_2Mb_Bin.pl";
system("perl $s4 $Equal2 $o2");
my $o4=$o2; $o4=~s/.txt$/_Merge.txt/;

my $s5=$sp."/Calculate_Each_Bin_ZScore_CBS.pl";
system("perl $s5 $R2M $o4");
my $o5=$o4; $o5=~s/.txt$/_ZScore.txt/;

my $s6=$sp."/Calculate_ZScore_Percentage.pl";
system("perl $s6 $R10M $o3");
my $o6=$o3; $o6=~s/.txt$/_ZScore.txt/;  ##

my $s7=$sp."/Extract_MicroInDel_Bin_ZScore.pl";
system("perl $s7 $o1 $o3");
my $o7=$o3; $o7=~s/.txt$/_MicroInDel_ZScore.txt/; ##

my $s8=$sp."/FusedLasso.r";
my @tmp=split /\//,$file;
my $o8=$o5; $o8=~s/.txt$/_FLasso_Value.txt/;
my $winfo=`Rscript $s8 $o5 $o8`;

my $s9=$sp."/Extract_FusedLasso_ZScore.pl";
system("perl $s9 $o8");
my $o9=$o8; $o9=~s/.txt$/_Region.txt/;  ##
my $o10=$o8; $o10=~s/.txt$/_FLasso.txt/; ##

my $s10=$sp."/Convert_FLasso_SVG_TO_PNG.pl";
system("perl $s10 $o10");
my $o11=$o10; $o11=~s/.txt$/.html/;  ##
my $o12=$o10; $o12=~s/.txt$/_upload.html/;  ##

my $s11=$sp."/calculate_size_percentage.pl";
my $size=$file; $size=~s/_MAPQ60_Nbin.txt$/_Size_Info.txt/; ##
system("perl $s11 $size");

my $s13=$sp."/Merge_FLasso_CNV_ZS.pl";
system("perl $s13 $o9");
my $o14=$o9; $o14=~s/.txt/_Merge.txt/;

my $s12=$sp."/Extract_MicroInDel_Abnormal_Info.pl";
system("perl $s12 $o14 $o7");
my $o13=$o7; $o13=~s/.txt$/_FLasso_Extract_Abnormal.txt/;

#system("rm $o1");
#system("rm $o2");
#system("rm $o4");
#system("rm $o5");
#system("rm $o8");

