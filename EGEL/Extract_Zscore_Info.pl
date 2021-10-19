#!/usr/bin/perl -w
use strict;

my $f1=$ARGV[0];
my $f2=$f1; $f2=~s/_2000Kb_Fbin_GC_All_Normalized_Percentage_ZScore.txt$/_Nbin.txt/;
my $f3=$f1; $f3=~s/_2000Kb_Fbin_GC_All_Normalized_Percentage_ZScore.txt$/_2000Kb_Fbin_GC_All_Normalized_Percentage_ZScore_Predict_ChrXY.txt/;
my $f4=$f1; $f4=~s/.txt$/_All.txt/;
open TO,">$f4" or die;
open(F2,$f2);
my @t1=<F2>;
chomp($t1[0]);
my @tmp=split /\t/,$t1[0];
print TO "##unique	$tmp[1]\n";
close(F2);
if(-e $f3){
open(F1,$f1);
my @t2=<F1>;
chomp($t2[0]);
my @tmp=split /\t/,$t2[0];
print TO "##gender	$tmp[1]\n";
print TO "##concentration	$tmp[2]\n";
for(my $i=5;$i<=26;$i++){print TO $t2[$i];}
close(F1);
open(F3,$f3);
my @t3=<F3>;
print TO $t3[5];
print TO $t3[6];
close(F3);
}
else{
open(F1,$f1);
my @t2=<F1>;
chomp($t2[0]);
my @tmp=split /\t/,$t2[0];
print TO "##gender	$tmp[1]\n";
print TO "##concentration	$tmp[2]\n";
for(my $i=1;$i<=23;$i++){print TO $t2[$i];}
close(F1);
}
close(TO);

