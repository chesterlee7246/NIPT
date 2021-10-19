#!/usr/bin/perl -w
use strict;
use Statistics::Descriptive;


my $name=$ARGV[0];
my $gender=$ARGV[1];

open(FH,$name); ##GC file

my @reads=();
while(<FH>)
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

seek(FH,0,0);

my $to=$name;
$to=~s/.txt$/_Normalized.txt/;
open(TO,">$to");
print TO "##MedianReads	$mean\n";
while(<FH>)
{
 next if $_=~/^##Chromosome/;
 if($gender eq "female" && $_=~/^chrY/) {next;}
 else{
 chomp($_);
 my @tmp=split /\t/,$_;
 my $normalized=$tmp[2]/$mean; print TO "$tmp[0]	$tmp[1]	$normalized\n";
 }
}
close(FH);
close(TO);

