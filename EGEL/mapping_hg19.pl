#!/usr/bin/perl -w
use strict;

my $bin=$ARGV[0];
my $p1=$ARGV[1];

  my $db1=$p1."/hg19_20kb_bin.txt"; $db1=~s/\/\//\//g;
  my $s3=$p1."/no_N_no_zero_bin.pl"; $s3=~s/\/\//\//;
  system("perl $s3 $db1 $bin $p1");
  my $gc=$bin; $gc=~s/_Nbin.txt$/_Fbin_GC.txt/;

  my $abin=$gc; $abin=~s/.txt$/_All_Bin.txt/;
  my $s4=$p1."/extract_all_bin_mapping.pl"; $s4=~s/\/\//\//;
  system("perl $s4 $gc $db1 $abin");
  system("rm $gc");

  my $db2=$p1."/Hg19_2000Kb_Bin_New.txt"; $db2=~s/\/\//\//;
  my $s5=$p1."/Merge_20Kb_To_2000Kb.pl"; $s5=~s/\/\//\//;
  system("perl $s5 $db2 $abin");

  my $out=$abin; $out=~s/_Fbin_GC_All_Bin.txt$/_2000Kb_Fbin_GC_All.txt/;
  my $s6=$p1."/Normalized_WGS_Reference.pl"; $s6=~s/\/\//\//;
  system("perl $s6 $out");
  system("rm $abin");
  system("rm $out");

  my $normalized=$out;  $normalized=~s/.txt$/_Normalized.txt/;
  my $per=$normalized; $per=~s/.txt$/_Percentage.txt/;
  my $s7=$p1."/calculate_normalized_bin_percent_autosomal_chromosome.pl"; $s7=~s/\/\//\//;
  system("perl $s7 $normalized $per");
  system("rm $normalized")

