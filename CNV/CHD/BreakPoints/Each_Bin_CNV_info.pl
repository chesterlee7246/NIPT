#!/usr/bin/perl -w
use strict;

open(F1,$ARGV[0]);
open(F2,$ARGV[1]);
my $out=$ARGV[1]; $out=~s/.txt$/_Extract_CNV.txt/;
open(T1,">$out");

my %info=();
while(<F1>)
{
 next if $_=~/^ID/;
 next if $_=~/^##/;
 chomp($_);
 my @tmp=split /\t/,$_;
 my $chr=$tmp[1];
 my $start=$tmp[2];
 my $end=$tmp[3];
 $info{$chr}{$start}{$end}=$tmp[5];
}
close(F1);

while(<F2>)
{
 next if $_=~/^Chromosome/;
 chomp($_);
 my @tmp=split /\t/,$_;
 my $print="";
 foreach my $k1 (sort {$a<=>$b} keys %{$info{$tmp[0]}})
 {
  foreach my $k2 (sort {$a<=>$b} keys %{$info{$tmp[0]}{$k1}})
  {
  if($tmp[1]>=$k1 && $tmp[2]<=$k2) {
  if($tmp[3] ne "NA")
  {
  $print="$tmp[0]	$tmp[1]	$tmp[2]	$tmp[3]	$info{$tmp[0]}{$k1}{$k2}\n";
  }
  else{
  $print="$tmp[0]	$tmp[1]	$tmp[2]	$tmp[3]	NA\n";
  }
  }
  }
 }
 if($print eq ""){print T1 "$tmp[0]	$tmp[1]	$tmp[2]	$tmp[3]	NA\n";}
 else {print T1 $print;}
}
close(F2);
close(T1);
