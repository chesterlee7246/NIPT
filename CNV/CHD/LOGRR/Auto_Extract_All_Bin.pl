#!/usr/bin/perl -w
use strict;

my $f1=$ARGV[0];
my $p2=$ARGV[1];
my $ref=$p2."/hg19_20kb_bin.txt";
my $useful=$p2."/Evenness_Useful_Bin_Filter.txt";
my $re=$p2."/Evenness_Useful_Bin_Filter_Merge_80Kb.txt";


my $file=$f1;

 if($file=~/Nbin.txt$/)
 {
  my $name=$file;
  my $Mratio=`perl $p2/Calculate_ChrM_Autosomal.pl $name`;
  system("perl $p2/no_N_no_zero_bin.pl $useful $name $p2");
  my $gc=$name; $gc=~s/Nbin.txt$/Fbin_GC.txt/;
  my $abin=$gc; $abin=~s/.txt$/_All.txt/;
  system("perl $p2/extract_all_bin.pl $gc $name");
  my $gender=`perl $p2/Calculate_ChrY_Percentage.pl $abin`;
  system("perl $p2/Merge_Bin_From_Reference.pl $re $abin $gender");
  my $t1=$abin; $t1=~s/.txt$/_Merge.txt/;
  my $t2=$t1; $t2=~s/.txt$/_Normalized.txt/;
  system("perl $p2/Calculate_Each_Bin_LogRR.pl $p2/Male_Mean_SD_80Kb_Merge.txt $p2/Female_Mean_SD_80Kb_Merge.txt $t2 $gender $t1");
 }
