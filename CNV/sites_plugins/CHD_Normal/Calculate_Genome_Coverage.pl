#!/usr/bin/perl -w
use strict;

 my $bed=$ARGV[0];
 my $uni=$ARGV[1];
 my $depth=$bed; $depth=~s/.bed$/.txt/;
 system("bedtools genomecov -i $bed -bga -split -g /results/referenceLibrary/tmap-f3/hg19/hg19.fasta.fai >$depth");
 open(DP,$depth);
 my $all=2838603846;
 my $cov=0;
 my $per=0;

 while(<DP>)
 {
 chomp($_);
 my @tmp=split /\t/,$_;
 if($tmp[3]!=0) {$cov+=$tmp[2]-$tmp[1];}
 }
 close(DP);
 $per=$cov/$all;
 $per=sprintf("%.4f",$per);
 system("rm $depth");
 system("rm $bed");
 my $Cov=$depth;
 $Cov=~s/.txt$/_Cov.txt/;
 open(TO,">$Cov");
 print TO "Cov	$per\n";
 print TO "Uni	$uni\n";
 close(TO);
