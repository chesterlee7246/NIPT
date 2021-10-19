#!/usr/bin/perl -w
use strict;
use threads;

my $p1=$ARGV[0]; #输入文件路径名：没比对bam路径
my $p1map=$ARGV[1]; #输入文件路径名：已比对bam路径
my $p2=$ARGV[2]; #输出文件路径名
my $dir=$ARGV[3];

my $json=$p1."/datasets_basecaller.json";
my $index2id=$p2."/AllIndexLabel.txt";
system("python $dir/barcode_generate.py $json >$index2id");
open(FH,$index2id);
my %index=();
while(<FH>)
{
 chomp($_);
 my $tmp="IonXpress_".$_;
 $index{$tmp}+=1;
}
close(FH);

my @path=();

opendir(UNMAP,$p1);
while(my $filename=readdir(UNMAP))
{
 next if($filename=~/^\./);
 if($filename=~/^IonXpress/ && $filename=~/bam$/)
 {
 my $name="";
 my $label=substr($filename,0,13);
 if($p1=~/\/$/) {$name=$p1.$filename;}
 else {$name=$p1."/".$filename;}
 if(exists $index{$label})
 {push(@path,$name);}
 }
}
closedir(UNMAP);


opendir(MAP,$p1map);
while(my $filename=readdir(MAP))
{
 next if($filename=~/^\./);
 if($filename=~/^IonXpress/ && $filename=~/bam$/)
 {
 my $name="";
 my $label=substr($filename,0,13);
 if($p1map=~/\/$/) {$name=$p1map.$filename;}
 else {$name=$p1map."/".$filename;}
 if(exists $index{$label})
 {push(@path,$name);}
 }
}
closedir(MAP);

@path=sort {$a cmp $b} @path;
for(my $j=0;$j<=$#path;$j+=2)
#for(my $j=0;$j<=$#path;$j+=1)
{
my @type=();
if($j<=$#path) {$type[0]=$path[$j];}
if(($j+1)<=$#path) {$type[1]=$path[$j+1];}

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

sub function
{
 my $form=$_[0];
 system("perl $dir/mapping_hg19.pl $form $p2 $dir");###mapping
}

