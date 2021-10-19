#!/usr/bin/perl -w
use strict;


my $p1=$ARGV[0]; ##path index2id file
my $p2=$ARGV[1]; ##path scripts
my $f3=$ARGV[2]."/expMeta.dat";

open(F3,$f3);
my $run_name="";
while(<F3>)
{
  if($_=~/^Analysis Name/){
   $_=~s/\s+//g;
   my @tmp=split /\=/,$_;
   $run_name=$tmp[1];
  }
}
close(F3);

my $name=$p2."/BaseCareNIPT_block.html";
open(HTML,$name); ##report example html
my @html=();
@html=<HTML>;

if($p1=~/\/$/) {$p1=~s/\/$//;}
my @split_dir=split /\//,$p1;
my @create_html=();
for(my $i=0;$i<=9;$i++)
{
push(@create_html,$html[$i]);
}
$create_html[10]=$html[10]; $create_html[10]=~s/NULL/$run_name/;
for(my $i=11;$i<=26;$i++)
{
push(@create_html,$html[$i]);
}
my $j=27;
my $id2index="";
if($p1=~/\/$/) {$id2index=$p1."index2id.txt";}
else{$id2index=$p1."/index2id.txt";}

open(ID,$id2index);
my %index=();
while(<ID>)
{
 chomp($_);
 my @tmp=split /\t/,$_;
 $index{$tmp[0]}=$tmp[1];
}
close(ID);

my $sampleid="";
my $barcodeid="";

LINE:foreach my $num (sort {$a cmp $b} keys %index)
{
  $sampleid=$index{$num};
  $barcodeid=$num;

my $zs="";
my $rmdup="";
my $pf="";
my $nbin="";
my $file_label=0;

opendir(PH,$p1);
while(my $file=readdir(PH))
{
 if($file=~/$num/)
 {
  if($file=~/MAPQ60_Fbin_GC_Per_ZScore.txt$/)
  {$zs=$p1."/".$file; $file_label+=1;}
  if($file=~/BamDuplicates.json$/)
  {$rmdup=$p1."/".$file; $file_label+=1;}
  if($file=~/Size_Info_Percentage.txt$/)
  {$pf=$p1."/".$file; $file_label+=1;}
  if($file=~/MAPQ60_Nbin.txt$/)
  {$nbin=$p1."/".$file; $file_label+=1;}
 }
}
closedir(PH);

if($file_label!=4) {next LINE;}

open(NB,$nbin);
my @NBIN=<NB>;
chomp($NBIN[0]);
my @Ntmp=split /\t/,$NBIN[0];
my $unique=$Ntmp[-1];
close(NB);

open(RM,$rmdup);
my @rm=<RM>;
close(RM);
$rm[5]=~s/\s+//g;
$rm[5]=~s/\,$//g;
my @temp=split /\:/,$rm[5];
my $mapping=$temp[1];

open(PF,$pf);
my @pdf=<PF>;
close(PF);
chomp($pdf[-1]);
my @Ctmp=split /\t/,$pdf[-1];
my $Pdf=sprintf("%.4f",$Ctmp[-1]);

open(ZS,$zs);
my @zscore=<ZS>;
close(ZS);

chomp($zscore[0]);
my @array=split /\t/,$zscore[0];
my $of=$array[-1];

my $Z13="";my $Z18="";my $Z21="";
if($of ne "NULL") {
$of=sprintf("%.4f",$of);
chomp($zscore[17]);
@array=split /\t/,$zscore[17];
$Z13=$array[-1]; $Z13=sprintf("%.3f",$Z13);
chomp($zscore[22]);
@array=split /\t/,$zscore[22];
$Z18=$array[-1]; $Z18=sprintf("%.3f",$Z18);
chomp($zscore[25]);
@array=split /\t/,$zscore[25];
$Z21=$array[-1]; $Z21=sprintf("%.3f",$Z21);
}
else{
chomp($zscore[13]);
@array=split /\t/,$zscore[13];
$Z13=$array[-1]; $Z13=sprintf("%.3f",$Z13);
chomp($zscore[18]);
@array=split /\t/,$zscore[18];
$Z18=$array[-1]; $Z18=sprintf("%.3f",$Z18);
chomp($zscore[21]);
@array=split /\t/,$zscore[21];
$Z21=$array[-1]; $Z21=sprintf("%.3f",$Z21);
}

my $mark="";
if($Z13<3 && $Z18<3 && $Z21<3){$mark="--";}
elsif($Z13>=3 && $Z18<3 && $Z21<3) {$mark="13,++";}
elsif($Z13<3 && $Z18>=3 && $Z21<3) {$mark="18,++";}
elsif($Z13<3 && $Z18<3 && $Z21>=3) {$mark="21,++";}
elsif($Z13>=3 && $Z18>=3 && $Z21<3) {$mark="13_18,++";}
elsif($Z13>=3 && $Z18<3 && $Z21>=3) {$mark="13_21,++";}
elsif($Z13<3 && $Z18>=3 && $Z21>=3) {$mark="18_21,++";}
elsif($Z13>=3 && $Z18>=3 && $Z21>=3) {$mark="13_18_21,++";}
$create_html[$j]=$html[27]; $j++;
$create_html[$j]=$html[28]; $create_html[$j]=~s/NULL/$barcodeid/; $j++;
$create_html[$j]=$html[29]; $create_html[$j]=~s/NULL/$sampleid/; $j++;
$create_html[$j]=$html[30]; $create_html[$j]=~s/NULL/$unique/; $j++;
$create_html[$j]=$html[31]; $create_html[$j]=~s/NULL/$mapping/; $j++;
$create_html[$j]=$html[32]; $create_html[$j]=~s/NULL/$Z13/; $j++;
$create_html[$j]=$html[33]; $create_html[$j]=~s/NULL/$Z18/; $j++;
$create_html[$j]=$html[34]; $create_html[$j]=~s/NULL/$Z21/; $j++;
$create_html[$j]=$html[35]; $create_html[$j]=~s/NULL/$mark/; $j++;
$create_html[$j]=$html[36]; $create_html[$j]=~s/NULL/$of/; $j++;
$create_html[$j]=$html[37]; $create_html[$j]=~s/NULL/$Pdf/; $j++;
$create_html[$j]=$html[38]; $j++;
}


for(my $i=39;$i<=42;$i++)
{
push(@create_html,$html[$i]);
}

my $output_html=$p1."/BaseCareNIPT_block.html";

open(TO,">$output_html");

print TO "@create_html";
close(TO);

close(HTML);
