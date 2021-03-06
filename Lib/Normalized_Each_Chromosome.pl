#!/usr/bin/perl -w
use strict;
use Statistics::Descriptive;

open(REF,$ARGV[0]);# $ARGV[0]表示命令行第一个参数，这里指Female_Merge_All_Reads_Equal_10M.txt

my %reads=();
my %nums=();
while(<REF>)
{
 my @tmp=split /\t/,$_;
 $nums{$tmp[0]}+=1;#统计每条染色体有多少个10M大窗口
 for(my $i=$tmp[1];$i<=$tmp[2];$i++)#统计每条染色体有多少20kb小窗口（i++的用法？）
 {
 $reads{$tmp[0]}{$i}=$nums{$tmp[0]};#10M大窗口数赋值给小窗口，最终结果是chr:10M大窗口:20kb小窗口
 #$reads{chr1}{1-501}=1
 #$reads{chr1}{502-1000}=2
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
open(FH,$name);#打开_MAPQ60_Fbin_GC.txt文件
while(<FH>) {#遍历
    my @tmp=split /\t/,$_;
    if(exists $reads{$tmp[0]}{$tmp[1]}) {#如果有这个bin，则把小窗口矫正后reads累加到大窗口
        $bin{$tmp[0]}{$reads{$tmp[0]}{$tmp[1]}}+=$tmp[$#tmp];
        if($tmp[$#tmp]!=0) {#如果矫正后reads数不为0
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
        }else{
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
  
  my %Reads=();
  my $autosomal=0;
  open(FH,$name);
  while(<FH>)
  {
   next if $_=~/^Chromosome/;
   chomp($_);
   my @tmp=split /\t/,$_;
   $Reads{$tmp[0]}+=$tmp[$#tmp];
   if($tmp[0] ne "chrX" && $tmp[0] ne "chrY"){
    $autosomal+=$tmp[$#tmp];
   }
  }
  close(FH);
  
  my @all5M=();
  for(my $i=0;$i<=$#chr;$i++)
  {
  #add 20190522
  #next if $chr[$i]=~/chr13|chr18|chr21|chrX|chrY|chrM/;
   if(exists $bin{$chr[$i]})
   {
    foreach my $k1 (sort {$a <=> $b} keys %{$bin{$chr[$i]}})
	{
	 if(exists $eff{$chr[$i]}{$k1})
	 {
	 #print TO "$chr[$i]	$k1	$bin{$chr[$i]}{$k1}	$min{$chr[$i]}{$k1}	$max{$chr[$i]}{$k1}	$eff{$chr[$i]}{$k1}\n";
	 push(@all5M,$bin{$chr[$i]}{$k1});
	 }
	 else{
	 #print TO "$chr[$i]	$k1	$bin{$chr[$i]}{$k1}	$min0{$chr[$i]}{$k1}	$max0{$chr[$i]}{$k1}	$eff0{$chr[$i]}{$k1}\n";
	 push(@all5M,$bin{$chr[$i]}{$k1});
	 }
	}
   }
  }
    my $stat = Statistics::Descriptive::Full->new();
    $stat->add_data(@all5M);
    my $median=$stat->median();
    $stat->clear();
  
  my @chromosome=("chr1","chr2","chr3","chr4","chr5","chr6","chr7","chr8","chr9","chr10","chr11","chr12","chr13","chr14","chr15","chr16","chr17","chr18","chr19","chr20","chr21","chr22","chrX","chrY");
  my $to=$name; $to=~s/.txt$/_Per.txt/;
  open(TO,">$to");
  print TO "##Median	$median\n";
  print TO "##autosomal	$autosomal\n";
  for(my $i=0;$i<=$#chromosome;$i++)
  {
  if(exists $Reads{$chromosome[$i]}){
  my $per=$Reads{$chromosome[$i]}/$autosomal;
  my $nor=$Reads{$chromosome[$i]}/$median;
  print TO "$chromosome[$i]	$Reads{$chromosome[$i]}	$per	$nor\n";
  }
  else{
  print TO "$chromosome[$i]	0	0	0\n";
  }
  }
  close(TO);
    

