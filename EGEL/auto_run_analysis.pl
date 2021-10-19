#!/usr/bin/perl -w
#use strict;

my $file=$ARGV[0]; ##Nbin
my $sp=$ARGV[1]; ##scripts path

#from mapping
my $bin=$ARGV[0];
my $p1=$ARGV[1];

my $db1=$p1."/hg19_20kb_bin.txt"; $db1=~s/\/\//\//g;
my $ms3=$p1."/no_N_no_zero_bin.pl"; $ms3=~s/\/\//\//;
system("perl $ms3 $db1 $bin $p1");#输出矫正GC含量后的reads数，去掉没有测到reads的bin
my $gc=$bin; $gc=~s/_Nbin.txt$/_Fbin_GC.txt/;

my $abin=$gc; $abin=~s/.txt$/_All_Bin.txt/;
#my $ms4=$p1."/extract_all_bin_mapping.pl"; $ms4=~s/\/\//\//;
my $ms4=$p1."/extract_all_bin.pl"; $ms4=~s/\/\//\//;
system("perl $ms4 $gc $db1 $abin");
system("rm $gc");

my $db2=$p1."/Hg19_2000Kb_Bin_New.txt"; $db2=~s/\/\//\//;
my $ms5=$p1."/Merge_20Kb_To_2000Kb.pl"; $ms5=~s/\/\//\//;
system("perl $ms5 $db2 $abin");

my $out=$abin; $out=~s/_Fbin_GC_All_Bin.txt$/_2000Kb_Fbin_GC_All.txt/;
my $ms6=$p1."/Normalized_WGS_Reference.pl"; $ms6=~s/\/\//\//;
system("perl $ms6 $out");
system("rm $abin");
system("rm $out");

my $normalized=$out;  $normalized=~s/.txt$/_Normalized.txt/;
my $per=$normalized; $per=~s/.txt$/_Percentage.txt/;
my $ms7=$p1."/calculate_normalized_bin_percent_autosomal_chromosome.pl"; $ms7=~s/\/\//\//;
system("perl $ms7 $normalized $per");
system("rm $normalized");

#common analysis
my $zscore=$per; $zscore=~s/.txt$/_ZScore.txt/;
my $ms8=$p1."/Calculate_Autosomal_ZScore.pl"; $ms8=~s/\/\//\//;
system("perl $ms8 $per");

my $pred=$zscore; $pred=~s/.txt$/_Predict_ChrXY.txt/;
my $ms9=$p1."/Calculate_ChrXY_ZScore.pl"; $ms9=~s/\/\//\//;
system("perl $ms9 $zscore");

my $all=$zscore; $all=~s/.txt$/_All.txt/;
my $ms10=$p1."/Extract_Zscore_Info.pl"; $ms10=~s/\/\//\//;
system("perl $ms10 $zscore");



my $USEFUL=$sp."/Autosomal_Evenness_Info_FNAN_ChrXY.txt";
my $Rbin=$sp."/hg19_20kb_bin.txt";
my $Equal1=$sp."/Female_Merge_All_Reads_Equal_10M.txt";
my $Equal2=$sp."/Female_Merge_All_Reads_Equal_2M.txt";
my $R2M=$sp."/Autosomal_Mean_SD_Nor_2Mb.txt";
my $R10M=$sp."/Autosomal_Female_Mean_SD_10Mb_ssplus_145.txt";

my $E2000kb=$sp."/Female_Merge_2000Kb.txt";

my $R2000kb=$sp."/SZMH_MicroIndel_2000Kb.txt";

my $s1=$sp."/no_N_no_zero_bin_ssplus_145.pl";
system("perl $s1 $USEFUL $file $sp");
my $o1=$file; $o1=~s/MAPQ60_Nbin.txt$/MAPQ60_Fbin_GC.txt/;

my $s2=$sp."/extract_all_bin_ssplus_145.pl";
system("perl $s2 $o1 $Rbin");
my $o2=$o1; $o2=~s/.txt$/_All.txt/;

my $s4=$sp."/Merge_2Mb_Bin.pl";
my $o4=$o2; $o4=~s/.txt$/_2000Kb_Merge.txt/;
system("perl $s4 $E2000kb $o2 $o4");

my $s5=$sp."/Calculate_Each_Bin_ZScore_CBS.pl";
system("perl $s5 $R2000kb $o4");
my $o5=$o4; $o5=~s/.txt$/_ZScore.txt/;

my $s8=$sp."/FusedLasso.r";
my @tmp=split /\//,$file;
my $o8=$o5; $o8=~s/.txt$/_FLasso_Value.txt/;
my $winfo=`Rscript $s8 $o5 $o8`;

my $s9=$sp."/Extract_FLasso_ZScore_2000Kb.pl";
system("perl $s9 $o8");
my $o9=$o8; $o9=~s/.txt$/_Region.txt/;  ##
my $o10=$o8; $o10=~s/.txt$/_FLasso.txt/; ##

my $s10=$sp."/Convert_FLasso_SVG_TO_PNG.pl";
system("perl $s10 $o10");
my $o11=$o10; $o11=~s/.txt$/.html/;  ##
my $o12=$o10; $o12=~s/.txt$/_upload.html/;  ##


my $s13=$sp."/Merge_FLasso_CNV_ZS.pl";
system("perl $s13 $o9");
my $o14=$o9; $o14=~s/.txt/_Merge.txt/;

my $s7=$sp."/Extract_MicroInDel_Bin_ZScore_ssplus_145.pl";
system("perl $s7 $o2");
my $o7=$o2; $o7=~s/.txt$/_MicroInDel_ZScore.txt/; ##

my $s12=$sp."/Extract_MicroInDel_Abnormal_Info.pl";
system("perl $s12 $o14 $o7");
my $o13=$o7; $o13=~s/.txt$/_FLasso_Extract_Abnormal.txt/;
