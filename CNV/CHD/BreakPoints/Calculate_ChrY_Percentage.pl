#!/usr/bin/perl -w
use strict;

my $name=$ARGV[0];

  my $autosomal=0;
  my $chrY=0;
  my $chrX=0;


  open(FH,$name);
  while(<FH>)
  {
   next if $_=~/^##/;
   my @tmp=split /\t/,$_;
   if($tmp[0] ne "chrX" && $tmp[0] ne "chrY" && $tmp[0] ne "chrM")
   {
   $autosomal+=$tmp[2];
   }
   elsif($tmp[0] eq "chrX"){
   $chrX+=$tmp[2];
   }
   elsif($tmp[0] eq "chrY"){
   $chrY+=$tmp[2];
   }
  }
  close(FH);
  my $perX=$chrX/$autosomal;
  my $perY=$chrY/$autosomal;

  my $gender="";
  if($perY>=7.5e-5) {$gender="male";}
  else{$gender="female";}
  print $gender;


