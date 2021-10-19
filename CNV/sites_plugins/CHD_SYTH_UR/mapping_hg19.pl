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
  my $outdir=$outpath."/".$label;
  system("mkdir $outdir");
  my $ampliseq_region=$p1."/chrM.bed";
  my $ampliseq_json=$p1."/WGA.json";
  system("/results/plugins/variantCaller/bin/variant_caller_pipeline.py -b $ampliseq_region -p $ampliseq_json -i $sbam -r /results/referenceLibrary/tmap-f3/hg19/hg19.fasta -o $outdir");
  my $vcf=$outdir."/all.merged.vcf";
  my $mvcf=$outdir."/$label"."_ChrM_Region.vcf";
  system("mv $vcf $mvcf");
  my $coverage=$outdir."/$label"."_ChrM_Region_Coverage.txt";
  my $depth=$outdir."/$label"."_ChrM_Region_Depth.txt";
  system("bedtools coverage -abam $sbam -b $ampliseq_region >$coverage");
  system("samtools bedcov $ampliseq_region $sbam >$depth");
  my $zip=$outpath."/ZIP";
  system("cp $mvcf $zip");
  system("cp $coverage $zip");
  system("cp $depth $zip");
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
  my $db1=$p1."/hg19_20kb_bin.txt"; $db1=~s/\/\//\//g;
  my $MAPQY=10;
  for(my $MAPQ=10;$MAPQ<=10;$MAPQ+=10)
  {
  my $bin1=$bed; $bin1=~s/\.bed$//;
  $bin1.="_MAPQ".$MAPQ."_Nbin.txt";
  system("perl $s2 $bed $db1 $bin1 $MAPQY $MAPQ");
  }
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
elsif($filename=~/rawlib.bam$/)
{
   my $outdir=$outpath."/".$label;
  system("mkdir $outdir");
  my $ampliseq_region=$p1."/chrM.bed";
  my $ampliseq_json=$p1."/WGA.json";
  system("/results/plugins/variantCaller/bin/variant_caller_pipeline.py -b $ampliseq_region -p $ampliseq_json -i $filename -r /results/referenceLibrary/tmap-f3/hg19/hg19.fasta -o $outdir");
  my $vcf=$outdir."/all.merged.vcf";
  my $mvcf=$outdir."/$label"."_ChrM_Region.vcf";
  system("mv $vcf $mvcf");
  my $coverage=$outdir."/$label"."_ChrM_Region_Coverage.txt";
  my $depth=$outdir."/$label"."_ChrM_Region_Depth.txt";
  system("bedtools coverage -abam $filename -b $ampliseq_region >$coverage");
  system("samtools bedcov $ampliseq_region $filename >$depth");
  my $zip=$outpath."/ZIP";
  system("cp $mvcf $zip");
  system("cp $coverage $zip");
  system("cp $depth $zip");
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
  my $db1=$p1."/hg19_20kb_bin.txt"; $db1=~s/\/\//\//g;
  my $MAPQY=10;
  for(my $MAPQ=10;$MAPQ<=10;$MAPQ+=10)
  {
  my $bin1=$bed; $bin1=~s/\.bed$//;
  $bin1.="_MAPQ".$MAPQ."_Nbin.txt";
  system("perl $s2 $bed $db1 $bin1 $MAPQY $MAPQ");
  }

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
