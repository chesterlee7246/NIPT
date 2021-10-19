#!/usr/bin/perl -w
use strict;

my $rg=$ARGV[0]; ##refGene
my $og=$ARGV[1]; ##omim Gene
my $rfds=$ARGV[2]; ##Decipher_Syndrome database
my $rfdsg=$ARGV[3]; ##Decipher_Syndrome Gene database
my $f1=$ARGV[4];  ##CNV Results


my $t1=$f1; $t1=~s/.txt$/_DS_Annotation.txt/;
my $t2=$f1; $t2=~s/.txt$/_DS_Filted.txt/;

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

open(RFG,$rfdsg);
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

my %ds=();
open(RF,$rfds);

while(<RF>)
{
 next if $_=~/^chrom/;
 chomp($_);
 my @tmp=split /\t/,$_;
 if(exists $ds{$tmp[0]}{$tmp[-1]}){print "##	$tmp[0]	$tmp[-1]\n"; exit(1);}
 else{
  $ds{$tmp[0]}{$tmp[-1]}=$_;
 }
}
close(RF);

my @ann=();
my @filted=();

open(F1,$f1);
while(<F1>)
{
 next if $_=~/^ID/;
 chomp($_);
 my @tmp=split /\t/,$_;
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

 my @SGene=();
 my %Glabel=();
 if(%Gene){
  my @SGene=sort {$a cmp $b} keys %Gene;
  foreach my $syndrome (sort {$a cmp $b} keys %{$ds{$chr}})
  {
  my @temp=split /\t/,$ds{$chr}{$syndrome};
  my $p1=$temp[1]; #one coordinate
  my $p2=$temp[2];
  my $dsCNV=$temp[3];
 if(($dsCNV>2 && $cnv>2) || ($dsCNV<2 && $cnv<2)){
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
     my $per=$per1;
	 $Glabel{$syndrome}=$per;
	}
   }
   }
  }
 }
 my %label=();
 foreach my $syndrome (sort {$a cmp $b} keys %{$ds{$chr}})
 {
  my @temp=split /\t/,$ds{$chr}{$syndrome};
  my $p1=$temp[1];  #one coordinate
  my $p2=$temp[2];
  my $len=$p2-$p1+1;
  my $dsCNV=$temp[3];
  if(($dsCNV>2 && $cnv>2) || ($dsCNV<2 && $cnv<2)){
  if($p1>=$start && $p2<=$end){
   if(($len/$length)>=0.8) ##80% overlap
   {
     my $per=$len/$length;
	 $label{$syndrome}=$per;
   }
  }
  elsif($p1<=$start && $p2>=$end){
   if(($length/$len)>=0.8) ##80% overlap
   {
     my $per=$length/$len;
	 $label{$syndrome}=$per;
   }
  }
  elsif($p1<=$start && $p2<=$end && $p2>=$start){
   if(((($p2-$start+1)/$len)>=0.8) && ((($p2-$start+1)/$length)>=0.8)) ##80% overlap
   {
     my $per=($p2-$start+1)/$length;
	 $label{$syndrome}=$per;
   }
  }
  elsif($p1>=$start && $p1<=$end && $p2>=$end){
  if(((($end-$p1+1)/$len)>=0.8) && ((($end-$p1+1)/$length)>=0.8)) ##80% overlap
  {
     my $per=($end-$p1+1)/$length;
	 $label{$syndrome}=$per;
  }
  }
  }
 }
   if(%Glabel){
   my $max=-1;
   my $SYD="";
   foreach my $k1 (sort {$a cmp $b} keys %Glabel)
   {
    if($Glabel{$k1}>$max) {$max=$Glabel{$k1}; $SYD=$k1;}
   }
   $max=sprintf("%.2f",$max);
   my $info=$_."	Decipher_Syndrome_Gene_KNOWN	$max	$SYD";
   push(@ann,$info);
   }
   elsif(%label){
   my $max=-1;
   my $SYD="";
   foreach my $k1 (sort {$a cmp $b} keys %label)
   {
    if($label{$k1}>$max) {$max=$label{$k1}; $SYD=$k1;}
   }
   $max=sprintf("%.2f",$max);
   my $info=$_."	Decipher_Syndrome_KNOWN	$max	$SYD";
   push(@ann,$info);
   }
   else{
   push(@filted,$_);
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
