#!/usr/bin/perl -w
use strict;

open(F1,$ARGV[0]);
my $to=$ARGV[0]; $to=~s/.txt/_Report.txt/;
open(TO,">$to");

my $Mosaic=0;
my $No_Mosaic=0;
while(<F1>)
{
 next if $_=~/^ID/;
 if($_=~/Mosaic/) {$Mosaic+=1;}
 elsif($_!~/Mosaic/) {$No_Mosaic+=1;}
}

my $label=0;
my %Record=();
seek(F1,0,0);
while(<F1>)
{
 if($_=~/^ID/) {print TO $_;}
 else{
  #if($No_Mosaic!=0 && $_=~/Mosaic/) {next;}
  #else{
  my @tmp=split /\t/,$_;
  if($tmp[8]>=(500*1000)){
  print TO $_;
  if($_=~/OMIM/) {
  $label+=1;
  chomp($_);
  my @tmp=split /\t/,$_;
  $Record{$tmp[-1]}+=1;
  }
  }
  else{
   if($_=~/DECIPHER/i || $_=~/ISCA/i){
   print TO $_;
   }
  }
  #}
 }
}
close(F1);
close(TO);

if($label!=0){
 my $f1=$ARGV[0]; $f1=~s/_Annotation.txt$/_OMIM_Annotation_Gene_Function.txt/;
 my $f2=$f1; $f2=~s/.txt/_Report.txt/;
 open(T1,">$f2");
 open(F2,$f1);
 while(<F2>)
 {
  if($_=~/^CNV/) {print T1 $_;}
  else{
  my @tmp=split /\t/,$_;
  if(exists $Record{$tmp[0]}){
  print T1 $_;
  }
  }
 }
 close(F2);
 close(T1);
}
