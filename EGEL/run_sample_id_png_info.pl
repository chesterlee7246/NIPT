#!/usr/bin/perl -w
use strict;

my $dir=$ARGV[0];  ##ARGV[0]:运行run产生的结果目录

my $f1=$ARGV[0]."/expMeta.dat";  ##ARGV[1]：运行run产生根目录
my $index2id=$dir."/index2id.txt";

my $path=$ARGV[1]; ##脚本目录

open(F1,$f1);
my $run_name="";
while(<F1>)
{
  if($_=~/^Run Name/){
   $_=~s/\s+//g;
   my @tmp=split /[\_\-\.]/,$_;
   for(my $i=0;$i<=$#tmp;$i++)
   {
    if($tmp[$i]=~/^SQR/) {
    $run_name=$tmp[$i];
    next;}
   }
  }
}
close(F1);

open(F2,$index2id);
my %hash=();
while(<F2>)
{
 chomp($_);
 my @tmp=split /\t/,$_;
 $hash{$tmp[0]}=$tmp[1];
}
close(F2);

opendir(PH,$dir);

while(my $file=readdir(PH))
{
 if($file=~/MAPQ60_Fbin_GC_All_2000Kb_Merge_ZScore_FLasso_Value_FLasso_upload.html$/)
 {
  my $out=$dir."/".$file;
  my $index=substr($file,0,13);
  my $id=$hash{$index};
  my $ind=substr($file,11,2);
  if($ind=~/^0/) {$ind=substr($ind,1,1);}
  my $s1=$path."/run_sample_id_png_info.py";
  system("python $s1 $run_name $id $ind $out");
  #system("rm $out");
 }
}
closedir(PH);
