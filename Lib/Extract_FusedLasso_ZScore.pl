#!/usr/bin/perl -w
use strict;

open(F1,$ARGV[0]); ##FusedLasso Results
my $to=$ARGV[0]; $to=~s/.txt$/_Region.txt/;
open(T1,">$to");

my %LN=(); ##line Normalized
##SZS<->Y  ZS<->X
$LN{"chr1"} ="3.437	0.138";  ##chr1  Y=3.437X+0.138 R^2=0.946
$LN{"chr2"} ="3.362	0.148";  ##chr2  Y=3.362X+0.148 R^2=0.897
$LN{"chr3"} ="3.081	0.106";  ##chr3  Y=3.081X+0.106 R^2=0.915
$LN{"chr4"} ="2.778	0.096";  ##chr4  Y=2.778X+0.096 R^2=0.932
$LN{"chr5"} ="2.630	0.093";  ##chr5  Y=2.630X+0.093 R^2=0.925
$LN{"chr6"} ="2.747	0.154";  ##chr6  Y=2.747X+0.154 R^2=0.931
$LN{"chr7"} ="2.454	0.119";  ##chr7  Y=2.454X+0.119 R^2=0.900
$LN{"chr8"} ="2.425	0.041";  ##chr8  Y=2.425X+0.041 R^2=0.916
$LN{"chr9"} ="2.408	0.115";  ##chr9  Y=2.408X+0.115 R^2=0.918
$LN{"chr10"}="2.605	0.173";  ##chr10 Y=2.605X+0.173 R^2=0.945
$LN{"chr11"}="2.403	0.116";  ##chr11 Y=2.403X+0.116 R^2=0.949
$LN{"chr12"}="2.452	0.110";  ##chr12 Y=2.452X+0.110 R^2=0.926
$LN{"chr13"}="1.492	0.084";  ##chr13 Y=1.492X+0.084 R^2=0.947
$LN{"chr14"}="2.041	0.098";  ##chr14 Y=2.041X+0.098 R^2=0.944
$LN{"chr15"}="2.117	0.183";  ##chr15 Y=2.117X+0.183 R^2=0.971
$LN{"chr16"}="1.778	0.092";  ##chr16 Y=1.778X+0.092 R^2=0.976
$LN{"chr17"}="1.866	0.143";  ##chr17 Y=1.866X+0.143 R^2=0.978
$LN{"chr18"}="1.351	0.123";  ##chr18 Y=1.351X+0.123 R^2=0.984
$LN{"chr19"}="1.720	0.016";  ##chr19 Y=1.720X+0.016 R^2=0.993
$LN{"chr20"}="1.737	0.060";  ##chr20 Y=1.737X+0.060 R^2=0.978
$LN{"chr21"}="0.855	0.064";  ##chr21 Y=0.855X+0.064 R^2=0.974
$LN{"chr22"}="1.242	0.020";  ##chr22 Y=1.242X+0.020 R^2=0.979

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
  
  
  
  
