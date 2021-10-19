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

my $name=$p2."/NIPT_SizeSelect_block.html";
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
for(my $i=11;$i<=24;$i++)
{
push(@create_html,$html[$i]);
}
my $j=25;
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
my $file_label=0;

opendir(PH,$p1);
while(my $file=readdir(PH))
{
 if($file=~/$num/)
 {
  if($file=~/2000Kb_Fbin_GC_All_Normalized_Percentage_ZScore_All.txt$/)
  {$zs=$p1."/".$file; $file_label+=1;}
  if($file=~/BamDuplicates.json$/)
  {$rmdup=$p1."/".$file; $file_label+=1;}
 }
}
closedir(PH);

if($file_label!=2) {next LINE;}

open(RM,$rmdup);
my @rm=<RM>;
close(RM);
$rm[12]=~s/\s+//g;
$rm[12]=~s/\,$//g;
my @temp=split /\:/,$rm[12];
my $mapping=$temp[1];

open(ZS,$zs);
my @zscore=<ZS>;
close(ZS);
chomp($zscore[0]);
my @array=split /\t/,$zscore[0];
my $unique=$array[1];

chomp($zscore[2]);
@array=split /\t/,$zscore[2];
my $of=$array[1];
if($of ne "NULL") {$of=sprintf("%.4f",$of);}

chomp($zscore[15]);
@array=split /\t/,$zscore[15];
my $Z13=$array[1]; $Z13=sprintf("%.3f",$Z13);
chomp($zscore[20]);
@array=split /\t/,$zscore[20];
my $Z18=$array[1]; $Z18=sprintf("%.3f",$Z18);
chomp($zscore[23]);
@array=split /\t/,$zscore[23];
my $Z21=$array[1]; $Z21=sprintf("%.3f",$Z21);

$create_html[$j]=$html[25]; $j++;
$create_html[$j]=$html[26]; $create_html[$j]=~s/NULL/$barcodeid/; $j++; print $barcodeid."\n";
$create_html[$j]=$html[27]; $create_html[$j]=~s/NULL/$sampleid/; $j++; print $sampleid."\n";
$create_html[$j]=$html[28]; $create_html[$j]=~s/NULL/$unique/; $j++; print $unique."\n";
$create_html[$j]=$html[29]; $create_html[$j]=~s/NULL/$mapping/; $j++; print $mapping."\n";
$create_html[$j]=$html[30]; $create_html[$j]=~s/NULL/$Z13/; $j++; print $Z13."\n";
$create_html[$j]=$html[31]; $create_html[$j]=~s/NULL/$Z18/; $j++; print $Z18."\n";
$create_html[$j]=$html[32]; $create_html[$j]=~s/NULL/$Z21/; $j++; print $Z21."\n";
$create_html[$j]=$html[33]; $create_html[$j]=~s/NULL/$of/; $j++; print $of."\n";
$create_html[$j]=$html[34]; $j++;
}

for(my $i=35;$i<=38;$i++)
{
push(@create_html,$html[$i]);
}

my $output_html=$p1."/NIPT_SizeSelect_block.html";

open(TO,">$output_html");

print TO "@create_html";
close(TO);

close(HTML);
