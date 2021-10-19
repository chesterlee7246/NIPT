#!/usr/bin/perl -w
use strict;
use threads;

my $dir=$ARGV[0];
opendir(PH,$dir);
my $path=$ARGV[1];

my $json=$dir."/ion_params_00.json"; $json=~s/\/\//\//g;
my $index2id=$dir."/index2id.txt"; $index2id=~s/\/\//\//g;
my $new=$path."/extract_sampleid_new.pl"; $new=~s/\/\//\//g;
if(-e $json){
system("perl $new $json $index2id");
}

my @FILE=();
while(my $file=readdir(PH))
{
 if($file=~/MAPQ60_Nbin.txt$/)
 {
   my $name=$dir."/".$file;
   push(@FILE,$name);
 }
}
closedir(PH);

for(my $j=0;$j<=$#FILE;$j+=4)
{
my @type=();
if($j<=$#FILE) {$type[0]=$FILE[$j];}
if(($j+1)<=$#FILE) {$type[1]=$FILE[$j+1];}
if(($j+2)<=$#FILE) {$type[2]=$FILE[$j+2];}
if(($j+3)<=$#FILE) {$type[3]=$FILE[$j+3];}

my @t=();

foreach my $tmp (@type)
{
 push @t,threads->create(\&function,$tmp);
}

foreach my $temp (@t)
{
 $temp->join();
}
}

system("perl $path/create_report_html_info.pl $dir $path $dir");

sub function
{
 my $form=$_[0];
 system("perl $path/auto_run_analysis.pl $form $path");
}

