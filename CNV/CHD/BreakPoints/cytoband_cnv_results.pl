#!/usr/bin/perl -w
use strict;

my $f1=$ARGV[0]; ##abnormal merge cnv
my $to=$f1; $to=~s/.txt$/_Cytoband.txt/;
open(TO,">$to");

my %record=();
my %per=();
my %mper=();
my %all=();
my $mosaic=0;
my $mnums=0;
open(F1,$f1);
while(<F1>)
{
 next if $_=~/ID/;
 chomp($_);
 my @tmp=split /\t/,$_;
 if($tmp[5]>0){
 $record{$tmp[1]}{"dup"}+=1;
 if($tmp[-1]==100){
 $per{$tmp[1]}{"dup"}+=$tmp[6];
 }
 else{
 $mper{$tmp[1]}{"dup"}+=$tmp[6];
 }
 $all{$tmp[1]}=$tmp[7];
 }
 elsif($tmp[5]<0){
 $record{$tmp[1]}{"del"}+=1;
 if($tmp[-1]==100){
 $per{$tmp[1]}{"del"}+=$tmp[6];
 }
 else{
 $mper{$tmp[1]}{"del"}+=$tmp[6];
 }
 $all{$tmp[1]}=$tmp[7];
 }
 if($tmp[-1]<100){
 $mosaic+=$tmp[-1];
 $mnums+=1;
 }
}
if($mnums!=0) {$mosaic=int($mosaic/$mnums);}


print TO "ID	chrom	loc.start	loc.end	num.mark	seg.mean	r.BinNums	e.BinNums	r.len	cytoband.region	mosaic.per	loc.per	all.per	cnv.info	mosaic.avg\n";

seek(F1,0,0);

while(<F1>)
{
 next if $_=~/ID/;
 chomp($_);
 my @tmp=split /\t/,$_;
 my $pchr=$tmp[1]; $pchr=~s/^chr//;
 my $info=$tmp[-2];
 my $start=$tmp[2];
 my $end=$tmp[3];
 my $MOSAIC=0;
 if($tmp[-1]<100){
 $MOSAIC=$mosaic;
 }
 else{
 $MOSAIC=100;
 }
 if($tmp[5]>0 && $tmp[-1]==100){
  my $APer=$per{$tmp[1]}{"dup"}/$all{$tmp[1]}; $APer=sprintf("%.3f",$APer);
  my $Per=$tmp[6]/$all{$tmp[1]}; $Per=sprintf("%.3f",$Per);
  my $CNV=3;
  if($APer>=0.95 && !exists $record{$tmp[1]}{"del"})
  {
  if($pchr ne "X" && $pchr ne "Y"){
  print TO "$_	$Per	$APer	+$pchr	$MOSAIC\n";
  }
  else{
  print TO "$_	$Per	$APer	+$pchr	$MOSAIC\n";
  }
  }
  else{
  print TO "$_	$Per	$APer	dup($pchr)($info)\.seq[GRCh37/hg19]($start\-$end)X$CNV	$MOSAIC\n";
  }
 }
 elsif($tmp[5]>0 && $tmp[-1]<100){
  my $APer=$mper{$tmp[1]}{"dup"}/$all{$tmp[1]}; $APer=sprintf("%.3f",$APer);
  my $Per=$tmp[6]/$all{$tmp[1]}; $Per=sprintf("%.3f",$Per);
  my $CNV=3;
  if($APer>=0.95 && !exists $record{$tmp[1]}{"del"})
  {
  if($pchr ne "X" && $pchr ne "Y"){
  print TO "$_	$Per	$APer	+(mosaic)($pchr)	$MOSAIC\n";
  }
  else{
  print TO "$_	$Per	$APer	+(mosaic)($pchr)	$MOSAIC\n";
  }
  }
  else{
  print TO "$_	$Per	$APer	dup(mosaic)($pchr)($info)\.seq[GRCh37/hg19]($start\-$end)X$CNV	$MOSAIC\n";
  }
 }
 elsif($tmp[5]<0 && $tmp[-1]==100){
  my $APer=$per{$tmp[1]}{"del"}/$all{$tmp[1]}; $APer=sprintf("%.3f",$APer);
  my $Per=$tmp[6]/$all{$tmp[1]}; $Per=sprintf("%.3f",$Per);
  my $CNV=1;
  if($APer>=0.95 && !exists $record{$tmp[1]}{"dup"})
  {
  if($pchr ne "X" && $pchr ne "Y"){
  print TO "$_	$Per	$APer	-$pchr	$MOSAIC\n";
  }
  else{
  print TO "$_	$Per	$APer	-$pchr	$MOSAIC\n";
  }
  }
  else{
  print TO "$_	$Per	$APer	del($pchr)($info)\.seq[GRCh37/hg19]($start\-$end)X$CNV	$MOSAIC\n";
  }
 }
 elsif($tmp[5]<0 && $tmp[-1]<100){
  my $APer=$mper{$tmp[1]}{"del"}/$all{$tmp[1]}; $APer=sprintf("%.3f",$APer);
  my $Per=$tmp[6]/$all{$tmp[1]}; $Per=sprintf("%.3f",$Per);
  my $CNV=1;
  if($APer>=0.95 && !exists $record{$tmp[1]}{"dup"})
  {
  if($pchr ne "X" && $pchr ne "Y"){
  print TO "$_	$Per	$APer	-(mosaic)($pchr)	$MOSAIC\n";
  }
  else{
  print TO "$_	$Per	$APer	-(mosaic)($pchr)	$MOSAIC\n";
  }
  }
  else{
  print TO "$_	$Per	$APer	del(mosaic)($pchr)($info)\.seq[GRCh37/hg19]($start\-$end)X$CNV	$MOSAIC\n";
  }
 }
}
close(F1);
close(TO);
