#!/usr/bin/perl -w
use strict;
use threads;

my $p1=$ARGV[0]; #输入文件路径名(Nbin)
my $p2=$ARGV[1]; #脚本路径

my $lims=$ARGV[2];
my $run_number=$ARGV[3];
my $site=$ARGV[4];

my $json=$p1."/ion_params_00.json";
if(-e $json)
{
    &change_index("$p1/index2id.txt",$p1);
    my $index2id=$p1."/index2id.txt";
}

my %id;
open ID,"<$p1\/index2id.txt" || die "$!";
while(<ID>)
{
    chomp;
    my @line = split;
    #next if($line[1] !~ /^*N|^*P|^*C/);
    $id{$line[0]} = $line[1];
}
close ID;

my @path=();

opendir(P1,$p1);

ST:while(my $filename=readdir(P1))
{
 next if($filename=~/^\./);
 if($filename=~/MAPQ10_Nbin.txt$/)
 {
	$filename =~ /(IonXpress_\d+)_/;
	my $index = $1;
	next ST if(!exists $id{$index});

 my $name="";
 if($p1=~/\/$/) {$name=$p1.$filename;}
 else {$name=$p1."/".$filename;}
 push(@path,$name);
 }
}
closedir(P1);



@path=sort {$a cmp $b} @path;
for(my $j=0;$j<=$#path;$j+=6)
#for(my $j=0;$j<=$#path;$j+=1)
{
my @type=();
if($j<=$#path) {$type[0]=$path[$j];}
if(($j+1)<=$#path) {$type[1]=$path[$j+1];}
if(($j+2)<=$#path) {$type[2]=$path[$j+2];}
if(($j+3)<=$#path) {$type[3]=$path[$j+3];}
if(($j+4)<=$#path) {$type[4]=$path[$j+4];}
if(($j+5)<=$#path) {$type[5]=$path[$j+5];}

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
 system("perl $p2/Auto_Extract_All_Bin.pl $form $p2");###mapping
}

sub change_index {
    my ($index2id,$direct)=@_;
    open OUT,">$direct\/index2id_temp";
    open IN,$index2id;
    while(<IN>){
        $_=~s/[\r\n]//g;
    my  @arr=split/\t/,$_;
        print OUT "$arr[0]\t$arr[1]\t$arr[1]\tY\n";
        }
    close IN;
    close OUT;
    system("mv $index2id $direct\/index2id.bak.txt");
    system("mv $direct\/index2id_temp $index2id");
    }
