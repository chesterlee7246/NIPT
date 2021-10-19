#!/usr/bin/perl -w
use strict;

my $p1=$ARGV[0]; ##file dir
my $f1=$ARGV[0]."/index2id.txt";
my $f2=$ARGV[0]."/expMeta.dat";
my $hospital=$ARGV[1]; ##医院名称
my $binsize=$ARGV[2]; ##分析采用的bin大小
my $bin_dir = $ARGV[3];
#$method=$ARGV[3]; ##检测分类
my $method="CHD"; ##检测分类

my %ID=();
open(IDX,$f1);
while(<IDX>)
{
 chomp($_);
 my @tmp=split /\t/,$_;
 if($tmp[1]=~/^R/){
 $ID{$tmp[0]}=$tmp[1];
 }
}
close(IDX);

my $run="";
open(RN,$f2);
while(<RN>)
{
  if($_=~/^Run Name/){
   $_=~s/\s+//g;
   my @tmp=split /[\_\-\.]/,$_;
   for(my $i=0;$i<=$#tmp;$i++)
   {
    if($tmp[$i]=~/^SQR/) {
    $run=$tmp[$i];
    next;}
   }
  }
}
close(RN);

opendir(P1,$p1);
while(my $file=readdir(P1))
{
 if($file=~/100Kb_Cytoband.txt$/)
 {
  my $index=substr($file,0,13);
  if(exists $ID{$index}){
  my $name=$p1."/".$file; $name=~s/.txt$/_Annotation.txt/;
  if(-e $name){
  print $name."\n";
  system("perl $bin_dir\/CNV_Database_Upload_API.pl $name $hospital $run $ID{$index} $binsize $method");
  }
  else{
  my $name1=$p1."/".$file;
  system("perl $bin_dir\/CNV_Database_Upload_API.pl $name1 $hospital $run $ID{$index} $binsize $method");
  }
  }
 }
}
closedir(P1);
