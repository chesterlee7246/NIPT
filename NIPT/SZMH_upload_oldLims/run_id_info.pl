#!/usr/bin/perl -w
use strict;
use JSON;
use Data::Dumper;

my $dir=$ARGV[0];
$dir=~s/\/$//;

my $f1=$ARGV[0]."/expMeta.dat";
my $f2=$ARGV[0]."/BaseCaller.json";
my $f3=$ARGV[0]."/analysis.bfmask.stats";
my $f4=$ARGV[0]."/startplugin.json";
my $f5=$ARGV[0]."/datasets_basecaller.json";

my $path=$ARGV[1]; ##脚本目录

open(F1,$f1);
open(F2,$f2);
open(F3,$f3);

my $instrument="";
my $run_name="";

while(<F1>)
{
  if($_=~/^Run Name/){
   $_=~s/\s+//g;
   my @tmp=split /[\_\-\.]/,$_;
   for(my $i=0;$i<=$#tmp;$i++)
   {
    if($tmp[$i]=~/^SQR/) {
    $run_name=$tmp[$i];
    next;}
   }
  }
  elsif($_=~/^Instrument/){
  $_=~s/\s+//g;
  my @tmp=split /\=/,$_;
  $instrument=$tmp[1];
  }
}
close(F1);

my ($polyclonal, $low, $final, $gb);
while(<F2>)
{
  if($_=~/\"filtered_polyclonal\"/){
  $_=~s/\s+//g;
  $_=~s/\,//g;
  my @tmp=split /\:/,$_;
  $polyclonal=$tmp[1];
  }
  elsif($_=~/\"filtered_low_quality\"/){
  $_=~s/\s+//g;
  $_=~s/\,//g;
  my @tmp=split /\:/,$_;
  $low=$tmp[1];
  }
  elsif($_=~/\"final_library_reads\"/){
  $_=~s/\s+//g;
  $_=~s/\,//g;
  my @tmp=split /\:/,$_;
  $final=$tmp[1];
  }
  elsif($_=~/\"final\"/){
  $_=~s/\s+//g;
  $_=~s/\,//g;
  my @tmp=split /\:/,$_;
  $gb=$tmp[1];
  }
}
close(F2);

my ($total, $empty, $bead, $live, $exclud);
while(<F3>)
{
  if($_=~/^Total Wells/){
  $_=~s/\s+//g;
  my @tmp=split /\=/,$_;
  $total=$tmp[1];
  }
  elsif($_=~/^Excluded Wells/){
  $_=~s/\s+//g;
  my @tmp=split /\=/,$_;
  $exclud=$tmp[1];
  }
  elsif($_=~/^Empty Wells/){
  $_=~s/\s+//g;
  my @tmp=split /\=/,$_;
  $empty=$tmp[1];
  }
  elsif($_=~/^Bead Wells/){
  $_=~s/\s+//g;
  my @tmp=split /\=/,$_;
  $bead=$tmp[1];
  }
  elsif($_=~/^Live Beads/){
  $_=~s/\s+//g;
  my @tmp=split /\=/,$_;
  $live=$tmp[1];
  }
}
close(F3);

open JS1, "$f4";
my $js1;
while(<JS1>) {
   $js1 .= "$_";
}
close(JS1);
my $json = new JSON;
my $obj = $json->decode($js1);
my $runid=$obj->{'expmeta'}->{"runid"};
#print "$runid\n";

open JS2, "$f5";
my $js2;
while(<JS2>) {
   $js2 .= "$_";
}
close(JS2);
my $Datasets_json = new JSON;
my $Datasets_obj = $Datasets_json->decode($js2);
my $all=0;
my $q20=0;
for(my $i=1;$i<=96;$i++)
{
 my $index=$runid."\."."IonXpress_".sprintf("%03d",$i);
 my $info1=$Datasets_obj->{'read_groups'}->{$index}->{"total_bases"}; $all+=$info1;
 my $info2=$Datasets_obj->{'read_groups'}->{$index}->{"Q20_bases"}; $q20+=$info2;
 #print "$index	$info1	$info2\n";
}

my $q20per=($q20/$all)*100;
my $Q20=sprintf("%.1f",$q20per)."%";
#print "$all	$q20	$per\n";



my $reads=$final/1000000; $reads=sprintf("%.1f",$reads);
my $Gb=$gb/1000000000; $Gb=sprintf("%.1f",$Gb);
my $len=int($gb/$final);
my $isp=($bead/($total-$exclud))*100; $isp=sprintf("%.1f",$isp);
my $Empty=100-$isp; $Empty=sprintf("%.1f",$Empty);
my $enrich=($live/$bead)*100; $enrich=sprintf("%.1f",$enrich);
my $no=100-$enrich; $no=sprintf("%.1f",$no);
my $Polyclonal=($polyclonal/$live)*100; $Polyclonal=sprintf("%.1f",$Polyclonal);
my $clonal=100-$Polyclonal; $clonal=sprintf("%.1f",$clonal);
my $Low=($low/($live-$polyclonal))*100; $Low=sprintf("%.1f",$Low);
my $Final=($final/($live-$polyclonal))*100; $Final=sprintf("%.1f",$Final);

$reads.="Mb"; $Gb.="Gbp"; $len.="bp"; $isp.="%"; $Empty.="%"; $enrich.="%"; $no.="%"; $Polyclonal.="%"; $clonal.="%"; $Low.="%"; $Final.="%";

my $s1=$path."/run_id_info.py";
print "$s1:$run_name:$reads:$Gb:$len:$isp:$enrich:$clonal:$Final:$Empty:$no:$Polyclonal:$Low:$instrument:$Q20\n";
system("python $s1 $run_name $reads $Gb $len $isp $enrich $clonal $Final $Empty $no $Polyclonal $Low $instrument $Q20");
