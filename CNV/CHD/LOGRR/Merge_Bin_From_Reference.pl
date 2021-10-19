#!/usr/bin/perl -w
use strict;
use Statistics::Descriptive;

open(RF,$ARGV[0]); ##Reference bin
open(FH,$ARGV[1]); ##All_Bin_File
my $gender=$ARGV[2];

my %info=();
while(<FH>)
{
  chomp($_);
  my @tmp=split /\t/,$_;
  $info{$tmp[0]}{$tmp[1]}=$tmp[2];
}
close(FH);

my $to=$ARGV[1]; $to=~s/.txt$/_Merge.txt/;
open(TO,">$to");
my %NUM=();
while(<RF>)
{
 if($gender eq "female" && $_=~/^chrY/) {next;}
 else{
 chomp($_);
 my @tmp=split /\t/,$_;
 $NUM{$tmp[0]}+=1;
 my $reads=0;
 for(my $i=$tmp[1];$i<=$tmp[2];$i++)
 {
  $reads+=$info{$tmp[0]}{$i};
 }
 print TO "$tmp[0]	$NUM{$tmp[0]}	$reads	$tmp[1]	$tmp[2]	$tmp[3]\n";
 }
}
close(RF);
close(TO);


open(F2,$to);
my @reads=();
while(<F2>)
{
 next if $_=~/^##Chromosome/;
 chomp($_);
 my @tmp=split /\t/,$_;
 if($tmp[2]!=0 && $tmp[0] ne "chrX" && $tmp[0] ne "chrY") {push(@reads,$tmp[2]);}
}

my $stat = Statistics::Descriptive::Full->new();
$stat->add_data(@reads);
my $mean = $stat->median();
$stat->clear();

seek(F2,0,0);


my $t1=$to;
$t1=~s/.txt$/_Normalized.txt/;
open(T1,">$t1");
print T1 "##MedianReads	$mean\n";
while(<F2>)
{
 next if $_=~/^##Chromosome/;
 chomp($_);
 my @tmp=split /\t/,$_;
 my $normalized=$tmp[2]/$mean; print T1 "$tmp[0]	$tmp[1]	$normalized\n";
}
close(F2);
close(T1);
