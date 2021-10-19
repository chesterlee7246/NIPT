#!/usr/bin/perl -w
use strict;
use Statistics::Descriptive;

my $ref=$ARGV[0]; ##reference

open(RF,$ref);
my %ref=();
while(<RF>)
{
 chomp($_);
 my @tmp=split /\t/,$_;
 if($tmp[2]!=0 && $tmp[3]!=0)
 {
 $ref{$tmp[0]}{$tmp[1]}=$_;
 }
}
close(RF);


open(FB,$ARGV[1]);
my $to=$ARGV[1];
$to=~s/.txt$/_ZScore.txt/;
open(TO,">$to");
my %chr=();
my %pos=();
my %log=();
my @Log=();
while(<FB>)
{
 next if $_=~/^##/;
 chomp($_);
 my @tmp=split /\t/,$_;
 if(exists $ref{$tmp[0]}{$tmp[1]})
 {
 my @temp=split /\t/,$ref{$tmp[0]}{$tmp[1]};
 my $ZS=($tmp[2]-$temp[2])/$temp[3];
 $chr{$tmp[0]}{$tmp[1]}=$ZS;
 $pos{$tmp[0]}{$tmp[1]}="$tmp[3]	$tmp[4]	$tmp[5]";
 $log{$tmp[0]}{$tmp[1]}=$tmp[2]/$temp[2];
 push(@Log,$tmp[2]/$temp[2]);
 }
}
close(FB);

 my $stat = Statistics::Descriptive::Full->new();
 $stat->add_data(@Log);
 my $median=$stat->median();
 $stat->clear();

my @Chr=();
@Chr=("chr1","chr2","chr3","chr4","chr5","chr6","chr7","chr8","chr9","chr10","chr11","chr12","chr13","chr14","chr15","chr16","chr17","chr18","chr19","chr20","chr21","chr22");

my $size=20*1000;

print TO "Chromosome	Start	End	RR	ZScore	Effective\n";

for(my $i=0;$i<=$#Chr;$i++)
{
 foreach my $nums (sort {$a<=>$b} keys %{$chr{$Chr[$i]}})
 {
  my @tmp=split /\t/,$pos{$Chr[$i]}{$nums};
  my $start=$tmp[0]*$size+1;
  my $end=$tmp[1]*$size;
  my $eff=$tmp[2]*$size;
  my $RR=$log{$Chr[$i]}{$nums}/$median;
  print TO "$Chr[$i]	$start	$end	$RR	$chr{$Chr[$i]}{$nums}	$eff\n";
 }
}
close(TO);