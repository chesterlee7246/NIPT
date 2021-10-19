#!/usr/bin/perl -w
use strict;

my $f=$ARGV[0];

my $autosomal=2661263286;
my $chrM=16569;

open(FH,$f);
my $to=$f;
$to=~s/.txt$/_ChrM_Autosomal_Ratio_INFO.txt/;
open(TO,">$to");


my $AR=0;
my $MR=0;
while(<FH>)
{
 next if $_=~/^##/;
 chomp($_);
 my @tmp=split /\t/,$_;
 if($tmp[0] ne "chrX" && $tmp[0] ne "chrY" && $tmp[0] ne "chrM")
 {
  $AR+=$tmp[3];
 }
 elsif($tmp[0] eq "chrM"){
  $MR+=$tmp[3];
 }
}
close(FH);

my $ratio=($MR/$chrM)/($AR/$autosomal);

print TO "##ChrM_Autosomal_Ratio\t".$ratio."\n";
close(TO);
print $ratio;