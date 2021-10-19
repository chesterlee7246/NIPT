#!/usr/bin/perl -w
use strict;
use Statistics::Descriptive;

open(FH,$ARGV[0]); ##GC file

my @reads=();
while(<FH>)
{
 next if $_=~/^##Chromosome/;
 chomp($_);
 my @tmp=split /\t/,$_;
 if($tmp[$#tmp]!=0 && $tmp[0] ne "chrX" && $tmp[0] ne "chrY") {push(@reads,$tmp[$#tmp]);}
}

my $stat = Statistics::Descriptive::Full->new();
$stat->add_data(@reads);
my $mean = $stat->median();
$stat->clear();

seek(FH,0,0);

my $to=$ARGV[0];
$to=~s/.txt$/_Normalized.txt/;
open(TO,">$to");
print TO "##MedianReads	$mean\n";
while(<FH>)
{
 next if $_=~/^##Chromosome/;
 chomp($_);
 my @tmp=split /\t/,$_;
 my $normalized=$tmp[$#tmp]/$mean; print TO "$tmp[0]	$tmp[1]	$normalized\n";
}
close(FH);
close(TO);

