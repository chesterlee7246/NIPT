#!/usr/bin/perl -w
use strict;

my $rg=$ARGV[0]; ##refGene
my $og=$ARGV[1]; ##omim Gene
my $rf=$ARGV[2]; ##DGV database
my $rfg=$ARGV[3]; ##DGV Gene database
my $f1=$ARGV[4];  ##CNV Results


my $t1=$f1; $t1=~s/.txt$/_DGV_Annotation.txt/;
my $t2=$f1; $t2=~s/.txt$/_DGV_Filted.txt/;
my $t3=$f1; $t3=~s/.txt$/_Aneuploid.txt/;

open(OG,$og);
my %omim=();
while(<OG>)
{
 next if $_=~/^##/;
 my @tmp=split /\t/,$_;
 if(exists $omim{$tmp[3]}) {$omim{$tmp[3]}.=";".$tmp[1] 
 #print $_."\n"; exit(1);
 }
 else{
 $omim{$tmp[3]}=$tmp[1];
 }
}
close(OG);

open(RG,$rg);
my %refGene=();
while(<RG>)
{
 next if $_=~/^name/;
 chomp($_);
 my @tmp=split /\t/,$_;
 if(exists $omim{$tmp[-1]})
 {
  my $tp=$tmp[0]."_".$tmp[2];
  if(exists $refGene{$tmp[1]}{$tp}) {print $_."\n"; exit(1);}
  $refGene{$tmp[1]}{$tp}=$_;
 }
}
close(RG);

open(RFG,$rfg);
my %RFGI=();
while(<RFG>)
{
  chomp($_);
  my @tmp=split /\t/,$_;
  my @temp1=split /\;/,$tmp[0];
  for(my $i=0;$i<=$#temp1;$i++)
  {
   my @temp2=split /\-/,$temp1[$i];
   $RFGI{$temp2[0]}{$temp2[1]}{$temp2[2]}=$tmp[1];
  }
}
close(RFG);

my %dgv=();
open(RF,$rf);

while(<RF>)
{
 next if $_=~/^chrom/;
 chomp($_);
 my @tmp=split /\t/,$_;
 if(exists $dgv{$tmp[0]}{$tmp[3]}){print "##	$tmp[0]	$tmp[1]\n"; exit(1);}
 else{
  $dgv{$tmp[0]}{$tmp[3]}=$_;
 }
}
close(RF);

my @ann=();
my @filted=();
my @aneuploid=();

open(F1,$f1);
while(<F1>)
{
 next if $_=~/^ID/;
 chomp($_);
 my @tmp=split /\t/,$_;
 my $Aper=$tmp[-3];
 if($Aper>=0.95){
 my $ANP=$_."	Aneuploid";
 push(@aneuploid,$ANP); ##aneuploid chromosome
 next;
 }
 else{
 my $chr=$tmp[1];
 my $start=$tmp[2];
 my $end=$tmp[3];
 my $length=$end-$start+1;
 my $RR=2*(2**($tmp[5]));
 my $cnv;
 ##CNV type
 if($RR>2) {$cnv=3;}
 elsif($RR<2) {$cnv=1;}
 
 ##OMIM Gene
 my %Gene=();
 foreach my $id (sort {$a cmp $b} keys %{$refGene{$chr}})
 {
  my @temp=split /\t/,$refGene{$chr}{$id};
  my $p1=$temp[2];  #one coordinate
  my $p2=$temp[3];
  my $gn=$temp[-1];
  if(($p1>=$start && $p2<=$end) || ($p1<=$start && $p2>=$end) || ($p1<=$start && $p2<=$end && $p2>=$start) || ($p1>=$start && $p1<=$end && $p2>=$end))
  {
  $Gene{$gn}+=1;
  }
 }
 my $Gene_observedGains=0;
 my $Gene_observedLosses=0;
 my $GID="";
 my @SGene=();
 if(%Gene){
  my @SGene=sort {$a cmp $b} keys %Gene;
  foreach my $id (sort {$a cmp $b} keys %{$dgv{$chr}})
  {
  my @temp=split /\t/,$dgv{$chr}{$id};
  my $p1=$temp[1]+1; #zero coordinate
  my $p2=$temp[2];
   if(exists $RFGI{$chr}{$p1}{$p2}){
    my @GTMP=split /\;/,$RFGI{$chr}{$p1}{$p2};
	my $gene_consistency=0;
	for(my $ij=0;$ij<=$#GTMP;$ij++)
	{
	 if(exists $Gene{$GTMP[$ij]}){
	 $gene_consistency+=1;
	 }
	}
	my $per1=$gene_consistency/($#SGene+1);
	my $per2=$gene_consistency/($#GTMP+1);
	if($per1>=0.8 && $per2>=0.8){
     $Gene_observedGains+=$temp[-2];
     $Gene_observedLosses+=$temp[-1];
	 if($GID eq "") {$GID=$id;}
	 else {$GID.=";$id";}
	}
   }
  }
 }
 my $observedGains=0;
 my $observedLosses=0;
 my $ID="";
 foreach my $id (sort {$a cmp $b} keys %{$dgv{$chr}})
 {
  my @temp=split /\t/,$dgv{$chr}{$id};
  my $p1=$temp[1]+1;  #zero coordinate
  my $p2=$temp[2];
  my $len=$p2-$p1+1;
  if($p1>=$start && $p2<=$end){
   if(($len/$length)>=0.8) ##80% overlap
   {
   $observedGains+=$temp[-2];
   $observedLosses+=$temp[-1];
   if($ID eq "") {$ID=$id;}
   else {$ID.=";$id";}
   }
  }
  elsif($p1<=$start && $p2>=$end){
   if(($length/$len)>=0.8) ##80% overlap
   {
   $observedGains+=$temp[-2];
   $observedLosses+=$temp[-1];
   if($ID eq "") {$ID=$id;}
   else {$ID.=";$id";}
   }
  }
  elsif($p1<=$start && $p2<=$end && $p2>=$start){
   if(((($p2-$start+1)/$len)>=0.8) && ((($p2-$start+1)/$length)>=0.8)) ##80% overlap
   {
   $observedGains+=$temp[-2];
   $observedLosses+=$temp[-1];
   if($ID eq "") {$ID=$id;}
   else {$ID.=";$id";}
   }
  }
  elsif($p1>=$start && $p1<=$end && $p2>=$end){
  if(((($end-$p1+1)/$len)>=0.8) && ((($end-$p1+1)/$length)>=0.8)) ##80% overlap
  {
   $observedGains+=$temp[-2];
   $observedLosses+=$temp[-1];
   if($ID eq "") {$ID=$id;}
   else {$ID.=";$id";}
  }
  }
 }
 if($cnv==3){
  if($Gene_observedGains>=3 || ($Gene_observedGains>=2 && $Gene_observedLosses>=5)){
  my $info=$_."	DGV_Gene_KNOWN	$Gene_observedGains	$Gene_observedLosses	$GID";
  push(@ann,$info);
  }
  elsif($observedGains>=3 || ($observedGains>=2 && $observedLosses>=5)){
  my $info=$_."	DGV_KNOWN	$observedGains	$observedLosses	$ID";
  push(@ann,$info);
  }
  else{
  push(@filted,$_);
  }
 }
 elsif($cnv==1){
  if($Gene_observedLosses>=3 || ($Gene_observedLosses>=2 && $Gene_observedGains>=5)){
  my $info=$_."	DGV_Gene_KNOWN	$Gene_observedGains	$Gene_observedLosses	$GID";
  push(@ann,$info);
  }
  elsif($observedLosses>=3 || ($observedLosses>=2 && $observedGains>=5)){
  my $info=$_."	DGV_KNOWN	$observedGains	$observedLosses	$ID";
  push(@ann,$info);
  }
  else{
  push(@filted,$_);
  }
 }
  }
}
close(F1);

if(@ann){
 open(T1,">$t1");
 my $info=join "\n",@ann;
 print T1 $info."\n";
 close(T1);
}
if(@filted){
 open(T2,">$t2");
 my $info=join "\n",@filted;
 print T2 $info."\n";
 close(T2);
}
if(@aneuploid){
 open(T3,">$t3");
 my $info=join "\n",@aneuploid;
 print T3 $info."\n";
 close(T3);
}
