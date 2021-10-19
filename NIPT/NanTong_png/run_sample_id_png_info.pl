#!/usr/bin/perl -w
use strict;

my $dir=$ARGV[0];  ##ARGV[0]:����run�����Ľ��Ŀ¼

my $f1=$ARGV[0]."/expMeta.dat";  ##ARGV[1]������run������Ŀ¼
my $index2id=$dir."/index2id.txt";

my $path=$ARGV[1]; ##�ű�Ŀ¼

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
 if($file=~/MAPQ60_Fbin_GC_All_Merge_ZScore_FLasso_Value_FLasso.html$/)
 {
  my $index=substr($file,0,13);
  my $id=$hash{$index};
  next if not defined  $hash{$index};
  my $out=$dir."/".$file;
  my $pd=$path."/PNG_Q20";
  system("perl $pd/upload_scatterpoints.pl $out $pd");
 }
}
closedir(PH);
