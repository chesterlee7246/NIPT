#!/usr/bin/perl -w
use strict;

my %InDel_Bin=();

$InDel_Bin{"chr1"}{"1"}=643;
$InDel_Bin{"chr15"}{"1138"}=1422;
$InDel_Bin{"chr2"}{"9847"}=10261;
$InDel_Bin{"chr22"}{"951"}=1187;
$InDel_Bin{"chr5"}{"1"}=627;
$InDel_Bin{"chr8"}{"5606"}=6366;



my %mean=();
my %sd=();
my %len=();

$mean{"chr1"}{"1"}=1.298987744;
$mean{"chr15"}{"1138"}=0.518742217;
$mean{"chr2"}{"9847"}=0.894280007;
$mean{"chr22"}{"951"}=0.37106948;
$mean{"chr5"}{"1"}=1.468687306;
$mean{"chr8"}{"5606"}=1.743521465;

$sd{"chr1"}{"1"}=0.021649796;
#$sd{"chr15"}{"1138"}=0.008645704;
$sd{"chr15"}{"1138"}=0.01080713; ##F=0.125
$sd{"chr2"}{"9847"}=0.014904667;
$sd{"chr22"}{"951"}=0.006184491;
$sd{"chr5"}{"1"}=0.024478122;
$sd{"chr8"}{"5606"}=0.029058691;

$len{"chr1"}{"1"}="10001-12840259";
$len{"chr15"}{"1138"}="22749354-28438266";
$len{"chr2"}{"9847"}="196925121-205206939";
$len{"chr22"}{"951"}="19009792-23722445";
$len{"chr5"}{"1"}="10001-12533304";
$len{"chr8"}{"5606"}="112100001-127300000";


  #my $Gbin=$p2."/".$tmp[0]."_rawlib_rmdup_MAPQ60_Fbin_GC.txt";
  #my $GPer=$p2."/".$tmp[0]."_rawlib_rmdup_MAPQ60_Fbin_GC_Per.txt";

my $Gbin=$ARGV[0];
my $GPer=$ARGV[1];
  
if(-e $Gbin && -e $GPer){
open(GC,$Gbin);
my %useful_bin=();

while(<GC>)
{
 next if $_=~/^Chromosome/;
 chomp($_);
 my @tmp=split /\t/,$_;
 if(exists $InDel_Bin{$tmp[0]}){
  foreach my $start (keys %{$InDel_Bin{$tmp[0]}})
  {
  my $end=$InDel_Bin{$tmp[0]}{$start};
  if($tmp[1]>=$start && $tmp[1]<=$end){
  $useful_bin{$tmp[0]}{$tmp[1]}=$tmp[$#tmp];
  }
  }
 }
}
close(GC);

open(PER,$GPer);
my @info=<PER>;
close(PER);
chomp($info[0]);
my @info1=split /\t/,$info[0];
my $median=$info1[1];

my %Nor_Bin=();
foreach my $chr (sort {$a cmp $b} keys %InDel_Bin)
{
 foreach my $start (sort {$a <=> $b} keys %{$InDel_Bin{$chr}})
 {
 my $end=$InDel_Bin{$chr}{$start};
 for(my $i=$start;$i<=$end;$i++)
 {
  if(exists $useful_bin{$chr}{$i}){
  my $value=$useful_bin{$chr}{$i};
  $Nor_Bin{$chr}{$start}+=$value;
  }
 }
 }
}

my $to=$ARGV[1]; $to=~s/.txt$/_MicroInDel_ZScore.txt/;
open(TO,">$to");

foreach my $chr (sort {$a cmp $b} keys %InDel_Bin)
{
 foreach my $start (sort {$a <=> $b} keys %{$InDel_Bin{$chr}})
 {
 if(exists $Nor_Bin{$chr}{$start}){
 my $end=$InDel_Bin{$chr}{$start};
 my $per=$Nor_Bin{$chr}{$start}/$median;
 my $Z=($per-$mean{$chr}{$start})/$sd{$chr}{$start};
 #my $F=2*(abs($Z))*$sd{$chr}{$start}/$mean{$chr}{$start};
 #print "$chr	$start	$end	$len{$chr}{$start}	$per	$Z	$F\n";
 print TO "$chr	$start	$end	$len{$chr}{$start}	$per	$Z\n"
 }
 }
}
close(TO);
}



