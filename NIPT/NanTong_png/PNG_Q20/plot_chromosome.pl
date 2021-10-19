#!/usr/bin/perl -w
use strict;

open(FH,$ARGV[0]);
my $id=$ARGV[1];
my $path=$ARGV[2];

my %info=();
my $label=0;
my %Cnums=();
while(<FH>)
{
 chomp($_);
 my @tmp=split /\t/,$_;
 $label+=1;
 $Cnums{$tmp[0]}+=1;
 $info{$tmp[0]}{$tmp[1]}=$_."\t".$label;
}
close(FH);

my @chr=("chr1","chr2","chr3","chr4","chr5","chr6","chr7","chr8","chr9","chr10","chr11","chr12","chr13","chr14","chr15","chr16","chr17","chr18","chr19","chr20","chr21","chr22");

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
 $file{$k1}=$f1;
 #system("rm $o1");
}

my $input="";
my $out=$ARGV[0]; $out=~s/txt$/png/;
for(my $i=0;$i<$gender;$i++)
{
 if($input eq "") {$input=$file{$chr[$i]};}
 else{
 $input.=" ".$file{$chr[$i]};
 }
}
my $nums=22;
system("Rscript $path/plot_all_chromosome.r $id $label $nums $out $input >/dev/null");


for(my $i=0;$i<$gender;$i++)
{
# system("rm $file{$chr[$i]}");
}
