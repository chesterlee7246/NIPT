#!/usr/bin/perl -w
use strict;

my $file=$ARGV[0];
print("file $file\n");

my @infoX=(0.931351435,2.57283066962711);
my @infoY=(0.0748073441963815,0.206653065833503);

my $Index=substr($file,0,13);
open(FH,$file);
my @info=<FH>;
close(FH);
my @tmp=split /\t/,$info[0];
if($tmp[1] eq "Male"){
my $to=$file; $to=~s/.txt/_Predict_ChrXY.txt/;
print("to $to\n");
open(TO,">$to");
print TO "$info[0]$info[1]$info[2]$info[3]$info[4]";
chomp($info[2]);
	my @temp1=split /\t/,$info[2];
chomp($info[4]);
	my @temp2=split /\t/,$info[4];
	my $ZX=($temp1[2]-$infoX[0])/$infoX[1];
	my $ZY=($temp2[2]-$infoY[0])/$infoY[1];
	print TO "chrX	$ZX\n";
	print TO "chrY	$ZY\n";
	close(TO);
}

