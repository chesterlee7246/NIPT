#!/usr/bin/perl -w
use strict;

my $dir=$ARGV[0];  ##ARGV[0]:����run�����Ľ��Ŀ¼

my $f1=$ARGV[0]."/expMeta.dat";  ##ARGV[1]������run������Ŀ¼
my $index2id=$ARGV[0]."/index2id.txt";

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
 $hash{$tmp[0]}=$tmp[1]; # if defined $tmp[2] and $tmp[2]=~/egel/i;
 print "$tmp[0] $tmp[1] $tmp[2]\n";
}
close(F2);

opendir(PH,$dir);

while(my $file=readdir(PH))
{
 if($file=~/MAPQ60_2000Kb_Fbin_GC_All_Normalized_Percentage_ZScore_All.txt$/)
 {
  my $out=$dir."/".$file;
  open(ZS,$out);
  my @array=();
  my $unique=0;
  my $index=substr($file,0,13);
  next if not defined $hash{$index};
  my $seqff=$dir."/".$index."_SeqFF_Fetal.txt";
  open(FF,$seqff);
  my $seqFF="";
  while(<FF>)
  {
   if($_=~/PROTON/){
    chomp($_);
	my @tmp=split /\,/,$_;
	$seqFF=sprintf("%.4f",$tmp[-1]);
   }
  }
  close(FF);
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
  if($_=~/^##unique/) {$unique=$tmp[1];}
  elsif($_=~/^##gender/) {$gender=$tmp[1];}
  elsif($_=~/^##concentration/) {$concentration=$tmp[1]; $concentration_real=$tmp[1];
  if($concentration ne "NULL"){
  $concentration=sprintf("%.4f",$concentration); $concentration_real=sprintf("%.4f",$concentration_real);
  if($concentration>0.12) {$seqFF/=2.4;}
  else{
  $seqFF=$concentration;
  }
  }
  else{
  my $Con=$out; $Con=~s/MAPQ60_2000Kb_Fbin_GC_All_Normalized_Percentage_ZScore_All.txt$/Size_Info_Percentage_PFetal.txt/;
  #$concentration=sprintf("%.4f",0.1); #$concentration_real=sprintf("%.4f",0.1);
  $concentration=$seqFF;
  if(-e $Con)
  {
  open(CON,$Con);
  $concentration=<CON>;
  chomp($concentration);
  $concentration=sprintf("%.4f",$concentration);
  close(CON);
  }
  if($seqFF>0.12) {$seqFF/=2.4;}
  }
  }
  else{
  if($tmp[0] ne "chrY"){
   $tmp[1]=sprintf("%.3f",$tmp[1]);
   push(@array,$tmp[1]);
   if(($tmp[1]>=2.58) | ($tmp[1]<=(-2.58))) {$other+=1;}
  }
  else{
  if($gender eq "male"){
  $tmp[1]=sprintf("%.3f",$tmp[1]);
  push(@array,$tmp[1]);
  if(($tmp[1]>=2.58) | ($tmp[1]<=(-2.58))) {$other+=1;}
  }
  else{
  push(@array,"0.000");
  }
  }
  }
  }
  close(ZS);
  my $Nbin10 =$dir."/".$index."_rawlib_rmdup_MAPQ10_Nbin.txt";
  open(Nbin10_Uniq,$Nbin10);
  while(<Nbin10_Uniq>)
  {
   chomp($_);
   my @tmp=split /\t/,$_;
   if($_=~/^##unique/) {$unique=$tmp[1];}
  }
   close(Nbin10_Uniq);
  my $s1=$path."/run_sample_id_info.py";
  $seqFF=sprintf("%.4f",$seqFF);
  print "$run_name $id $ind $unique $array[0] $array[1] $array[2] $array[3] $array[4] $array[5] $array[6] $array[7] $array[8] $array[9] $array[10] $array[11] $array[12] $array[13] $array[14] $array[15] $array[16] $array[17] $array[18] $array[19] $array[20] $array[21] $array[22] $other $concentration $concentration_real $seqFF\n";
  system("python $s1 $run_name $id $ind $unique $array[0] $array[1] $array[2] $array[3] $array[4] $array[5] $array[6] $array[7] $array[8] $array[9] $array[10] $array[11] $array[12] $array[13] $array[14] $array[15] $array[16] $array[17] $array[18] $array[19] $array[20] $array[21] $array[22] $other $concentration $concentration_real $seqFF");
  
  #my $new_lims_upload=$path."/zpush_nipt_id_data.py";
  #$seqFF=sprintf("%.4f",$seqFF);
  #print "python $new_lims_upload $run_name $id $ind $unique $unique $ARGV[0] $array[0] $array[1] $array[2] $array[3] $array[4] $array[5] $array[6] $array[7] $array[8] $array[9] $array[10] $array[11] $array[12] $array[13] $array[14] $array[15] $array[16] $array[17] $array[18] $array[19] $array[20] $array[21] $array[22] $other $concentration $concentration_real $seqFF";
  #system("python $new_lims_upload $run_name $id $ind $unique $unique $ARGV[0] $array[0] $array[1] $array[2] $array[3] $array[4] $array[5] $array[6] $array[7] $array[8] $array[9] $array[10] $array[11] $array[12] $array[13] $array[14] $array[15] $array[16] $array[17] $array[18] $array[19] $array[20] $array[21] $array[22] $other $concentration $concentration_real $seqFF");
 }
}
closedir(PH);
