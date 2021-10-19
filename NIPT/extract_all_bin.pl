#!/usr/bin/perl -w
use strict;

open(FH,$ARGV[0]);  ##_Fbin_GC.txt
open(FE,$ARGV[1]);  ##hg19_20_kb
my $to=$ARGV[0]; $to=~s/.txt$/_All.txt/;
open(TO,">$to");

my %chr=();
#创建哈希变量，储存校正后reads数(_Fbin_GC.txt最后一列)到chr变量中
while(<FH>)
{
  next if $_=~/^Chromosome/;
  chomp($_);
  my @tmp=split /\t/,$_;
  $chr{$tmp[0]}{$tmp[1]}=$tmp[$#tmp];
}
close(FH);

#遍历hg19 20kb窗口文件，若chr变量中没有该窗口的key,则reads等于0
while(<FE>)
{
 if($_=~/^##/) {next;}
 else
 {
  chomp($_);
  my @tmp=split /\t/,$_;
  next if $tmp[0]=~/chrM/;
  if(exists $chr{$tmp[0]}{$tmp[1]}) {print TO "$tmp[0]\t$tmp[1]\t$chr{$tmp[0]}{$tmp[1]}\n";}
  #else {print TO "$tmp[0]\t$tmp[1]\t$tmp[$#tmp]\n";}
  else {print TO "$tmp[0]\t$tmp[1]\t0\n";}
  }
}
close(FE);