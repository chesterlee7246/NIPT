#!/usr/bin/perl -w
use strict;

open(BED,$ARGV[0]);
open(BIN,$ARGV[1]);
open(TO,">$ARGV[2]");
my $MY=$ARGV[3];
my $MAPQ=$ARGV[4];

my $windows=20;

my @chromosome=("chr1","chr2","chr3","chr4","chr5","chr6","chr7","chr8","chr9","chr10","chr11","chr12","chr13","chr14","chr15","chr16","chr17","chr18","chr19","chr20","chr21","chr22","chrX","chrY","chrM");
my %label=();
for(my $i=0;$i<=$#chromosome;$i++)
{$label{$chromosome[$i]}=1;}

my %bin=();
while(<BIN>)
{
 if($_=~/##/) {next;}
 else
 {
  chomp($_);
  my @tmp=split /\t/,$_;
  my $chr=$tmp[0];
  if(exists $label{$chr})
  {
  my $start=$tmp[1];
  my $percent=$tmp[2];
  $bin{$chr}{$start}=$percent;
  }
 }
}
close(BIN);

my $unique=0;

my %reads=();
while(<BED>)
{
  chomp($_);
  my @temp=split /\t/,$_;
  my $len=$temp[2]-$temp[1];
  if($temp[4]>=$MAPQ && $len>=35 && $temp[0] ne "chrY")
  {
  if(exists $label{$temp[0]})
  {
   my $position=$temp[1];
   my $window=int(($position)/($windows*1000))+1;
   if(exists $bin{$temp[0]}{$window})
   {
    if(exists $reads{$temp[0]}{$window}) {$reads{$temp[0]}{$window}+=1;}
    else{$reads{$temp[0]}{$window}=1;}
    $unique+=1;
   }
  }
  }
  elsif($temp[4]>=$MY && $len>=35 && $temp[0] eq "chrY")
  {
  if(exists $label{$temp[0]})
  {
   my $position=$temp[1];
   my $window=int(($position)/($windows*1000))+1;
   if(exists $bin{$temp[0]}{$window})
   {
    if(exists $reads{$temp[0]}{$window}) {$reads{$temp[0]}{$window}+=1;}
    else{$reads{$temp[0]}{$window}=1;}
    $unique+=1;
   }
  }
  }
}
close(BED);

print TO "##unique reads	$unique\n";
print TO "##Chromosome	Bin Windows(start with 1)	GC Percent	Reads Number\n";

for(my $i=0;$i<=$#chromosome;$i++)
{
 foreach my $key (sort {$a<=>$b} keys %{$bin{$chromosome[$i]}})
 {
  if(exists $reads{$chromosome[$i]}{$key})
  {print TO $chromosome[$i]."\t".$key."\t".$bin{$chromosome[$i]}{$key}."\t".$reads{$chromosome[$i]}{$key}."\n";}
  else
  {print TO $chromosome[$i]."\t".$key."\t".$bin{$chromosome[$i]}{$key}."\t"."0\n";}
 }
}
close(TO);
