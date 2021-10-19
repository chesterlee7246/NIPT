#!/usr/bin/perl -w
use strict;
use Statistics::Descriptive;

open(REF,$ARGV[0]);

my %reads=();
my %nums=();
while(<REF>)
{
 my @tmp=split /\t/,$_;
 $nums{$tmp[0]}+=1;
 for(my $i=$tmp[1];$i<=$tmp[2];$i++)
 {
 $reads{$tmp[0]}{$i}=$nums{$tmp[0]};
 }
}
close(REF);

  my @chr=("chr1","chr2","chr3","chr4","chr5","chr6","chr7","chr8","chr9","chr10","chr11","chr12","chr13","chr14","chr15","chr16","chr17","chr18","chr19","chr20","chr21","chr22");

  my $name=$ARGV[1];
  my %bin=();
  my %min=();
  my %max=();
  my %eff=();
  my %min0=();
  my %max0=();
  my %eff0=();
  open(FH,$name);
  while(<FH>)
  {
   my @tmp=split /\t/,$_;
   if(exists $reads{$tmp[0]}{$tmp[1]})
   {
    $bin{$tmp[0]}{$reads{$tmp[0]}{$tmp[1]}}+=$tmp[$#tmp];
	if($tmp[$#tmp]!=0)
	{
	if(exists $min{$tmp[0]}{$reads{$tmp[0]}{$tmp[1]}}){
	if($min{$tmp[0]}{$reads{$tmp[0]}{$tmp[1]}}>$tmp[1]) {
	$min{$tmp[0]}{$reads{$tmp[0]}{$tmp[1]}}=$tmp[1];
	}
	}
	else{$min{$tmp[0]}{$reads{$tmp[0]}{$tmp[1]}}=$tmp[1];}
	if(exists $max{$tmp[0]}{$reads{$tmp[0]}{$tmp[1]}}){
	if($max{$tmp[0]}{$reads{$tmp[0]}{$tmp[1]}}<$tmp[1]) {
	$max{$tmp[0]}{$reads{$tmp[0]}{$tmp[1]}}=$tmp[1];
	}
	}
	else{$max{$tmp[0]}{$reads{$tmp[0]}{$tmp[1]}}=$tmp[1];}
	$eff{$tmp[0]}{$reads{$tmp[0]}{$tmp[1]}}+=1;
	}
	else
	{
	if(exists $min0{$tmp[0]}{$reads{$tmp[0]}{$tmp[1]}}){
	if($min0{$tmp[0]}{$reads{$tmp[0]}{$tmp[1]}}>$tmp[1]) {
	$min0{$tmp[0]}{$reads{$tmp[0]}{$tmp[1]}}=$tmp[1];
	}
	}
	else{$min0{$tmp[0]}{$reads{$tmp[0]}{$tmp[1]}}=$tmp[1];}
	if(exists $max0{$tmp[0]}{$reads{$tmp[0]}{$tmp[1]}}){
	if($max0{$tmp[0]}{$reads{$tmp[0]}{$tmp[1]}}<$tmp[1]) {
	$max0{$tmp[0]}{$reads{$tmp[0]}{$tmp[1]}}=$tmp[1];
	}
	}
	else{$max0{$tmp[0]}{$reads{$tmp[0]}{$tmp[1]}}=$tmp[1];}
	$eff0{$tmp[0]}{$reads{$tmp[0]}{$tmp[1]}}+=1;
	}
	}
  }
  close(FH);
  
  my @all1M=();
  for(my $i=0;$i<=$#chr;$i++)
  {
   if(exists $bin{$chr[$i]})
   {
    foreach my $k1 (sort {$a <=> $b} keys %{$bin{$chr[$i]}})
	{
	 if(exists $eff{$chr[$i]}{$k1})
	 {
	 push(@all1M,$bin{$chr[$i]}{$k1});
	 }
	 else{
	 push(@all1M,$bin{$chr[$i]}{$k1});
	 }
	}
   }
  }
    my $stat = Statistics::Descriptive::Full->new();
    $stat->add_data(@all1M);
    my $median=$stat->median();
    $stat->clear();

  
  #my $to=$name; $to=~s/.txt$/_Merge.txt/;
  my $to=$ARGV[2];
  print $to."\n";
  open(TO,">$to");
  for(my $i=0;$i<=$#chr;$i++)
  {
   if(exists $bin{$chr[$i]})
   {
    foreach my $k1 (sort {$a <=> $b} keys %{$bin{$chr[$i]}})
	{
	 if(exists $eff{$chr[$i]}{$k1})
	 {
	 my $NorBin=$bin{$chr[$i]}{$k1}/$median;
	 #print TO "$chr[$i]	$k1	$bin{$chr[$i]}{$k1}	$min{$chr[$i]}{$k1}	$max{$chr[$i]}{$k1}	$eff{$chr[$i]}{$k1}\n";
	 print TO "$chr[$i]	$k1	$NorBin	$min{$chr[$i]}{$k1}	$max{$chr[$i]}{$k1}	$eff{$chr[$i]}{$k1}\n";
	 }
	 else{
	 my $NorBin=$bin{$chr[$i]}{$k1}/$median;
	 #print TO "$chr[$i]	$k1	$bin{$chr[$i]}{$k1}	$min0{$chr[$i]}{$k1}	$max0{$chr[$i]}{$k1}	$eff0{$chr[$i]}{$k1}\n";
	 print TO "$chr[$i]	$k1	$NorBin	$min0{$chr[$i]}{$k1}	$max0{$chr[$i]}{$k1}	$eff0{$chr[$i]}{$k1}\n";
	 }
	}
   }
  }
  close(TO);


