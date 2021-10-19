#!/usr/bin/perl -w
use strict;

my $filename=$ARGV[0];
my $outpath=$ARGV[1];
my $p1=$ARGV[2];

 my $tmp=$filename;
 my @temp=split /\//,$filename;


if($filename=~/rawlib.basecaller.bam$/)
{
  my $mbam="";
  $mbam=$outpath."/".$temp[$#temp]; $mbam=~s/\/\//\//g;
  $mbam=~s/rawlib.basecaller.bam$/rawlib_Mapping.bam/;
  system("tmap mapall -n 16 -f /home/bioinfo/database/hg19/hg19_rmhap/hg19.fasta -r $filename -v -Y -u --prefix-exclude 5 -o 2 stage1 map4 >$mbam");
  my $sbam=$mbam; $sbam=~s/rawlib_Mapping.bam/rawlib/;
  system("samtools sort $mbam $sbam");
  $sbam.=".bam";
  system("rm $mbam");
  my $bed=$sbam; $bed=~s/bam$/bed/;
  system("bedtools bamtobed -i $sbam >$bed");
  system("rm $sbam");
  my $Ybed=$bed; $Ybed=~s/.bed$/_CYM.bed/;
  system("grep chrY $bed >$Ybed");
  system("rm $bed");
}
elsif($filename=~/rawlib.bam$/)
{
  my $bed="";
  $bed=$outpath."/".$temp[$#temp]; $bed=~s/\/\//\//g; $bed=~s/bam$/bed/;
  system("bedtools bamtobed -i $filename >$bed");
  my $Ybed=$bed; $Ybed=~s/.bed$/_CYM.bed/;
  system("grep chrY $bed >$Ybed");
  system("rm $bed");
}
