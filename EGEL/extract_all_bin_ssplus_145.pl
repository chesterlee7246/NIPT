#!/usr/bin/perl -w
use strict;

open(FH,$ARGV[0]);  ##GC bin file
open(FE,$ARGV[1]);  ##hg19_20_kb
my $to=$ARGV[0]; $to=~s/.txt$/_All.txt/;
open(TO,">$to");

my %chr=();

while(<FH>)
{
  next if $_=~/^Chromosome/;
  chomp($_);
  my @tmp=split /\t/,$_;
  $chr{$tmp[0]}{$tmp[1]}=$tmp[$#tmp];
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
  #else {print TO "$tmp[0]\t$tmp[1]\t$tmp[$#tmp]\n";}
  else {print TO "$tmp[0]\t$tmp[1]\t0\n";}
  }
}
close(FE);