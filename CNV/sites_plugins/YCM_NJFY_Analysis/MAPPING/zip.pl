#!/usr/bin/perl -w

my $dir1=$ARGV[0];
my $dir2=$ARGV[1];
my $dir=$ARGV[2];


my $f1=$dir1."/expMeta.dat";
my $f2=$dir1."/basecaller_results/BaseCaller.json";
my $f3=$dir1."/sigproc_results/analysis.bfmask.stats";

my $json=$dir1."/ion_params_00.json"; $json=~s/\/\//\//;
my $json1=$dir1."/basecaller_results/datasets_basecaller.json"; $json1=~s/\/\//\//;
my $unique_id=$dir1."/version.txt"; $unique_id=~s/\/\//\//;

my $outdir=$dir2."/ZIP";


system("cp $json $outdir"); system("cp $json $dir2");
system("cp $json1 $outdir"); system("cp $json1 $dir2");
system("cp $unique_id $outdir"); system("cp $unique_id $dir2");
system("cp $f1 $outdir"); system("cp $f1 $dir2");
system("cp $f2 $outdir"); system("cp $f2 $dir2");
system("cp $f3 $outdir"); system("cp $f3 $dir2");
system("cp $dir2/*.bed $outdir");


open(FH,$f1);
my @info=<FH>;
my $host="";
for(my $i=0;$i<=$#info;$i++)
{
 if($info[$i]=~/^Instrument/){
 chomp($info[$i]);
 $info[$i]=~s/\s+//g;
 my @tmp=split /\=/,$info[$i];
 $host=$tmp[1];
 }
}
close(FH);

open(F1,$unique_id);
my @info1=<F1>;
for(my $i=0;$i<=$#info1;$i++)
{
 if($info1[$i]=~/^host/){
 chomp($info1[$i]);
 $info1[$i]=~s/\s+//g;
 my @tmp=split /\=/,$info1[$i];
 $host.="_".$tmp[1];
 }
}
close(F1);

my @tmp=split /\//,$dir1;
my $file=$tmp[$#tmp];

my $site="CHD";
if($dir=~/CHD_(\w+)\/*$/){
    $site = $1;
}

my $name=$host."_".$file; $name=~s/Auto/${site}_YCM/;
my $outname=$dir2."/".$name;  $outname=~s/\/\//\//;
my $zip=$outname.".zip";
system("zip -r -j $zip $dir2/ZIP");

system("python $dir/uploadfile.py $zip");
