#!/usr/bin/perl -w
use strict;

open(F1,$ARGV[0]);
open(T1,">$ARGV[1]");

my %cnv=();

my $label=0;
LINE:while(<F1>)
{
 chomp($_);
 $_=~s/^\s+//;
 if($_=~/^ID/)
 {
 $label+=1;
 my @tmp=split /\s+/,$_;
 print T1 join "\t",@tmp;
 print T1 "\n";
 next LINE;
 }
 if($label==1){
 my @tmp=split /\s+/,$_;
 my @temp=();
 for(my $i=1;$i<=$#tmp;$i++) {push(@temp,$tmp[$i]);}
 print T1 join "\t",@temp;
 print T1 "\n";
 }
}
close(F1);
close(T1);