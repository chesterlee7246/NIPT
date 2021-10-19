#!/usr/bin/perl -w
use strict;

my $ref=$ARGV[0];
my $FC=0.00002;
my $AFP=0.000002;
my $MP=0.00173;
my %RM=();
my %RS=();

my @infoX=(-0.0110607054106172,0.165910581159259);
my @infoY=(-0.000674703030047651,0.0101205454507148);

open(REF,$ref);
while(<REF>)
{
 chomp($_);
 my @tmp=split /\t/,$_;
 $RM{$tmp[0]}{$tmp[1]}=$tmp[2];
 $RS{$tmp[0]}{$tmp[1]}=$tmp[3];
}
close(REF);


my @chr=("chr1","chr2","chr3","chr4","chr5","chr6","chr7","chr8","chr9","chr10","chr11","chr12","chr13","chr14","chr15","chr16","chr17","chr18","chr19","chr20","chr21","chr22","chrX","chrY");

  my $file=$ARGV[1];
 if($file=~/MAPQ60_Fbin_GC_Per.txt$/)
 {
 my $name=$file; $name=~s/\/\//\//g;
 my $to=$name; $to=~s/.txt$/_ZScore.txt/;
 open(FH,$name);
  my %array=();
  my $uchrY=0;
  my $nums=0;
  while(<FH>)
  {
   next if $_=~/^##/;
   chomp($_);
   my @tmp=split /\t/,$_;
   if($#tmp==3 && $tmp[0] ne "")
   {
   $array{$tmp[0]}=$tmp[3];
   $nums+=1;
   if($tmp[0] eq "chrY") {$uchrY=$tmp[2];}
   }
  }
  close(FH);

  if($nums==24){
   open(TO,">$to");
   if($uchrY>=$FC){
   my $fetal=($uchrY-$AFP)/($MP-$AFP);
   my $LchrY=$array{"chrX"}*(-0.061)+0.910;
   my $LchrX=($array{"chrY"}-0.910)/(-0.061);
   my $RX=$LchrX-$array{"chrX"};
   my $RY=$LchrY-$array{"chrY"};
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
	 #my $PZX=($RX-$infoX[0])/$infoX[1];
	 my $PZX=($infoX[0]-$RX)/$infoX[1];
     #my $PZY=($RY-$infoY[0])/$infoY[1];
	 my $PZY=($infoY[0]-$RY)/$infoY[1];
	 print TO "chrX	$PZX\n";
	 print TO "chrY	$PZY\n";
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
 }