#!/usr/bin/perl -w
use strict;

open(FH,$ARGV[0]);
my $id=$ARGV[1];
my $path=$ARGV[2];
my $Label=$ARGV[3];
my $YY=$ARGV[4];
my $YG=$ARGV[5];

my %info=();
my $label=0;
my %Cnums=();
while(<FH>)
{
 chomp($_);
 my @tmp=split /\t/,$_;
 if($Label==0 && $YG eq "female") {if($tmp[0] ne "chrY") {$label+=1;}}
 elsif($Label==0 && $YG eq "male" && $YY eq "Y") {$label+=1;}
 elsif($Label==0 && $YG eq "male" && $YY ne "Y") {if($tmp[0] ne "chrY") {$label+=1;}}
 else{
 $label+=1;
 }
 $Cnums{$tmp[0]}+=1;
 $info{$tmp[0]}{$tmp[1]}=$_."\t".$label;
}
close(FH);

my @chr=("chr1","chr2","chr3","chr4","chr5","chr6","chr7","chr8","chr9","chr10","chr11","chr12","chr13","chr14","chr15","chr16","chr17","chr18","chr19","chr20","chr21","chr22","chrX","chrY");

my $gender=0;
my %file=();
foreach my $k1 (sort {$a cmp $b} keys %info)
{
 $gender+=1;
 my $f1=$ARGV[0]; $f1=~s/.txt//; $f1.="_".$k1.".txt";
 my $o1=$f1; $o1=~s/txt$/png/;
 open(TMP,">$f1");
 foreach my $k2 (sort {$a <=> $b} keys %{$info{$k1}})
 {
  print TMP $info{$k1}{$k2}."\n";
 }
 close(TMP);
 system("Rscript $path/plot_each_chromosome.r $f1 $k1 $o1 $Cnums{$k1} >/dev/null");
 $file{$k1}=$f1;
 #system("rm $o1");
}

my $input="";
my $out=$ARGV[0]; $out=~s/txt$/png/;
my $outnew=$ARGV[0]; $outnew=~s/txt$/new.png/;
my $outnoXY=$ARGV[0]; $outnew=~s/.txt$/_noXY.png/;
for(my $i=0;$i<$gender;$i++)
{
 if($input eq "") {$input=$file{$chr[$i]};}
 else{
 $input.=" ".$file{$chr[$i]};
 }
}
my $nums=0;
if($Label==0 && $YG eq "female") {$nums=23;}
elsif($Label==0 && $YG eq "male" && $YY ne "Y") {$nums=23;}
elsif($Label==0 && $YG eq "male" && $YY eq "Y") {$nums=24;}
else {$nums=24;}
system("Rscript $path/plot_all_chromosome.r $id $label $nums $out $input >/dev/null");
system("Rscript $path/plot_all_chromosome_rb.r $id $label $nums $outnew $input >/dev/null");
system("Rscript $path/plot_all_chromosome_22.r $id $label 22 $outnoXY $input >/dev/null");
for(my $i=0;$i<$gender;$i++)
{
 system("rm $file{$chr[$i]}");
}
