#!/usr/bin/perl -w
use strict;
use Statistics::Descriptive;

open(FH,$ARGV[0]);
my $to=$ARGV[0];
$to=~s/.txt$/_MAPD_INFO.txt/;
open(TO,">$to");

my @log=();
while(<FH>)
{ 
  next if $_=~/^Chromosome/;
  my @tmp=split /\t/,$_;
  if($tmp[3] !~ "NA" && $tmp[0] ne "chrX" && $tmp[0] ne "chrY"){
  push(@log,$tmp[3]);
  }
}
close(FH);

my @sub=();

for(my $i=1;$i<=$#log;$i++)
{
 my $value=abs($log[$i]-$log[$i-1]);
 #my $value=($log[$i]+$log[$i-1]);
 push(@sub,$value);
}

 my $stat = Statistics::Descriptive::Full->new();
 $stat->add_data(@log);
 my $sd = $stat->standard_deviation();
$stat->clear();
 
$stat = Statistics::Descriptive::Full->new();
 $stat->add_data(@sub);
 my $median = $stat->median();
 my $mean = $stat->mean();
 $stat->clear();
 
 print TO "##MAPD Median	$median\n";
 print TO "##LOG SD	$sd\n";
 close(TO);
 print $median;