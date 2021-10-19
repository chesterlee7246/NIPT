#!/usr/bin/perl -w
use strict;

my $file=$ARGV[0];

 if($file=~/Size_Info.txt$/)
 {
  my $name=$file; $name=~s/\/\//\//;
  open(F1,$name);
  my $to=$name; $to=~s/Size_Info.txt$/Size_Info_Percentage.txt/;
  open(T1,">$to");
  my %info=();
  my $all=0;
  while(<F1>)
  {
   next if $_=~/^##/;
   chomp($_);
   my @tmp=split /\t/,$_;
   if($tmp[1]==6 && $tmp[0] ne "chrX" && $tmp[0] ne "chrY" && $tmp[0] ne "chrM"){
    $info{$tmp[2]}+=$tmp[3];
    $all+=$tmp[3];
   }
  }
  close(F1);
  my $A=0;
  my $B=0;
  my $C=0;
  my $D=0;
  my $E=0;
  foreach my $K1 (sort {$a <=> $b} keys %info)
  {
   my $per=$info{$K1}/$all;
   my $len=$K1*5;
   print T1 "$len	$per\n";
   if($len>=115 && $len<=125) {$A+=$per;}
   if($len>=125 && $len<=135) {$B+=$per;}
   if($len>=135 && $len<=145) {$C+=$per;}
   if($len>=130 && $len<=135) {$D+=$per;}
   if($len>=155 && $len<=170) {$E+=$per;}
  }
  #print T1 "[115-130]	$A\n";
  print T1 "[125-140]	$B\n";
  print T1 "[135-150]	$C\n";
  print T1 "[130-140]	$D\n";
  #print T1 "[155-175]	$E\n";
  
##125-140bp y=2.515*x-0.060 R^2=0.862
##135-150bp y=2.063*x-0.121 R^2=0.817
##130-140bp y=3.403*x-0.067 R^2=0.882
  my $fetal=((2.515*$B-0.060)+(2.063*$C-0.121)+(3.403*$D-0.067))/3;
  print T1 "PFetal	$fetal\n";
  close(T1);
 }