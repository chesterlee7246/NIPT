#!/usr/bin/perl -w
use strict;

my $f1=$ARGV[0]; ##real cnv effective
my $f2=$ARGV[1]; ##cytoband
my $to=$f1; $to=~s/.txt$/_Extract_Abnormal_CNV.txt/;
open(TO,">$to");

open(F2,$f2);

my %cytoband=();
my %chr_end=();
while(<F2>)
{
 my @tmp=split /\t/,$_;
 my $chr=$tmp[0];
 my $start=$tmp[1]+1;
 my $end=$tmp[2];
 $cytoband{$chr}{$start}{$end}=$tmp[3];
 $chr_end{$chr}=$end;
}
close(F2);

open(F1,$f1);
my $record=0;
while(<F1>)
{
 next if $_=~/^ID/;
 next if $_=~/^##SD/;
 chomp($_);
 my @tmp=split /\t/,$_;
 my $RR=2*(2**($tmp[5]));
 if($RR>=2.1 && $RR<2.75 && ($tmp[8]>=5.00 || $tmp[9]>=5.00) && $tmp[6]<=1e-5) {$record+=1;}
 elsif($RR<=1.9 && $RR>1.25 && ($tmp[8]>=5.00 || $tmp[9]>=5.00) && $tmp[6]<=1e-5) {$record+=1;}
 elsif($RR>=2.75 && (($tmp[8]>=3.00) || ($tmp[9]>=3.00)) && $tmp[6]<=1e-5) {$record+=1;}
 elsif($RR<=1.25 && (($tmp[8]>=3.00) || ($tmp[9]>=3.00)) && $tmp[6]<=1e-5) {$record+=1;}
 #elsif($RR>=2.75 && (($tmp[8]>=3.00) && ($tmp[9]>=3.00)) && $tmp[6]<=1e-5) {$record+=1;}
 #elsif($RR<=1.25 && (($tmp[8]>=3.00) && ($tmp[9]>=3.00)) && $tmp[6]<=1e-5) {$record+=1;}
 #elsif($RR>=2.8 && $tmp[6]<=1e-5) {$record+=1;}
 #elsif($RR<=1.2 && $tmp[6]<=1e-5) {$record+=1;}
}
close(F1);

print TO "ID	chrom	loc.start	loc.end	num.mark	seg.mean	r.BinNums	e.BinNums	r.len	cytoband.region\n";

if($record>0){
open(F1,$f1);
while(<F1>)
{
 next if $_=~/^##SD/;
 next if $_=~/^ID/;
 chomp($_);
 my @tmp=split /\t/,$_;
 my $id=$tmp[0];
 my $chr=$tmp[1];
 my $start=$tmp[2];
 my $end=$tmp[3];
 if($end>$chr_end{$chr}) {$end=$chr_end{$chr};}
 my $nums=$tmp[4];
 my $logRR=$tmp[5];
 my $RR=2*(2**($tmp[5]));
 my $pvalue=$tmp[6];
 my $pmad=$tmp[8];
 my $psd=$tmp[9];
 my $rbin=$tmp[10];
 my $ebin=$tmp[11];
 my $rlen=$tmp[13];
 if($chr ne "chr19" && (($RR>=2.1 && $RR<2.75) | ($RR<=1.9 && $RR>1.25)) && ($pmad>=5.00 || $psd>=5.00) && $pvalue<=1e-5){
		my @region=();
		foreach my $pos1 (sort {$a<=>$b} keys %{$cytoband{$chr}}){
			foreach my $pos2 (sort {$a<=>$b} keys %{$cytoband{$chr}{$pos1}}){
				if(($start>$pos2) | ($end<$pos1)) {next;}
				else{		push(@region,$cytoband{$chr}{$pos1}{$pos2});		}
			}
		}

		my $info="";
		if($#region==0) {$info=$region[0];}
		else{$info=$region[0]."-".$region[$#region];}

		print TO "$id	$chr	$start	$end	$nums	$logRR	$rbin	$ebin	$rlen	$info\n";
 }elsif($chr ne "chr19" && (($RR>=2.75) | ($RR<=1.25)) && (($pmad>=3.00) || ($psd>=3.00)) && $pvalue<=1e-5){
		my @region=();
		foreach my $pos1 (sort {$a<=>$b} keys %{$cytoband{$chr}}){
			foreach my $pos2 (sort {$a<=>$b} keys %{$cytoband{$chr}{$pos1}}){
				if(($start>$pos2) | ($end<$pos1)) {next;}
				else{		push(@region,$cytoband{$chr}{$pos1}{$pos2});		}
			}
		}

		my $info="";
		if($#region==0) {$info=$region[0];}
		else {$info=$region[0]."-".$region[$#region];}

		print TO "$id	$chr	$start	$end	$nums	$logRR	$rbin	$ebin	$rlen	$info\n";
 }elsif($chr eq "chr19" && (($RR>=2.1 && $RR<2.75) | ($RR<=1.9 && $RR>1.25)) && ($pmad>=5.00 && $psd>=5.00) && $pvalue<=1e-5){
		my @region=();
		foreach my $pos1 (sort {$a<=>$b} keys %{$cytoband{$chr}}){
			foreach my $pos2 (sort {$a<=>$b} keys %{$cytoband{$chr}{$pos1}}){
				if(($start>$pos2) | ($end<$pos1)) {next;}
				else{		push(@region,$cytoband{$chr}{$pos1}{$pos2});		}
			}
		}

		my $info="";
		if($#region==0) {$info=$region[0];}
		else{$info=$region[0]."-".$region[$#region];}
		print TO "$id	$chr	$start	$end	$nums	$logRR	$rbin	$ebin	$rlen	$info\n";
 }elsif($chr eq "chr19" && (($RR>=2.75) | ($RR<=1.25)) && (($pmad>=3.00) && ($psd>=3.00)) && $pvalue<=1e-5){
		my @region=();
		foreach my $pos1 (sort {$a<=>$b} keys %{$cytoband{$chr}}){
			foreach my $pos2 (sort {$a<=>$b} keys %{$cytoband{$chr}{$pos1}}){
				if(($start>$pos2) | ($end<$pos1)) {next;}
				else{		push(@region,$cytoband{$chr}{$pos1}{$pos2});		}
			}
		}

		my $info="";
		if($#region==0) {$info=$region[0];}
		else {$info=$region[0]."-".$region[$#region];}
		print TO "$id	$chr	$start	$end	$nums	$logRR	$rbin	$ebin	$rlen	$info\n";
 }
=pod
 elsif((($RR>=2.8) | ($RR<=1.2)) && $pvalue<=1e-5){
  my @region=();
  foreach my $pos1 (sort {$a<=>$b} keys %{$cytoband{$chr}})
  {
   foreach my $pos2 (sort {$a<=>$b} keys %{$cytoband{$chr}{$pos1}})
   {
    if(($start>$pos2) | ($end<$pos1)) {next;}
	else{
	push(@region,$cytoband{$chr}{$pos1}{$pos2});
	}
   }
  }
  my $info="";
  if($#region==0) {$info=$region[0];}
  else {$info=$region[0]."-".$region[$#region];}
 print TO "$id	$chr	$start	$end	$nums	$logRR	$rbin	$ebin	$rlen	$info\n";
 }
=cut
}
close(F1);
}
close(TO);
