#!/usr/bin/perl -w
use strict;

my $rg=$ARGV[0]; ##refGene
my $og=$ARGV[1]; ##omim Gene
my $rfd=$ARGV[2]; ##Decipher database
my $rfdg=$ARGV[3]; ##Decipher Gene database
my $rfi=$ARGV[4]; ##ISCA database
my $rfig=$ARGV[5]; ##ISCA Gene database
my $f1=$ARGV[6];  ##CNV Results


my $t1=$f1; $t1=~s/.txt$/_DI_Annotation.txt/;
my $t2=$f1; $t2=~s/.txt$/_DI_Filted.txt/;

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

my %decipher=();
open(RF1,$rfd);

while(<RF1>)
{
 next if $_=~/^DECIPHER/;
 chomp($_);
 my @tmp=split /\t/,$_;
 my $chr="chr".$tmp[1];
 my $id=$tmp[2]."_".$tmp[3]."_".$tmp[0]."_".$tmp[6]."_".$tmp[7];
 if(exists $decipher{$chr}{$id} && ($decipher{$chr}{$id} ne $_)){print "##DECIPHER	$chr	$id\n"; exit(1);}
 else{
  $decipher{$chr}{$id}=$_;
 }
}
close(RF1);

my %isca=();
open(RF2,$rfi);

while(<RF2>)
{
 next if $_=~/^chrom/;
 chomp($_);
 my @tmp=split /\t/,$_;
 my $chr=$tmp[0];
 my $id=$tmp[1]."_".$tmp[2]."_".$tmp[3];
 if(exists $isca{$chr}{$id} && ($isca{$chr}{$id} ne $_)){print "##ISCA	$chr	$id\n"; exit(1);}
 else{
  $isca{$chr}{$id}=$_;
 }
}
close(RF2);

open(RFG1,$rfdg);
my %RFDG=();
while(<RFG1>)
{
  chomp($_);
  my @tmp=split /\t/,$_;
  my @temp1=split /\;/,$tmp[0];
  for(my $i=0;$i<=$#temp1;$i++)
  {
   my @temp2=split /\-/,$temp1[$i];
   $RFDG{$temp2[0]}{$temp2[1]}{$temp2[2]}=$tmp[1];
  }
}
close(RFG1);

open(RFG2,$rfig);
my %RFIG=();
while(<RFG2>)
{
  chomp($_);
  my @tmp=split /\t/,$_;
  my @temp1=split /\;/,$tmp[0];
  for(my $i=0;$i<=$#temp1;$i++)
  {
   my @temp2=split /\-/,$temp1[$i];
   $RFIG{$temp2[0]}{$temp2[1]}{$temp2[2]}=$tmp[1];
  }
}
close(RFG2);


my @ann=();
my @filted=();
my @aneuploid=();

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
 my %Dlabel=();
 my %Ilabel=();
 if(%Gene){
  my @SGene=sort {$a cmp $b} keys %Gene;
  foreach my $id (sort {$a cmp $b} keys %{$decipher{$chr}})
  {
  my @temp=split /\t/,$decipher{$chr}{$id};
  my $deCNV=$temp[-1];
  my $p1=$temp[2];  #one coordinate
  my $p2=$temp[3];
  if(($cnv>2 && $deCNV eq "copy_number_gain") || ($cnv<2 && $deCNV eq "copy_number_loss")){
   if(exists $RFDG{$chr}{$p1}{$p2}){
    my @GTMP=split /\;/,$RFDG{$chr}{$p1}{$p2};
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
	 $Dlabel{$decipher{$chr}{$id}}=$per;
	}
   }
   }
  }
  foreach my $id (sort {$a cmp $b} keys %{$isca{$chr}})
  {
  my @temp=split /\t/,$isca{$chr}{$id};
  my $deCNV=$temp[4];
  my $p1=$temp[1];  #one coordinate
  my $p2=$temp[2];
  if(($cnv>2 && $deCNV eq "copy_number_gain") || ($cnv<2 && $deCNV eq "copy_number_loss")){
   if(exists $RFIG{$chr}{$p1}{$p2}){
    my @GTMP=split /\;/,$RFIG{$chr}{$p1}{$p2};
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
	 $Ilabel{$isca{$chr}{$id}}=$per;
	}
   }
   }
  }
 }
 my %dlabel=();
 foreach my $id (sort {$a cmp $b} keys %{$decipher{$chr}})
 {
  my @temp=split /\t/,$decipher{$chr}{$id};
 my $deCNV=$temp[-1];
 my $p1=$temp[2];  #one coordinate
 my $p2=$temp[3];
 my $len=$p2-$p1+1;
   if(($cnv>2 && $deCNV eq "copy_number_gain") || ($cnv<2 && $deCNV eq "copy_number_loss")){
  if($p1>=$start && $p2<=$end){
   if(($len/$length)>=0.8) ##80% overlap
   {
     my $per=$len/$length;
	 $dlabel{$decipher{$chr}{$id}}=$per;
   }
  }
  elsif($p1<=$start && $p2>=$end){
   if(($length/$len)>=0.8) ##80% overlap
   {
     my $per=$length/$len;
	 $dlabel{$decipher{$chr}{$id}}=$per;
   }
  }
  elsif($p1<=$start && $p2<=$end && $p2>=$start){
   if(((($p2-$start+1)/$len)>=0.8) && ((($p2-$start+1)/$length)>=0.8)) ##80% overlap
   {
     my $per=($p2-$start+1)/$length;
	 $dlabel{$decipher{$chr}{$id}}=$per;
   }
  }
  elsif($p1>=$start && $p1<=$end && $p2>=$end){
  if(((($end-$p1+1)/$len)>=0.8) && ((($end-$p1+1)/$length)>=0.8)) ##80% overlap
  {
     my $per=($end-$p1+1)/$length;
	 $dlabel{$decipher{$chr}{$id}}=$per;
  }
  }
  }
 }
 
 my %ilabel=();
 foreach my $id (sort {$a cmp $b} keys %{$isca{$chr}})
 {
  my @temp=split /\t/,$isca{$chr}{$id};
  my $deCNV=$temp[4];
  my $p1=$temp[1];  #one coordinate
  my $p2=$temp[2];
  my $len=$p2-$p1+1;
   if(($cnv>2 && $deCNV eq "copy_number_gain") || ($cnv<2 && $deCNV eq "copy_number_loss")){
  if($p1>=$start && $p2<=$end){
   if(($len/$length)>=0.8) ##80% overlap
   {
     my $per=$len/$length;
	 $ilabel{$isca{$chr}{$id}}=$per;
   }
  }
  elsif($p1<=$start && $p2>=$end){
   if(($length/$len)>=0.8) ##80% overlap
   {
     my $per=$length/$len;
	 $ilabel{$isca{$chr}{$id}}=$per;
   }
  }
  elsif($p1<=$start && $p2<=$end && $p2>=$start){
   if(((($p2-$start+1)/$len)>=0.8) && ((($p2-$start+1)/$length)>=0.8)) ##80% overlap
   {
     my $per=($p2-$start+1)/$length;
	 $ilabel{$isca{$chr}{$id}}=$per;
   }
  }
  elsif($p1>=$start && $p1<=$end && $p2>=$end){
  if(((($end-$p1+1)/$len)>=0.8) && ((($end-$p1+1)/$length)>=0.8)) ##80% overlap
  {
     my $per=($end-$p1+1)/$length;
	 $ilabel{$isca{$chr}{$id}}=$per;
  }
  }
  }
 }
   my $info="";
   my $record=0;
   if(%Dlabel){
   $record+=1;
   my $max=-1;
   my $SYD="";
   my %full_info=();
   foreach my $k1 (sort {$a cmp $b} keys %Dlabel)
   {
    push $fullinfo{Decipher_Gene_KNOWN},$k1."_$max";
    if($Dlabel{$k1}>$max) {$max=$Dlabel{$k1}; $SYD=$k1;}
   }
   my @TEMP=split /\t/,$SYD;
   if($max>1) {$max=1.00;}
   $max=sprintf("%.2f",$max);
   $info=$_."	Decipher_Gene_KNOWN	$max	$TEMP[0]	chr$TEMP[1]	$TEMP[2]-$TEMP[3]	$TEMP[-1]	$TEMP[5]	$TEMP[6]	$TEMP[7]	$TEMP[8]";
   }
   elsif(%dlabel){
   $record+=1;
   my $max=-1;
   my $SYD="";
   foreach my $k1 (sort {$a cmp $b} keys %dlabel)
   {
    push $full_info{Decipher_KNOWN},$k1."_$max";
    if($dlabel{$k1}>$max) {$max=$dlabel{$k1}; $SYD=$k1;}
   }
   my @TEMP=split /\t/,$SYD;
   if($max>1) {$max=1.00;}
   $max=sprintf("%.2f",$max);
   $info=$_."	Decipher_KNOWN	$max	$TEMP[0]	chr$TEMP[1]	$TEMP[2]-$TEMP[3]	$TEMP[-1]	$TEMP[5]	$TEMP[6]	$TEMP[7]	$TEMP[8]";
   }
   elsif(%Ilabel){
   $record+=1;
   my $max=-1;
   my $SYD="";
   foreach my $k1 (sort {$a cmp $b} keys %Ilabel)
   {
    push $full_info{ISCA_Gene_KNOWN},$k1."_$max";
    if($Ilabel{$k1}>$max) {$max=$Ilabel{$k1}; $SYD=$k1;}
   }
   my @TEMP=split /\t/,$SYD;
   if($max>1) {$max=1.00;}
   $max=sprintf("%.2f",$max);
   $info=$_."	ISCA_Gene_KNOWN	$max	$TEMP[3]	$TEMP[0]	$TEMP[1]-$TEMP[2]	$TEMP[4]	$TEMP[6]	$TEMP[7]";
   }
   elsif(%ilabel){
   $record+=1;
   my $max=-1;
   my $SYD="";
   foreach my $k1 (sort {$a cmp $b} keys %ilabel)
   {
    push $full_info{ISCA_KNOWN},$k1."_$max";
    if($ilabel{$k1}>$max) {$max=$ilabel{$k1}; $SYD=$k1;}
   }
   my @TEMP=split /\t/,$SYD;
   if($max>1) {$max=1.00;}
   $max=sprintf("%.2f",$max);
   $info=$_."	ISCA_KNOWN	$max	$TEMP[3]	$TEMP[0]	$TEMP[1]-$TEMP[2]	$TEMP[4]	$TEMP[6]	$TEMP[7]";
   }
   else{
   $info=$_."	-	-	-";
   }
   if($record==0){
   push(@filted,$_);
   }
   else{
   push(@ann,$info);
   }
}
close(F1);

my $t3=$f1; $t3=~s/.txt$/_DI_FULL_Annotation.txt/;
my $t4=$f1; $t4=~s/.txt$/_DI_FULL_Filted.txt/;
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
