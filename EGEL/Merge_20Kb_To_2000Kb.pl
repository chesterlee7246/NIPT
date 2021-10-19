#!/usr/bin/perl -w
use strict;

open(F1,$ARGV[0]); ##hg19 100Kb GC bin
open(F2,$ARGV[1]); ##20Kb file

my %per=();
while(<F1>)
{
 chomp($_);
 my @tmp=split /\t/,$_;
 $per{$tmp[0]}{$tmp[1]}=$tmp[2];
}
close(F1);

my %reads=();
my $to=$ARGV[1]; $to=~s/_Fbin_GC_All_Bin.txt$/_2000Kb_Fbin_GC_All.txt/;
open(TO,">$to");
while(<F2>)
{
 if($_=~/^##Chromosome/)
 {
  print TO $_;
 }
 else{
 chomp($_);
 my @tmp=split /\t/,$_;
 $reads{$tmp[0]}{$tmp[1]}=$tmp[2];
 }
}
close(F2);

my @chr=("chr1","chr2","chr3","chr4","chr5","chr6","chr7","chr8","chr9","chr10","chr11","chr12","chr13","chr14","chr15","chr16","chr17","chr18","chr19","chr20","chr21","chr22","chrX","chrY");

my $autosomal=0;
for(my $i=0;$i<=$#chr;$i++)
{
 my @array=();
 foreach my $nums (sort {$a <=> $b} keys %{$reads{$chr[$i]}})
 {
  push(@array,$reads{$chr[$i]}{$nums});
 }
 my @merge=();
 for(my $x=0;$x<=$#array;$x+=100)
 {
   my $value=0;
   for(my $j=$x;$j<$x+100;$j++)
   {
   if($j<=$#array) {$value+=$array[$j];}
   }
   push(@merge,$value);
 }
 for(my $x=0;$x<=$#merge;$x++)
 {
 my $j=$x+1;
 print TO "$chr[$i]	$j	$merge[$x]\n";
 }
}
close(TO);