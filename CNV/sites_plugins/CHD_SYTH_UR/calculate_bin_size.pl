#!/usr/bin/perl -w
use strict;

open(FA,$ARGV[0]);
open(TO,">$ARGV[1]");
my $size=$ARGV[2];

my %hg19=();
my $chr="";
my @chromosome=();
my $i=0;


while(<FA>)
{
 chomp($_);
 if($_=~/^>/) 
 {
  my $tmp=$_;
  $tmp=~s/>//;
  $chr=$tmp;
  $chromosome[$i]=$chr;
  $i++;
 }
 else
 {
 if(exists $hg19{$chr}) {$hg19{$chr}.=$_;}
 else {$hg19{$chr}=$_;}
 }
}
close(FA);

print TO "##Chromosome	Bin Windows(start with 1)	GC Percent	'N' Character Counts\n";

for(my $j=0;$j<=$#chromosome;$j++)
{
 my $length=length($hg19{$chromosome[$j]});
 my $bin=$length/($size*1000);
 if($bin!=int($bin)) {$bin=int($bin)+1;}
 for(my $x=1;$x<=$bin;$x++)
 {
  my $start=($x-1)*($size*1000);
  my $len=$size*1000;
  my $seq=substr($hg19{$chromosome[$j]},$start,$len);
  my $Counts_N=($seq=~tr/N/N/);
  my $Counts_n=($seq=~tr/n/n/);
  my $Counts_Nn=$Counts_N+$Counts_n;
  my $Counts_GC=($seq=~tr/GC/GC/);
  my $Counts_gc=($seq=~tr/gc/gc/);
  my $Counts_GC_gc=$Counts_GC+$Counts_gc;
  my $tmp=length($seq)-$Counts_Nn;
  if($tmp!=0)
  {
  my $tmp_percent=$Counts_GC_gc/$tmp;
  my $percent=sprintf("%.3f",$tmp_percent);
  print TO $chromosome[$j]."\t".$x."\t".$percent."\t".$Counts_Nn."\n";
  }
  else{
  my $percent=sprintf("%.3f",0);
  print TO $chromosome[$j]."\t".$x."\t".$percent."\t".$Counts_Nn."\n";
  }
 }
}
close(TO);