#!/usr/bin/perl -w
use strict;
use Statistics::Descriptive;

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

$mean{"chr1"}{"1"}=0.255878542351416;
$mean{"chr15"}{"1138"}=0.0887677670308976;
$mean{"chr2"}{"9847"}=0.170668278318479;
$mean{"chr22"}{"951"}=0.0652861106081412;
$mean{"chr5"}{"1"}=0.293825699685442;
$mean{"chr8"}{"5606"}=0.390025288253734;

$sd{"chr1"}{"1"}=0.0042646423725236;
$sd{"chr15"}{"1138"}=0.00196008333778157;
$sd{"chr2"}{"9847"}=0.002925564648158;
$sd{"chr22"}{"951"}=0.00175259634944629;
$sd{"chr5"}{"1"}=0.00489709499475737;
$sd{"chr8"}{"5606"}=0.00650042147089557;

$len{"chr1"}{"1"}="10001-12840259";
$len{"chr15"}{"1138"}="22749354-28438266";
$len{"chr2"}{"9847"}="196925121-205206939";
$len{"chr22"}{"951"}="19009792-23722445";
$len{"chr5"}{"1"}="10001-12533304";
$len{"chr8"}{"5606"}="112100001-127300000";

open(GC,$ARGV[0]); ##GC file
my $to=$ARGV[0]; $to=~s/.txt$/_MicroInDel_ZScore.txt/;
open(TO,">$to");

my %useful_bin=();
my @useful=();
my $all=0;
while(<GC>)
{
 chomp($_);
 my @tmp=split /\t/,$_;
 if(exists $InDel_Bin{$tmp[0]}){
  foreach my $start (keys %{$InDel_Bin{$tmp[0]}})
  {
  my $end=$InDel_Bin{$tmp[0]}{$start};
  if($tmp[1]>=$start && $tmp[1]<=$end){
  if($tmp[2]!=0) {push(@useful,$tmp[2]);}
  $useful_bin{$tmp[0]}{$tmp[1]}=$tmp[2];
  }
  }
 }
 if($tmp[0] ne "chrX" && $tmp[1] ne "chrY") {$all+=$tmp[2];}
}
close(GC);

my $stat = Statistics::Descriptive::Full->new();
$stat->add_data(@useful);
my $median = $stat->median();
$stat->clear();

my %Nor_Bin=();
foreach my $chr (sort {$a cmp $b} keys %InDel_Bin)
{
 foreach my $start (sort {$a <=> $b} keys %{$InDel_Bin{$chr}})
 {
 my $end=$InDel_Bin{$chr}{$start};
 for(my $i=$start;$i<=$end;$i++)
 {
  #my $value=$useful_bin{$chr}{$i}/$median;
  my $value=$useful_bin{$chr}{$i};
  $Nor_Bin{$chr}{$start}+=$value;
 }
 }
}

foreach my $chr (sort {$a cmp $b} keys %InDel_Bin)
{
 foreach my $start (sort {$a <=> $b} keys %{$InDel_Bin{$chr}})
 {
 #my $end=$InDel_Bin{$chr}{$start};
 #my $per=$Nor_Bin{$chr}{$start}/$all;
 #my $Z=($per-$mean{$chr}{$start})/$sd{$chr}{$start};
 #print "$chr	$start	$end	$Nor_Bin{$chr}{$start}\n";
 #print "$chr	$start	$end	$per	$Z\n";
 my $Except=0;
 foreach my $chr1 (sort {$a cmp $b} keys %Nor_Bin)
 {
  if($chr1 ne $chr){
  foreach my $start1 (sort {$a <=> $b} keys %{$Nor_Bin{$chr1}})
  {
  $Except+=$Nor_Bin{$chr1}{$start1};
  }
  }
 }
 my $end=$InDel_Bin{$chr}{$start};
 print("Except Except $Except\n");
 my $per=$Nor_Bin{$chr}{$start}/$Except;
 my $Z=($per-$mean{$chr}{$start})/$sd{$chr}{$start};
 print TO "$chr	$start	$end	$len{$chr}{$start}	$per	$Z\n"
 }
}
 