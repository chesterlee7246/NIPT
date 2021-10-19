#!/usr/bin/perl -w

my $f1=$ARGV[0]; ##DNAcopy_Value_Zscore
my $f2=$ARGV[1]; ##MicroIndel_Zscore

my $to=$f2; $to=~s/.txt$/_FLasso_Extract_Abnormal.txt/;
open(TO,">$to");

open(F1,$f1);
while(<F1>)
{
 next if $_=~/^chrom/;
 chomp($_);
 my @tmp=split /\t/,$_;
 my $len=$tmp[-1];
 my $ZS=$tmp[-2];
 my $chr=$tmp[0];
 if($chr ne "chr13" && $chr ne "chr18" && $chr ne "chr21"){
  if(abs($ZS)>=4 && $len>=(10*1000*1000)){
  my $eff=sprintf("%.2f",$len/(1000*1000));
  my $start=$tmp[1];
  my $end=$tmp[2]+20*1000;
  print TO "$chr	$eff"."Mb"."	$start"."-"."$end	$ZS\n";
  }
 }
 else{
  if(($chr eq "chr13" && $tmp[3]==52) | ($chr eq "chr18" && $tmp[3]==42) | ($chr eq "chr21" && $tmp[3]==18))
  {
  if(abs($ZS)>=3 && $len>=(10*1000*1000)){
  my $eff=sprintf("%.2f",$len/(1000*1000));
  my $start=$tmp[1];
  my $end=$tmp[2]+20*1000;
  print TO "$chr	$eff"."Mb"."	$start"."-"."$end	$ZS\n";
  }
  }
  else{
  if(abs($ZS)>=4 && $len>=(10*1000*1000)){
  my $eff=sprintf("%.2f",$len/(1000*1000));
  my $start=$tmp[1];
  my $end=$tmp[2]+20*1000;
  print TO "$chr	$eff"."Mb"."	$start"."-"."$end	$ZS\n";
  }
  }
 }
}
close(F1);

open(F2,$f2);
while(<F2>)
{
 chomp($_);
 my @tmp=split /\t/,$_;
 if(abs($tmp[-1])>=4){
  my @temp=split /\-/,$tmp[3];
  my $len=sprintf("%.2f",(($temp[1]-$temp[0]+1)/(1000*1000)));
  print TO "$tmp[0]	$len"."Mb"."	$tmp[3]	$tmp[-1]\n";
 }else{
  my @temp=split /\-/,$tmp[3];
  my $len=sprintf("%.2f",(($temp[1]-$temp[0]+1)/(1000*1000)));
 	print "$tmp[0] $len"."Mb"."    $tmp[3] $tmp[-1]\n";
 }

}
close(F2);
close(TO);
