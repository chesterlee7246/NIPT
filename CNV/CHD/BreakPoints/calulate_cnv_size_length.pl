#!/usr/bin/perl -w
use strict;
use Statistics::Descriptive;

open(F1,$ARGV[0]); ##RealCNV file
open(F2,$ARGV[1]); ##LogRR file
open(F5,$ARGV[2]); ##Merge Bin file
open(F3,$ARGV[3]); ##cytoband effective length
open(F4,$ARGV[4]); ##cytoband masker

my %min=();
my %max=();
my %eff=();
while(<F3>)
{
 chomp($_);
 my @tmp=split /\t/,$_;
 $min{$tmp[0]}=$tmp[1];
 $max{$tmp[0]}=$tmp[2];
 $eff{$tmp[0]}=$tmp[3];
}
close(F3);

my %mask=();
while(<F4>)
{
 chomp($_);
 my @tmp=split /\t/,$_;
 $mask{$tmp[0]}{$tmp[1]}=$tmp[2];
}
close(F4);

my $size=20*1000;
my %merge=();
my %Rbin=();
while(<F5>)
{
 next if $_=~/NA/;
 chomp($_);
 my @tmp=split /\t/,$_;
 $merge{$tmp[0]}{$tmp[1]}=$_;
 if(exists $Rbin{$tmp[0]}) {$Rbin{$tmp[0]}+=($tmp[$#tmp]-2);} ##ovalap 2 bins
 else {$Rbin{$tmp[0]}+=($tmp[$#tmp]);}
 #$Rbin{$tmp[0]}+=$tmp[$#tmp];
}
close(F5);

my %chr=();
my %logRR=();
my %NumsBin=();
while(<F2>)
{
 my @tmp=split /\t/,$_;
 $logRR{$tmp[0]}{$tmp[1]}=$tmp[2];
 $chr{$tmp[0]}+=1;
 if(exists $merge{$tmp[0]}{$chr{$tmp[0]}})
 {$NumsBin{$tmp[0]}{$tmp[1]}=$merge{$tmp[0]}{$chr{$tmp[0]}};}
}
close(F2);

 #print "ID	chrom	loc.start	loc.end	num.mark	seg.mean	Runs.p.value	seg.dist	p.mad	p.sd	r.BinNums	e.BinNums	m.len	r.len	e.len\n";
  my @MlogRR=();
  my $print="";
while(<F1>)
{
 next if $_=~/^ID/;
 chomp($_);
 my @tmp=split /\t/,$_;

 my $START="";
 my $END="";
 my $EFF=0;

 for(my $nums=$tmp[2];$nums<=$tmp[3];$nums+=$size)
 {
 if(exists $NumsBin{$tmp[1]}{$nums} && $NumsBin{$tmp[1]}{$nums}!~/NA/){
 my @T=split /\t/,$NumsBin{$tmp[1]}{$nums};
 if($EFF==0) {$EFF+=$T[5];}
 else {$EFF+=$T[5]-2;} ##ovalap 2 bins
 #$EFF+=$T[5];
 if($START eq ""){
 $START=($T[3]-1)*$size+1;
 }
 else{
 if($START>(($T[3]-1)*$size+1)) {$START=($T[3]-1)*$size+1;}
 }
 if($END eq ""){
 $END=$T[4]*$size;
 }
 else{
 if($END<($T[4]*$size)) {$END=$T[4]*$size;}
 }
 }
 }
 if($tmp[2]<$min{$tmp[1]}) {$tmp[2]=$min{$tmp[1]};}
 if($logRR{$tmp[1]}{$tmp[3]}>$max{$tmp[1]}) {$tmp[3]=$max{$tmp[1]};}
 else{$tmp[3]=$logRR{$tmp[1]}{$tmp[3]};}
 if($tmp[2]<$START) {$tmp[2]=$START;}
 if($tmp[3]>$END) {$tmp[3]=$END;}
 my $mask_length=0;
 foreach my $k1 (sort {$a <=>$b} keys %{$mask{$tmp[1]}})
 {
  my $start=$k1;
  my $end=$mask{$tmp[1]}{$k1};
  if($tmp[2]<=$start && $tmp[3]>=$end) {$mask_length+=($end-$start+1);}
  elsif($tmp[2]>=$start && $tmp[3]>=$end && $tmp[2]<=$end) {$mask_length+=($end-$tmp[2]+1);}
  elsif($tmp[2]<=$start && $tmp[3]<=$end && $tmp[3]>=$start) {$mask_length+=($tmp[3]-$start+1);}
  elsif($tmp[2]>=$start && $tmp[3]<=$end) {$mask_length+=($tmp[3]-$tmp[2]+1);}
 }
 my $CNV_Length_1=$tmp[3]-$tmp[2]+1-$mask_length;
 my $CNV_Length_2=$tmp[4]*80000-($tmp[4]-1)*40000;
 my $CNV_Length; if($CNV_Length_1<$CNV_Length_2) {$CNV_Length=$CNV_Length_1;} else {$CNV_Length=$CNV_Length_2;}

 for(my $i=0;$i<=$#tmp;$i++)
 {
  #if($i==0) {print $tmp[$i];}
  #else{print "\t".$tmp[$i];}
  if($i==0) {$print.=$tmp[$i];}
  else{$print.="\t".$tmp[$i];}
 }
 $print.="	$EFF	$Rbin{$tmp[1]}	$mask_length	$CNV_Length	$eff{$tmp[1]}\n";
 push(@MlogRR,$tmp[5]);
 #print "	$EFF	$Rbin{$tmp[1]}	$mask_length	$CNV_Length	$eff{$tmp[1]}\n";
}
close(F1);

my @sort=sort {$a<=>$b} @MlogRR;
my $istart=int(($#sort+1)*0.1);
my $iend=int(($#sort+1)*0.9);
my @trim=();
for(my $i=$istart;$i<=$iend;$i++)
{
 push(@trim,$sort[$i]);
}

 my $stat = Statistics::Descriptive::Full->new();
 #$stat->add_data(@trim);
 $stat->add_data(@sort);
 my $sd = $stat->standard_deviation();
 $stat->clear();
 print "##SD	$sd\n";
 print "ID	chrom	loc.start	loc.end	num.mark	seg.mean	Runs.pvalue	seg.dist	p.mad	p.sd	r.BinNums	e.BinNums	m.len	r.len	e.len\n";
 print $print;