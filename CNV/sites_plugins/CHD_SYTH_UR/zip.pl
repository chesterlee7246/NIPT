#!/usr/bin/perl -w
use File::Basename;

my $dir1=$ARGV[0];
my $dir2=$ARGV[1];
my $dir=$ARGV[2];

my $png1=$dir1."/Bead_density_contour.png"; $png1=~s/\/\//\//;
my $png2=$dir1."/basecaller_results/wells_beadogram.png"; $png2=~s/\/\//\//;
my $png3=$dir1."/basecaller_results/readLenHisto.png"; $png3=~s/\/\//\//;

my $f1=$dir1."/expMeta.dat";
my $f2=$dir1."/basecaller_results/BaseCaller.json";
my $f3=$dir1."/sigproc_results/analysis.bfmask.stats";

my $json=$dir1."/ion_params_00.json"; $json=~s/\/\//\//;
my $json1=$dir1."/basecaller_results/datasets_basecaller.json"; $json1=~s/\/\//\//;
my $unique_id=$dir1."/version.txt"; $unique_id=~s/\/\//\//;

my $outdir=$dir2."/ZIP";

system("cp $png1 $outdir");
system("cp $png2 $outdir");
system("cp $png3 $outdir");
system("cp $json $outdir");
system("cp $json1 $outdir");
system("cp $unique_id $outdir");
system("cp $f1 $outdir");
system("cp $f2 $outdir");
system("cp $f3 $outdir");
system("cp $dir2/*Nbin.txt $outdir");
system("cp $dir2/*Size_Info.txt $outdir");
system("cp $dir2/*.json $outdir");
system("cp $dir2/*unique_Cov.txt $outdir");
#system("cp $dir2/*rmdup_info.txt $outdir");
#system("cp $dir2/*reads_info.txt $outdir");
#system("cp $dir2/drmaa_stdout.txt $outdir");

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

my $name=$host."_".$file; $name=~s/Auto/CHD_${site}/;
my $outname=$dir2."/".$name;  $outname=~s/\/\//\//;
my $zip=$outname.".zip";
print $zip,"\n";

system("zip -r -j $zip $dir2/ZIP");

my $zipsize = 10; # 判断zip文件大小，大于25M，则进行split，然后从站点传输回来
$zipsize = -s $zip;
if($zipsize<=25000000){
    system("python $dir/uploadfile.py $zip");
}
else{
    my $newzip=basename($zip);
    system("cat $zip | split -b 10M -d -a 1 - $dir2/$newzip\.");
    system("rm -f $zip");
    system("ls $dir2/$newzip* | while read sample; do echo \$sample; python $dir/uploadfile.py \$sample; done ");
}
