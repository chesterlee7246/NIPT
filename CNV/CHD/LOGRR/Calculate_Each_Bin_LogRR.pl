#!/usr/bin/perl -w
use strict;
use Statistics::Descriptive;

my $gender=$ARGV[3];
my $re=$ARGV[4];

my $mf=$ARGV[0]; ##male mean
my $ff=$ARGV[1]; ##female mean
my $rf="";

if($gender eq "male") 
{
 $rf=$mf;
}
else{
 $rf=$ff;
}

open(RF,$rf);
my %ref=();
while(<RF>)
{
 chomp($_);
 my @tmp=split /\t/,$_;
 if($gender eq "female" && $tmp[0] ne "chrY")
 {
 $ref{$tmp[0]}{$tmp[1]}=$_;
 }
 elsif($gender eq "male")
 {
 $ref{$tmp[0]}{$tmp[1]}=$_;
 }
}
close(RF);


open(FB,$ARGV[2]);
my $to=$ARGV[2];
$to=~s/.txt$/_LogRR.txt/;
open(TO,">$to");
my %chr=();
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
 if($gender eq "female")
 {
 $log{$tmp[0]}{$tmp[1]}=$tmp[2]/$temp[2];
 my $ZS=($tmp[2]-$temp[2])/$temp[3];
 $chr{$tmp[0]}{$tmp[1]}=$ZS;
 }
 elsif($gender eq "male")
 {
  if($tmp[0] ne "chrX" && $tmp[0] ne "chrY")
  {
  $log{$tmp[0]}{$tmp[1]}=$tmp[2]/$temp[2];
  my $ZS=($tmp[2]-$temp[2])/$temp[3];
  $chr{$tmp[0]}{$tmp[1]}=$ZS;
  }
  else{
  $log{$tmp[0]}{$tmp[1]}=(($tmp[2]/$temp[2])+1)/2;
  my $ZS=($tmp[2]-$temp[2])/$temp[3];
  $chr{$tmp[0]}{$tmp[1]}=$ZS;
  }
 }
 if($log{$tmp[0]}{$tmp[1]}!=0)
 {push(@Log,$log{$tmp[0]}{$tmp[1]});}
 }
 #else{
 #$log{$tmp[0]}{$tmp[1]}=0;
 #}
}
close(FB);

my $stat = Statistics::Descriptive::Full->new();
$stat->add_data(@Log);
my $median=$stat->median();
$stat->clear();

my @Chr=();
if($gender eq "male")
{
@Chr=("chr1","chr2","chr3","chr4","chr5","chr6","chr7","chr8","chr9","chr10","chr11","chr12","chr13","chr14","chr15","chr16","chr17","chr18","chr19","chr20","chr21","chr22","chrX","chrY");
}
elsif($gender eq "female")
{
@Chr=("chr1","chr2","chr3","chr4","chr5","chr6","chr7","chr8","chr9","chr10","chr11","chr12","chr13","chr14","chr15","chr16","chr17","chr18","chr19","chr20","chr21","chr22","chrX");
}

open(RE,$re);
my %rebin=();
my %chrL=();
while(<RE>)
{
 my @tmp=split /\t/,$_;
 $chrL{$tmp[0]}+=1;
 $rebin{$tmp[0]}{$chrL{$tmp[0]}}=$_;
}
close(RE);

my $size=20*1000;

print TO "Chromosome	Start	End	LogRR	ZScore\n";

for(my $i=0;$i<=$#Chr;$i++)
{
 foreach my $nums (sort {$a<=>$b} keys %{$log{$Chr[$i]}})
 {

  my $start;
  my $end;
  my @tmp=split /\t/,$rebin{$Chr[$i]}{$nums};
  if($#tmp==5){
  $start=($tmp[3]-1)*$size+1;
  $end=$tmp[4]*$size;}
  else{
  $start=($tmp[1]-1)*$size+1;
  $end=$tmp[1]*$size;
  }
 
  my $label=0;
  if($label==0)
  {
  if($log{$Chr[$i]}{$nums}!=0)
  {
  my $logRR=log($log{$Chr[$i]}{$nums}/$median)/log(2);
  #my $logRR=log($log{$Chr[$i]}{$nums})/log(2);
  if($logRR<-2) {$logRR=-2;}
  elsif($logRR>2) {$logRR=2;}
  print TO "$Chr[$i]	$start	$end	$logRR	$chr{$Chr[$i]}{$nums}\n";
  }
  elsif($log{$Chr[$i]}{$nums}==0 && exists $ref{$Chr[$i]}{$nums})
  {
  print TO "$Chr[$i]	$start	$end	-2	$chr{$Chr[$i]}{$nums}\n";
  }
  elsif($log{$Chr[$i]}{$nums}==0 && !exists $ref{$Chr[$i]}{$nums})
  {
  print TO "$Chr[$i]	$start	$end	NA	NA\n";
  }
  }
  else{
  print TO "$Chr[$i]	$start	$end	NA	NA\n";
  }
 }
}
close(TO);