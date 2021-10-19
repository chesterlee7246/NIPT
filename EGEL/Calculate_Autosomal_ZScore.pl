#!/usr/bin/perl -w
use strict;#所有变量需要强制声明类型

#my $ref=$ARGV[0];
my $FC=0.01;
my $AFP=0.0000217;
my $MP=0.00170;
my %RM=();
my %RS=();

$RM{"Autosomal"}{"chr1"}=110.0197775; $RS{"Autosomal"}{"chr1"}=0.916831479;
$RM{"Autosomal"}{"chr2"}=118.5149586; $RS{"Autosomal"}{"chr2"}=0.987624655;
$RM{"Autosomal"}{"chr3"}=98.42605693; $RS{"Autosomal"}{"chr3"}=0.820217141;
$RM{"Autosomal"}{"chr4"}=91.64603378; $RS{"Autosomal"}{"chr4"}=0.763716948;
$RM{"Autosomal"}{"chr5"}=87.5698841; $RS{"Autosomal"}{"chr5"}=0.729749034;
$RM{"Autosomal"}{"chr6"}=83.79921018; $RS{"Autosomal"}{"chr6"}=0.698326751;
$RM{"Autosomal"}{"chr7"}=72.56767591; $RS{"Autosomal"}{"chr7"}=0.604730633;
$RM{"Autosomal"}{"chr8"}=71.68274594; $RS{"Autosomal"}{"chr8"}=0.597356216;
$RM{"Autosomal"}{"chr9"}=54.61741406; $RS{"Autosomal"}{"chr9"}=0.455145117;
$RM{"Autosomal"}{"chr10"}=64.47670106; $RS{"Autosomal"}{"chr10"}=0.537305842;
$RM{"Autosomal"}{"chr11"}=64.78488716; $RS{"Autosomal"}{"chr11"}=0.53987406;
$RM{"Autosomal"}{"chr12"}=64.27988296; $RS{"Autosomal"}{"chr12"}=0.535665691;
$RM{"Autosomal"}{"chr13"}=47.98802234; $RS{"Autosomal"}{"chr13"}=0.399900186;
$RM{"Autosomal"}{"chr14"}=43.70655919; $RS{"Autosomal"}{"chr14"}=0.364221327;
$RM{"Autosomal"}{"chr15"}=39.0080682; $RS{"Autosomal"}{"chr15"}=0.325067235;
$RM{"Autosomal"}{"chr16"}=36.74834167; $RS{"Autosomal"}{"chr16"}=0.306236181;
$RM{"Autosomal"}{"chr17"}=36.13559971; $RS{"Autosomal"}{"chr17"}=0.301129998;
$RM{"Autosomal"}{"chr18"}=38.07640199; $RS{"Autosomal"}{"chr18"}=0.31730335;
$RM{"Autosomal"}{"chr19"}=22.89377193; $RS{"Autosomal"}{"chr19"}=0.381562865;
$RM{"Autosomal"}{"chr20"}=30.77290536; $RS{"Autosomal"}{"chr20"}=0.256440878;
$RM{"Autosomal"}{"chr21"}=16.93462926; $RS{"Autosomal"}{"chr21"}=0.14112191;
$RM{"Autosomal"}{"chr22"}=16.09036823; $RS{"Autosomal"}{"chr22"}=0.134086402;
#$RM{"Female"}{"chrX"}=67.89244587; $RS{"Female"}{"chrX"}=0.565770382;
$RM{"Female"}{"chrX"}=67.89244587; $RS{"Female"}{"chrX"}=1.1315407645;
# $RM是各染色体reads平均值数组；$RS是各染色体reads标准差数组


my @chr=("chr1","chr2","chr3","chr4","chr5","chr6","chr7","chr8","chr9","chr10","chr11","chr12","chr13","chr14","chr15","chr16","chr17","chr18","chr19","chr20","chr21","chr22","chrX","chrY");

my $file=$ARGV[0];
my $to=$file; $to=~s/.txt$/_ZScore.txt/;
open(FH,$file);

my %array=();
my $all=0;
my $nums=0;
my $median=0;
my $autosomal=0;
my $ur=0;
my $uchrY=0;
while(<FH>)
{
  chomp($_);#删除换行符
  my @tmp=split /\t/,$_;
  if($_=~/^##MedianReads/) {$median=$tmp[1];}
  elsif($_=~/^##Autosomal/) {$autosomal=$tmp[1];}
  elsif($_=~/^##Unique/) {$ur=$tmp[1];}
  elsif($_=~/^##UChrY/) {$uchrY=$tmp[1];}
  elsif($#tmp==1 && $tmp[0] ne "" && $tmp[1]!=0)
  {
  $array{$tmp[0]}=$tmp[1];
  $nums+=1;
  }
}

close(FH);
$all+=$ur*$median;

if($nums==24){
  open(TO,">$to");
  if($uchrY>=$FC){
  my $fetal=(($array{"chrY"}/$autosomal)-$AFP)/($MP-$AFP);
  my $LchrX=$array{"chrY"}*(-12.45)+67.96;
  my $LchrY=($array{"chrX"}-67.96)/(-12.45);
  my $RX=abs($LchrX-$array{"chrX"});
  my $RY=abs($LchrY-$array{"chrY"});
  print TO "##Gender	Male	$fetal\n";
  print TO "##OriginalChrX	$array{\"chrX\"}\n";
  print TO "##PredictChrX	$LchrX	$RX\n";
  print TO "##OriginalChrY	$array{\"chrY\"}\n";
  print TO "##PredictChrY	$LchrY	$RY\n";

    for(my $i=0;$i<=$#chr-2;$i++)
    {
  my $ZS=($array{$chr[$i]}-$RM{"Autosomal"}{$chr[$i]})/$RS{"Autosomal"}{$chr[$i]};
  print TO "$chr[$i]	$ZS\n";
  }
  }
else{
  print TO "##Gender	Female	NULL\n";
    for(my $i=0;$i<=$#chr-2;$i++)
    {
  my $ZS=($array{$chr[$i]}-$RM{"Autosomal"}{$chr[$i]})/$RS{"Autosomal"}{$chr[$i]};
  print TO "$chr[$i]	$ZS\n";
  }
my $PchrX=$array{"chrX"};
my $ZSX=($PchrX-$RM{"Female"}{"chrX"})/$RS{"Female"}{"chrX"};
print TO "chrX	$ZSX\n";
}
close(TO);
}
