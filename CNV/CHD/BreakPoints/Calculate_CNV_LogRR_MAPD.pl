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
  next if $_=~/^ID/;
  if($_=~/^##SD/) {print TO $_;}
  else{
  my @tmp=split /\t/,$_;
  push(@log,$tmp[5]);
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
 $stat->add_data(@sub);
 my $median = $stat->median();
 my $mean = $stat->mean();
 $stat->clear();
 
 print TO "##CNV LogRR MAPD Median	$median\n";
 close(TO);
 print $median;