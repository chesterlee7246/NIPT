#!/usr/bin/perl -w
use strict;

open(F1,$ARGV[0]); ##DNAcopy results
open(F2,$ARGV[1]); ##ZScore File
open(T1,">$ARGV[2]");

my %cnv=();

my $Title="";
my %hash=();
my $label=0;
my $id="";
my %pvalue=();
LINE:while(<F1>)
{
 chomp($_);
 $_=~s/^\s+//;
 if($_=~/^ID/)
 {
 $label+=1;
 my @tmp=split /\s+/,$_;
 $Title=join "\t",@tmp;
 next LINE;
 }
 if($label==1){
 my @tmp=split /\s+/,$_;
 my @temp=();
 for(my $i=1;$i<=$#tmp;$i++) {push(@temp,$tmp[$i]);}
 my $value=join "\t",@temp;
 $hash{$tmp[1]}{$tmp[2]}=$tmp[3];
 $pvalue{$tmp[1]}{$tmp[2]}="$tmp[6]	$tmp[7]	$tmp[8]	$tmp[9]";
 if($id eq "") {$id=$tmp[0];}
 }
}
close(F1);

my $size=20*1000;

my %logRR=();
while(<F2>)
{
 next if $_=~/^Chromosome/;
 chomp($_);
 my @tmp=split /\t/,$_;
 if($tmp[$#tmp] ne "NA"){
 $logRR{$tmp[0]}{$tmp[1]}=$tmp[3];
 }
}
close(F2);

print T1 $Title."\n";
foreach my $k1 (sort {$a cmp $b} keys %hash)
{
  foreach my $k2 (sort {$a <=> $b} keys %{$hash{$k1}})
  {
   my $k3=$hash{$k1}{$k2};
   my $all=0;
   my $value=0;
   for(my $i=$k2;$i<=$k3;$i+=$size)
   {
    if(exists $logRR{$k1}{$i} && $logRR{$k1}{$i} ne "NA"){
	$all+=1;
	$value+=$logRR{$k1}{$i};
	}
   }
   my $mean=$value/$all; $mean=sprintf("%.3f",$mean);
   print T1 "$id	$k1	$k2	$k3	$all	$mean	$pvalue{$k1}{$k2}\n";
  }
}



close(T1);