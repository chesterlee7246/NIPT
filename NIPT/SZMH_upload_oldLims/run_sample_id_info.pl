#!/usr/bin/perl -w
use strict;
use Statistics::Descriptive;

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
 if($file=~/MAPQ60_Fbin_GC_Per_ZScore.txt$/)
 {
  my $out=$dir."/".$file;
  open(ZS,$out);
  my @array=();
  my $unique=0;
  my $index=substr($file,0,13);
  my $id=$hash{$index};
  my $ind=substr($file,11,2);
  if($ind=~/^0/) {$ind=substr($ind,1,1);}
  my $other=0;
  my $concentration=0;
  my $concentration_real=0;
  my $gender="";
  while(<ZS>)
  {
  chomp($_);
  my @tmp=split /\t/,$_;
  if($_=~/^##Gender/) {
  $gender=$tmp[1];
  $concentration=$tmp[2]; 
  $concentration_real=$tmp[2];
  if($concentration ne "NULL"){
  $concentration=sprintf("%.4f",$concentration); $concentration_real=sprintf("%.4f",$concentration_real);}
  else{
  my $Con=$out; $Con=~s/MAPQ60_Fbin_GC_Per_ZScore.txt$/Size_Info_Percentage.txt/;
  open(CON,$Con);
  my @Concentration=<CON>;
  chomp($Concentration[-1]);
  my @Ctmp=split /\t/,$Concentration[-1];
  $concentration=sprintf("%.4f",$Ctmp[-1]);
  close(CON);
  }
  my $Nbin=$out; $Nbin=~s/MAPQ60_Fbin_GC_Per_ZScore.txt$/MAPQ60_Nbin.txt/;
  my $NbinU=$out; $NbinU=~s/MAPQ60_Fbin_GC_Per_ZScore.txt$/MAPQ10_Nbin.txt/;
  open(NB,$NbinU);
  my @NBIN=<NB>;
  chomp($NBIN[0]);
  my @Ntmp=split /\t/,$NBIN[0];
  $unique=$Ntmp[-1];
  close(NB);
  }
  elsif($_=~/^##/) {next;}
  else{
  if($tmp[0] ne "chrY"){
   $tmp[1]=sprintf("%.2f",$tmp[1]);
   push(@array,$tmp[1]);
   if(($tmp[1]>=2.58) | ($tmp[1]<=(-2.58))) {$other+=1;}
  }
  else{
  if($gender eq "Male"){
  $tmp[1]=sprintf("%.2f",$tmp[1]);
  push(@array,$tmp[1]);
  if(($tmp[1]>=2.58) | ($tmp[1]<=(-2.58))) {$other+=1;}
  }
  else{
  push(@array,"0.00");
  }
  }
  }
  }
  close(ZS);
  my $GCF=$out; $GCF=~s/MAPQ60_Fbin_GC_Per_ZScore.txt$/EachChromosomeGC_UR.txt/;
  my $gcv1=0;
  my $gcv2=0;
  if(-e $GCF)
  {
  open(GCF,$GCF);
  my @GCV=();
  while(<GCF>)
  {
   chomp($_);
   if($_=~/^AllGC/){
    my @tmp=split /\t/,$_;
    $gcv1=$tmp[-1]*100;
   }
   else{
   my @tmp=split /\t/,$_;
   push(@GCV,$tmp[-1]);
   }
  }
  close(GCF);
  my $stat = Statistics::Descriptive::Full->new();
  $stat->add_data(@GCV);
  my $mean=$stat->mean();
  my $sd=$stat->standard_deviation();
  $gcv2=($sd/$mean)*100;
  }
  if($gcv1!=0){
  $gcv1=sprintf("%.2f",$gcv1); $gcv1.="%";
  $gcv2=sprintf("%.2f",$gcv2); $gcv2.="%";
  }
  my $s1=$path."/run_sample_id_info.py";
  print "$run_name $id $ind $unique $array[0] $array[1] $array[2] $array[3] $array[4] $array[5] $array[6] $array[7] $array[8] $array[9] $array[10] $array[11] $array[12] $array[13] $array[14] $array[15] $array[16] $array[17] $array[18] $array[19] $array[20] $array[21] $array[22] $other $concentration $concentration_real $gcv1 $gcv2\n";
  system("python $s1 $run_name $id $ind $unique $array[0] $array[1] $array[2] $array[3] $array[4] $array[5] $array[6] $array[7] $array[8] $array[9] $array[10] $array[11] $array[12] $array[13] $array[14] $array[15] $array[16] $array[17] $array[18] $array[19] $array[20] $array[21] $array[22] $other $concentration $concentration_real $gcv1 $gcv2");
 }
}
closedir(PH);
