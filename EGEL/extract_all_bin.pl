#!/usr/bin/perl -w
use strict;

open(FH,$ARGV[0]);#_Fbin_GC.txt
open(FE,$ARGV[1]);#hg19_20kb_bin.txt
open(TO,">$ARGV[2]");#_All_Bin.txt

my %chr=();
#把校正reads数(包括为0的)保存到$chr变量
while(<FH>)
{
  next if $_=~/^Chromosome/;
  chomp($_);
  my @tmp=split /\t/,$_;
  $chr{$tmp[0]}{$tmp[1]}=$tmp[$#tmp];# $#代表取数组的最大索引
}
close(FH);

while(<FE>)
{
  if($_=~/^##/) {next;}
 else
 {
  chomp($_);
  my @tmp=split /\t/,$_;
  next if $tmp[0]=~/chrM/;
  if(exists $chr{$tmp[0]}{$tmp[1]}) {print TO "$tmp[0]\t$tmp[1]\t$chr{$tmp[0]}{$tmp[1]}\n";}
  else {print TO "$tmp[0]\t$tmp[1]\t0\n";}
  }
}
close(FE);