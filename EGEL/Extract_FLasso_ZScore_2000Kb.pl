#!/usr/bin/perl -w
use strict;

open(F1,$ARGV[0]); ##FusedLasso Results
my $to=$ARGV[0]; $to=~s/.txt$/_Region.txt/;
open(T1,">$to");

my %LN=(); ##line Normalized
##SZS<->Y  ZS<->X
$LN{"chr1"}="3.416	0.032";
$LN{"chr2"}="3.115	0.014";
$LN{"chr3"}="3.138	-0.026";
$LN{"chr4"}="2.8	0.015";
$LN{"chr5"}="2.756	-0.022";
$LN{"chr6"}="2.736	0.054";
$LN{"chr7"}="2.458	0.022";
$LN{"chr8"}="2.462	-0.034";
$LN{"chr9"}="2.277	0.023";
$LN{"chr10"}="2.374	0.054";
$LN{"chr11"}="2.506	0";
$LN{"chr12"}="2.577	0.018";
$LN{"chr13"}="1.429	-0.013";
$LN{"chr14"}="2.025	0.022";
$LN{"chr15"}="1.995	0.087";
$LN{"chr16"}="1.839	0.015";
$LN{"chr17"}="1.891	0.035";
$LN{"chr18"}="1.311	0.011";
$LN{"chr19"}="3.517	-0.02";
$LN{"chr20"}="1.703	-0.015";
$LN{"chr21"}="0.87	0.005";
$LN{"chr22"}="1.234	-0.028";


print T1 "chrom	loc.start	loc.end	num.mark	seg.mean	FusedLasso	Effective\n";

my @info=();
my $Clabel="";
my $label=0;
while(<F1>)
{
 next if $_=~/^Chromosome/;
 chomp($_);
 my @tmp=split /\t/,$_;
 if($Clabel eq "") {
 $Clabel=$tmp[0];
 $label=$tmp[-1];
 push(@info,$_);
 }
 else{
 if($Clabel eq $tmp[0])
 {
  if($label==$tmp[-1]){
  push(@info,$_);
  }
  else{
  my $start=0;
  my $end=0;
  my $eff=0;
  my $ZS=0;
  for(my $i=0;$i<=$#info;$i++){
  my @itmp=split /\t/,$info[$i];
  if($i==0) {$start=$itmp[1];}
  if($i==$#info) {$end=$itmp[1];}
  $ZS+=$itmp[4];
  $eff+=$itmp[5];
  }
  my $nums=$#info+1; if($nums==0) {print $_."\n", exit();}
  my $avg=$ZS/$nums;
  my $ZScore=$ZS/sqrt($nums);
  my @temp=split /\t/,$LN{$Clabel};
  $ZScore=($ZScore-$temp[1])/$temp[0];
  print T1 "$Clabel	$start	$end	$nums	$avg	$ZScore	$eff\n";
  @info=();
  $label=$tmp[-1];
  push(@info,$_);
  }
 }
 else{
  my $start=0;
  my $end=0;
  my $eff=0;
  my $ZS=0;
  for(my $i=0;$i<=$#info;$i++){
  my @itmp=split /\t/,$info[$i];
  if($i==0) {$start=$itmp[1];}
  if($i==$#info) {$end=$itmp[1];}
  $ZS+=$itmp[4];
  $eff+=$itmp[5];
  }
  my $nums=$#info+1;
  my $avg=$ZS/$nums;
  my $ZScore=$ZS/sqrt($nums);
  my @temp=split /\t/,$LN{$Clabel};
  $ZScore=($ZScore-$temp[1])/$temp[0];
  print T1 "$Clabel	$start	$end	$nums	$avg	$ZScore	$eff\n";
  @info=();
  $label=$tmp[-1];
  $Clabel=$tmp[0];
  push(@info,$_);
 }
 }
}

  my $start=0;
  my $end=0;
  my $eff=0;
  my $ZS=0;
  for(my $i=0;$i<=$#info;$i++){
  my @itmp=split /\t/,$info[$i];
  if($i==0) {$start=$itmp[1];}
  if($i==$#info) {$end=$itmp[1];}
  $ZS+=$itmp[4];
  $eff+=$itmp[5];
  }
  my $nums=$#info+1;
  my $avg=$ZS/$nums;
  my $ZScore=$ZS/sqrt($nums);
  my @temp=split /\t/,$LN{$Clabel};
  $ZScore=($ZScore-$temp[1])/$temp[0];
  print T1 "$Clabel	$start	$end	$nums	$avg	$ZScore	$eff\n";
  close(T1);
  
  open(T1,$to);
  my %hash=();
  my $t2=$ARGV[0]; $t2=~s/.txt$/_FLasso.txt/;
  open(T2,">$t2");
  while(<T1>)
  {
   chomp($_);
   my @tmp=split /\t/,$_;
   $hash{$tmp[0]}{$tmp[1]}{$tmp[2]}=$tmp[-2];
  }
  close(T1);
  
  seek(F1,0,0);
  while(<F1>)
  {
  next if $_=~/^Chromosome/;
  chomp($_);
  my @tmp=split /\t/,$_;
  my $start=$tmp[1];
  foreach my $k1 (sort {$a<=>$b} keys %{$hash{$tmp[0]}})
  {
    foreach my $k2 (sort {$a<=>$b} keys %{$hash{$tmp[0]}{$k1}})
	{
	if($start>=$k1 && $start<=$k2){
	print T2 "$_	$hash{$tmp[0]}{$k1}{$k2}\n";
	}
	}
  }
  }
  close(F1);
  close(T2);
  
  
  
  
