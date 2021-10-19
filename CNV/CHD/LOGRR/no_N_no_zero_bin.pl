#!/usr/bin/perl -w
use strict;

open(FH,$ARGV[0]); ## All_Real_Useful_Bin
open(BIN,$ARGV[1]);
my $to=$ARGV[1];$to=~s/MAPQ10_Nbin.txt$/MAPQ10_Fbin_Autosomal.txt/;
open(TO,">$to");
my $gc=$to; $gc=~s/MAPQ10_Fbin_Autosomal.txt$/MAPQ10_Fbin_GC.txt/;
my $path=$ARGV[2];

my %ref=();
while(<FH>)
{
 if($_=~/^##/) {next;}
 else
 {
  chomp($_);
  my @tmp=split /\t/,$_;
  #if($tmp[3]==0) {$ref{$tmp[0]}{$tmp[1]}=1;}
  $ref{$tmp[0]}{$tmp[1]}=1;
 }
}
close(FH);

print TO "Chromosome	Bin	GC	ReadsNumber\n";
while(<BIN>)
{
 if($_=~/^##/) {next;}
 else
 {
  chomp($_);
  my @tmp=split /\t/,$_;
  if($tmp[0] ne "chrX" && $tmp[0] ne "chrY" && $tmp[0] ne "chrM"){
  if((exists $ref{$tmp[0]}{$tmp[1]}) && ($tmp[3]!=0)) {print TO $_."\n";}
  }
 }
}
close(BIN);
close(TO);

my $s1=$path."/GCBiasCorrect.R"; $s1=~s/\/\//\//;
system("Rscript $s1 $to $gc");

open(GC,$gc);
my %WeightValue=();
while(<GC>)
{
 next if $_=~/^Chromosome/;
 my @tmp=split /\t/,$_;
 $tmp[2]=sprintf("%.3f",$tmp[2]);
 #if($tmp[6]>0 && $tmp[5]<=$TOP) {$WeightValue{$tmp[2]}=$tmp[5];}
 if($tmp[6]>0) {$WeightValue{$tmp[2]}=$tmp[5];}
 else {$WeightValue{$tmp[2]}=1;}
}
close(GC);
system("rm $gc");
system("rm $to");

open(GC,">$gc");
open(BIN,$ARGV[1]);
print GC "Chromosome	Bin	GC	ReadsNumber	WeightValue	RCgc\n";
while(<BIN>)
{
 if($_=~/^##/) {next;}
 else
 {
  chomp($_);
  my @tmp=split /\t/,$_;
  if($tmp[0] ne "chrM"){
  if((exists $ref{$tmp[0]}{$tmp[1]}) && ($tmp[3]!=0)) {
  print GC $_;
  if(exists $WeightValue{$tmp[2]}){
  my $RCgc=$tmp[3]*$WeightValue{$tmp[2]};
  print GC "\t$WeightValue{$tmp[2]}	$RCgc\n";
  }
  else{
  my $RCgc=$tmp[3]*1;
  print GC "\t1	$RCgc\n";
  }
  }
  }
 }
}
close(GC);
close(BIN);
