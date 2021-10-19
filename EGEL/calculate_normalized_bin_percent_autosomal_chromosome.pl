#!/usr/bin/perl -w
use strict;

my @chromosome=("chr1","chr2","chr3","chr4","chr5","chr6","chr7","chr8","chr9","chr10","chr11","chr12","chr13","chr14","chr15","chr16","chr17","chr18","chr19","chr20","chr21","chr22","chrX","chrY");
my %label=();
for(my $i=0;$i<=$#chromosome;$i++)
{$label{$chromosome[$i]}=1;}

open(FH,$ARGV[0]);
open(TO,">$ARGV[1]"); 

my %reads=();
my $all=0;
my $ur=0;
my $record=0;
my $uchrY=0;

while(<FH>)
{
if($_=~/^##/) {print TO $_;}
chomp($_);
my @tmp=split /\t/,$_;
if(exists $label{$tmp[0]})
{
 if($tmp[0] ne "chrX" && $tmp[0] ne "chrY")
 {$reads{$tmp[0]}+=$tmp[2];}
 elsif(($tmp[0] eq "chrX") | ($tmp[0] eq "chrY"))
 {$reads{$tmp[0]}+=$tmp[2];}
 if($tmp[0] ne "chrX" && $tmp[0] ne "chrY")
 {$all+=$tmp[2];}
 $ur+=$tmp[2];
  if($tmp[0] eq "chrY"){
   if($tmp[1]==3) {$uchrY+=$tmp[2];}
   elsif($tmp[1]==4) {$uchrY+=$tmp[2];}
   elsif($tmp[1]==8) {$uchrY+=$tmp[2];}
   elsif($tmp[1]==9) {$uchrY+=$tmp[2];}
   elsif($tmp[1]==10) {$uchrY+=$tmp[2];}
   elsif($tmp[1]==11) {$uchrY+=$tmp[2];}
   elsif($tmp[1]==12) {$uchrY+=$tmp[2];}
   elsif($tmp[1]==13) {$uchrY+=$tmp[2];}
   elsif($tmp[1]==15) {$uchrY+=$tmp[2];}
  }
}
}
close(FH);

print TO "##AutosomalReads	$all\n";
print TO "##UniqueReads	$ur\n";
print TO "##UChrY	$uchrY\n";

for(my $i=0;$i<=$#chromosome;$i++)
{
 if(exists $reads{$chromosome[$i]})
 {
 my $percent;
 $percent=$reads{$chromosome[$i]};
 print TO "$chromosome[$i]	$percent\n";
 }
 else{
 print TO "$chromosome[$i]	0\n";
 }
}
close(TO);
