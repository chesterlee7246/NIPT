#!/usr/bin/perl -w
use strict;

my $filename=$ARGV[0];
my $outpath=$ARGV[1];
my $p1=$ARGV[2];

 my $tmp=$filename;
 my @temp=split /\//,$filename;
 my $label=substr($temp[$#temp],0,13);
 

if($filename=~/rawlib.basecaller.bam$/)
{
  my $mbam="";
  $mbam=$outpath."/".$temp[$#temp]; $mbam=~s/\/\//\//g;
  $mbam=~s/rawlib.basecaller.bam$/rawlib_Mapping.bam/;
  system("tmap mapall -n 16 -f /results/referenceLibrary/tmap-f3/hg19/hg19.fasta -r $filename -v -Y -u --prefix-exclude 5 -o 2 stage1 map4 >$mbam");
  my $sbam=$mbam; $sbam=~s/rawlib_Mapping.bam/rawlib/;
  system("samtools sort $mbam $sbam");
  $sbam.=".bam";
  system("rm $mbam");

  my $rbam=$sbam; $rbam=~s/.bam$/_BamDuplicates.bam/;
  my $index=substr($temp[$#temp],0,13);
  my $rmjson2=$index."_BamDuplicates.json";
  system("BamDuplicates -i $sbam -o $rbam -d $outpath -j $rmjson2");
  system("rm $sbam");
  my $rrbam=$rbam; $rrbam=~s/_BamDuplicates.bam$/_rmdup.bam/;
  system("samtools view -F 1024 -b -o $rrbam $rbam");
  system("rm $rbam");
  my $bed=$rrbam; $bed=~s/bam$/bed/;
  system("bedtools bamtobed -i $rrbam >$bed");
  system("rm $rrbam");
  my $s2=$p1."/calculate_mapping_result_from_bed.pl"; $s2=~s/\/\//\//g;
  my $s3=$p1."/calculate_mapping_result_from_bed_10kb.pl"; $s3=~s/\/\//\//g;
  my $db2=$p1."/hg19_10kb_bin.txt"; $db2=~s/\/\//\//g;
#  system("perl $s3 $bed $db2 $bin1 10 10");
  my $db1=$p1."/hg19_20kb_bin.txt"; $db1=~s/\/\//\//g;
  my $MAPQY=10;
  my $bin1;
  for(my $MAPQ=0;$MAPQ<=10;$MAPQ+=10)
  {
  $bin1=$bed; $bin1=~s/\.bed$//;
  $bin1.="_MAPQ".$MAPQ."_Nbin.txt";
  system("perl $s2 $bed $db1 $bin1 $MAPQY $MAPQ");
  }
  my $bin2=$bin1;$bin2=~s/_Nbin.txt$/_10kb_Nbin.txt/;
  system("perl $s3 $bed $db2 $bin2 10 10");
  system("rm $bed");
}
elsif($filename=~/rawlib.bam$/)
{

  my $rbam="";
  $rbam=$outpath."/".$temp[$#temp]; $rbam=~s/\/\//\//g;
  $rbam=~s/.bam$/_BamDuplicates.bam/;
  my $index=substr($temp[$#temp],0,13);
  my $rmjson2=$index."_BamDuplicates.json";
  system("BamDuplicates -i $filename -o $rbam -d $outpath -j $rmjson2");
  my $rrbam=$rbam; $rrbam=~s/_BamDuplicates.bam$/_rmdup.bam/;
  system("samtools view -F 1024 -b -o $rrbam $rbam");
  system("rm $rbam");
  my $bed=$rrbam; $bed=~s/bam$/bed/;
  system("bedtools bamtobed -i $rrbam >$bed");
  system("rm $rrbam");
  my $s2=$p1."/calculate_mapping_result_from_bed.pl"; $s2=~s/\/\//\//g;
  my $s3=$p1."/calculate_mapping_result_from_bed_10kb.pl"; $s3=~s/\/\//\//g;
  my $db2=$p1."/hg19_10kb_bin.txt"; $db2=~s/\/\//\//g;
#  system("perl $s3 $bed $db2 $bin1 10 10");
  my $db1=$p1."/hg19_20kb_bin.txt"; $db1=~s/\/\//\//g;
  my $MAPQY=10;
  my $bin1;
  for(my $MAPQ=0;$MAPQ<=10;$MAPQ+=10)
  {
  $bin1=$bed; $bin1=~s/\.bed$//;
  $bin1.="_MAPQ".$MAPQ."_Nbin.txt";
  system("perl $s2 $bed $db1 $bin1 $MAPQY $MAPQ");
  }
  my $bin2=$bin1;$bin2=~s/_Nbin.txt$/_10kb_Nbin.txt/;
  system("perl $s3 $bed $db2 $bin2 10 10");
#  system("rm $bed");
  open(BED,$bed);
  my $bedto=$bed; $bedto=~s/.bed$/_unique.bed/;
  open(TO,">$bedto");
  my $uni=0;
  while(<BED>)
  {
  chomp($_);
  my @temp=split /\t/,$_;
  my $len=$temp[2]-$temp[1];
  if($temp[4]>=10 && $len>=35)
  {
  $uni+=1;
  print TO $_."\n";
  }
  }
  close(BED);
  close(TO);
  my $s3=$p1."/Calculate_Genome_Coverage.pl"; $s3=~s/\/\//\//g;
  system("perl $s3 $bedto $uni");

  system("rm $bed");

}
