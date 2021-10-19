#!/usr/bin/perl -w
use strict;

my $f1=$ARGV[0]; ##abnormal cnv
my $t1=$f1; $t1=~s/.txt$/_Merge_1Mb.txt/;
open(T1,">$t1");
my $t2=$f1; $t2=~s/.txt$/_Merge_100Kb.txt/;
open(T2,">$t2");

my @chr=("chr1","chr2","chr3","chr4","chr5","chr6","chr7","chr8","chr9","chr10","chr11","chr12","chr13","chr14","chr15","chr16","chr17","chr18","chr19","chr20","chr21","chr22","chrX","chrY");

my %del=();
my %dup=();
my %mdel=();
my %mdup=();
open(F1,$f1);
my $lines=0;
while(<F1>)
{
 next if $_=~/^ID/;
 chomp($_);
 $lines+=1;
 my @tmp=split /\t/,$_;
 my $logRR=$tmp[5];
 my $RR=2*(2**($tmp[5]));
 my $Chr=$tmp[1];
 if($RR>=2.80) {$dup{$Chr}{$lines}=$_;}
 elsif($RR<=1.20) {$del{$Chr}{$lines}=$_;}
 elsif($RR>=2.1) {$mdup{$Chr}{$lines}=$_;}
 elsif($RR<=1.9) {$mdel{$Chr}{$lines}=$_;}
}
close(F1);

my %info=();
for(my $i=0;$i<=$#chr;$i++)
{
 if(exists $dup{$chr[$i]})
 {
  foreach my $ln (sort {$a<=>$b} keys %{$dup{$chr[$i]}})
  {
   if($dup{$chr[$i]}{$ln} ne "NA")
   {
    my $Info=$dup{$chr[$i]}{$ln};
    my $tm=$ln;
	LN:while(1)
    {
	 $tm+=1;
	 if(exists $dup{$chr[$i]}{$tm})
	 {
	  my @temp1=split /\t/,$Info;
	  my @temp2=split /\t/,$dup{$chr[$i]}{$tm};
	  my @R1=split /\-/,$temp1[-1];
	  my @R2=split /\-/,$temp2[-1];
=pod
	  if($R1[-1] eq $R2[0])
	  {
	  my $id=$temp1[0];
	  my $Chr=$temp1[1];
	  my $start=$temp1[2];
	  my $end=$temp2[3];
	  my $nums=$temp1[4]+$temp2[4];
	  my $logRR=($temp1[4]*$temp1[5]+$temp2[4]*$temp2[5])/($temp1[4]+$temp2[4]);
	  my $rbin=$temp1[6]+$temp2[6];
	  my $ebin=$temp1[7];
	  my $rlen=$temp1[8]+$temp2[8]-40*1000; ##40kb overlap
	  my $cyto=$R1[0]."-".$R2[-1];
	  $Info="$id	$Chr	$start	$end	$nums	$logRR	$rbin	$ebin	$rlen	$cyto";
	  $dup{$chr[$i]}{$tm}="NA";
	  }
=cut
	  #elsif($temp1[3]>=$temp2[2])
	  if($temp1[3]>=$temp2[2])
	  {
	  my $id=$temp1[0];
	  my $Chr=$temp1[1];
	  my $start=$temp1[2];
	  my $end=$temp2[3];
	  my $nums=$temp1[4]+$temp2[4];
	  my $logRR=($temp1[4]*$temp1[5]+$temp2[4]*$temp2[5])/($temp1[4]+$temp2[4]);
	  my $rbin=$temp1[6]+$temp2[6];
	  my $ebin=$temp1[7];
	  my $rlen=$temp1[8]+$temp2[8]-40*1000; ##40kb overlap
	  my $cyto=$R1[0]."-".$R2[-1];
	  $Info="$id	$Chr	$start	$end	$nums	$logRR	$rbin	$ebin	$rlen	$cyto";
	  $dup{$chr[$i]}{$tm}="NA";
	  }
	  else{
	  last LN;
	  }
	 }
	 else{
	 last LN;
	 }
    }
	$dup{$chr[$i]}{$ln}="NA";
	my @temp=split /\t/,$Info;
	$info{$temp[1]}{$temp[2]}=$Info;
   }
  }
 }
 if(exists $del{$chr[$i]})
 {
  foreach my $ln (sort {$a<=>$b} keys %{$del{$chr[$i]}})
  {
   if($del{$chr[$i]}{$ln} ne "NA")
   {
    my $Info=$del{$chr[$i]}{$ln};
    my $tm=$ln;
	LN:while(1)
    {
	 $tm+=1;
	 if(exists $del{$chr[$i]}{$tm})
	 {
	  my @temp1=split /\t/,$Info;
	  my @temp2=split /\t/,$del{$chr[$i]}{$tm};
	  my @R1=split /\-/,$temp1[-1];
	  my @R2=split /\-/,$temp2[-1];
=pod
	  if($R1[-1] eq $R2[0])
	  {
	  my $id=$temp1[0];
	  my $Chr=$temp1[1];
	  my $start=$temp1[2];
	  my $end=$temp2[3];
	  my $nums=$temp1[4]+$temp2[4];
	  my $logRR=($temp1[4]*$temp1[5]+$temp2[4]*$temp2[5])/($temp1[4]+$temp2[4]);
	  my $rbin=$temp1[6]+$temp2[6];
	  my $ebin=$temp1[7];
	  my $rlen=$temp1[8]+$temp2[8]-40*1000; ##40kb overlap
	  my $cyto=$R1[0]."-".$R2[-1];
	  $Info="$id	$Chr	$start	$end	$nums	$logRR	$rbin	$ebin	$rlen	$cyto";
	  $del{$chr[$i]}{$tm}="NA";
	  }
=cut
	  #elsif($temp1[3]>=$temp2[2])
	  if($temp1[3]>=$temp2[2])
	  {
	  my $id=$temp1[0];
	  my $Chr=$temp1[1];
	  my $start=$temp1[2];
	  my $end=$temp2[3];
	  my $nums=$temp1[4]+$temp2[4];
	  my $logRR=($temp1[4]*$temp1[5]+$temp2[4]*$temp2[5])/($temp1[4]+$temp2[4]);
	  my $rbin=$temp1[6]+$temp2[6];
	  my $ebin=$temp1[7];
	  my $rlen=$temp1[8]+$temp2[8]-40*1000; ##40kb overlap
	  my $cyto=$R1[0]."-".$R2[-1];
	  $Info="$id	$Chr	$start	$end	$nums	$logRR	$rbin	$ebin	$rlen	$cyto";
	  $del{$chr[$i]}{$tm}="NA";
	  }
	  else{
	  last LN;
	  }
	 }
	 else{
	 last LN;
	 }
    }
	$del{$chr[$i]}{$ln}="NA";
	my @temp=split /\t/,$Info;
	$info{$temp[1]}{$temp[2]}=$Info;
   }
  }
 }
 if(exists $mdup{$chr[$i]})
 {
  foreach my $ln (sort {$a<=>$b} keys %{$mdup{$chr[$i]}})
  {
   if($mdup{$chr[$i]}{$ln} ne "NA")
   {
    my $Info=$mdup{$chr[$i]}{$ln};
    my $tm=$ln;
	LN:while(1)
    {
	 $tm+=1;
	 if(exists $mdup{$chr[$i]}{$tm})
	 {
	  my @temp1=split /\t/,$Info;
	  my @temp2=split /\t/,$mdup{$chr[$i]}{$tm};
	  my @R1=split /\-/,$temp1[-1];
	  my @R2=split /\-/,$temp2[-1];
=pod
	  if($R1[-1] eq $R2[0])
	  {
	  my $id=$temp1[0];
	  my $Chr=$temp1[1];
	  my $start=$temp1[2];
	  my $end=$temp2[3];
	  my $nums=$temp1[4]+$temp2[4];
	  my $logRR=($temp1[4]*$temp1[5]+$temp2[4]*$temp2[5])/($temp1[4]+$temp2[4]);
	  my $rbin=$temp1[6]+$temp2[6];
	  my $ebin=$temp1[7];
	  my $rlen=$temp1[8]+$temp2[8]-40*1000; ##40kb overlap
	  my $cyto=$R1[0]."-".$R2[-1];
	  $Info="$id	$Chr	$start	$end	$nums	$logRR	$rbin	$ebin	$rlen	$cyto";
	  $mdup{$chr[$i]}{$tm}="NA";
	  }
=cut
	  #elsif($temp1[3]>=$temp2[2])
	  if($temp1[3]>=$temp2[2])
	  {
	  my $id=$temp1[0];
	  my $Chr=$temp1[1];
	  my $start=$temp1[2];
	  my $end=$temp2[3];
	  my $nums=$temp1[4]+$temp2[4];
	  my $logRR=($temp1[4]*$temp1[5]+$temp2[4]*$temp2[5])/($temp1[4]+$temp2[4]);
	  my $rbin=$temp1[6]+$temp2[6];
	  my $ebin=$temp1[7];
	  my $rlen=$temp1[8]+$temp2[8]-40*1000; ##40kb overlap
	  my $cyto=$R1[0]."-".$R2[-1];
	  $Info="$id	$Chr	$start	$end	$nums	$logRR	$rbin	$ebin	$rlen	$cyto";
	  $mdup{$chr[$i]}{$tm}="NA";
	  }
	  else{
	  last LN;
	  }
	 }
	 else{
	 last LN;
	 }
    }
	$mdup{$chr[$i]}{$ln}="NA";
	my @temp=split /\t/,$Info;
	$info{$temp[1]}{$temp[2]}=$Info;
   }
  }
 }
 if(exists $mdel{$chr[$i]})
 {
  foreach my $ln (sort {$a<=>$b} keys %{$mdel{$chr[$i]}})
  {
   if($mdel{$chr[$i]}{$ln} ne "NA")
   {
    my $Info=$mdel{$chr[$i]}{$ln};
    my $tm=$ln;
	LN:while(1)
    {
	 $tm+=1;
	 if(exists $mdel{$chr[$i]}{$tm})
	 {
	  my @temp1=split /\t/,$Info;
	  my @temp2=split /\t/,$mdel{$chr[$i]}{$tm};
	  my @R1=split /\-/,$temp1[-1];
	  my @R2=split /\-/,$temp2[-1];
=pod
	  if($R1[-1] eq $R2[0])
	  {
	  my $id=$temp1[0];
	  my $Chr=$temp1[1];
	  my $start=$temp1[2];
	  my $end=$temp2[3];
	  my $nums=$temp1[4]+$temp2[4];
	  my $logRR=($temp1[4]*$temp1[5]+$temp2[4]*$temp2[5])/($temp1[4]+$temp2[4]);
	  my $rbin=$temp1[6]+$temp2[6];
	  my $ebin=$temp1[7];
	  my $rlen=$temp1[8]+$temp2[8]-40*1000; ##40kb overlap
	  my $cyto=$R1[0]."-".$R2[-1];
	  $Info="$id	$Chr	$start	$end	$nums	$logRR	$rbin	$ebin	$rlen	$cyto";
	  $mdel{$chr[$i]}{$tm}="NA";
	  }
=cut
	  #elsif($temp1[3]>=$temp2[2])
	  if($temp1[3]>=$temp2[2])
	  {
	  my $id=$temp1[0];
	  my $Chr=$temp1[1];
	  my $start=$temp1[2];
	  my $end=$temp2[3];
	  my $nums=$temp1[4]+$temp2[4];
	  my $logRR=($temp1[4]*$temp1[5]+$temp2[4]*$temp2[5])/($temp1[4]+$temp2[4]);
	  my $rbin=$temp1[6]+$temp2[6];
	  my $ebin=$temp1[7];
	  my $rlen=$temp1[8]+$temp2[8]-40*1000; ##40kb overlap
	  my $cyto=$R1[0]."-".$R2[-1];
	  $Info="$id	$Chr	$start	$end	$nums	$logRR	$rbin	$ebin	$rlen	$cyto";
	  $mdel{$chr[$i]}{$tm}="NA";
	  }
	  else{
	  last LN;
	  }
	 }
	 else{
	 last LN;
	 }
    }
	$mdel{$chr[$i]}{$ln}="NA";
	my @temp=split /\t/,$Info;
	$info{$temp[1]}{$temp[2]}=$Info;
   }
  }
 }
}

print T1 "ID	chrom	loc.start	loc.end	num.mark	seg.mean	r.BinNums	e.BinNums	r.len	cytoband.region	mosaic.per\n";

for(my $i=0;$i<=$#chr;$i++)
{
 if(exists $info{$chr[$i]}){
 foreach my $pos (sort {$a<=>$b} keys %{$info{$chr[$i]}})
 {
 my @temp=split /\t/,$info{$chr[$i]}{$pos};
 my $RR=2*(2**($temp[5]));
 if((($RR>=2.80) | ($RR<=1.20)) && $temp[8]>=(1000*1000)){
  $temp[5]=sprintf("%.4f",$temp[5]);
  print T1 "$temp[0]	$temp[1]	$temp[2]	$temp[3]	$temp[4]	$temp[5]	$temp[6]	$temp[7]	$temp[8]	$temp[9]	100\n";
 }
 elsif((($RR>=2.1) | ($RR<=1.9)) && $temp[8]>=(10000*1000)){
  $temp[5]=sprintf("%.4f",$temp[5]);
  my $per=int(abs(2**($temp[5])*2-2)*100);
  print T1 "$temp[0]	$temp[1]	$temp[2]	$temp[3]	$temp[4]	$temp[5]	$temp[6]	$temp[7]	$temp[8]	$temp[9]	$per\n";
 }
 }
 }
}
close(T1);

print T2 "ID	chrom	loc.start	loc.end	num.mark	seg.mean	r.BinNums	e.BinNums	r.len	cytoband.region	mosaic.per\n";

for(my $i=0;$i<=$#chr;$i++)
{
 if(exists $info{$chr[$i]}){
 foreach my $pos (sort {$a<=>$b} keys %{$info{$chr[$i]}})
 {
 my @temp=split /\t/,$info{$chr[$i]}{$pos};
 my $RR=2*(2**($temp[5]));
 $temp[9]=~s/\-//;
 if((($RR>=2.80) | ($RR<=1.20)) && $temp[8]>=(100*1000)){
  $temp[5]=sprintf("%.4f",$temp[5]);
  print T2 "$temp[0]	$temp[1]	$temp[2]	$temp[3]	$temp[4]	$temp[5]	$temp[6]	$temp[7]	$temp[8]	$temp[9]	100\n";
 }
 elsif((($RR>=2.1) | ($RR<=1.9)) && $temp[8]>=(10000*1000)){
  $temp[5]=sprintf("%.4f",$temp[5]);
  my $per=int(abs(2**($temp[5])*2-2)*100);
  print T2 "$temp[0]	$temp[1]	$temp[2]	$temp[3]	$temp[4]	$temp[5]	$temp[6]	$temp[7]	$temp[8]	$temp[9]	$per\n";
 }
 }
 }
}
close(T2);
system("rm $f1");
