#!/usr/bin/perl -w
use strict;

my $f1=$ARGV[0];
open(F1,$f1);

my $f2=$f1;
$f2=~s/.txt$/_ConvertValue.txt/;
open(TO,">$f2");

my $label=0;
while(<F1>)
{
 if($_=~/^chrY/) {$label+=1;}
}
seek(F1,0,0);
while(<F1>)
{
 chomp($_);
 my @tmp=split /\t/,$_;
 if($tmp[0] ne "chrX" && $tmp[0] ne "chrY"){
 if($tmp[3]=~/NA/) {$tmp[3]="NA";$tmp[4]="NA";}
 elsif($tmp[4]=~/NA/) {$tmp[3]="NA";$tmp[4]="NA";}
 else{
 $tmp[3]=2*(2**$tmp[3]); #$tmp[3]=log($tmp[3])/log(2);
 $tmp[4]=2*(2**$tmp[4]); #$tmp[4]=log($tmp[4])/log(2);
 }
 }
 elsif($tmp[0] eq "chrX" && $label==0){
 if($tmp[3]=~/NA/) {$tmp[3]="NA";$tmp[4]="NA";}
 elsif($tmp[4]=~/NA/) {$tmp[3]="NA";$tmp[4]="NA";}
 else{
 $tmp[3]=2*(2**$tmp[3]); #$tmp[3]=log($tmp[3])/log(2);
 $tmp[4]=2*(2**$tmp[4]); #$tmp[4]=log($tmp[4])/log(2);
 }
 }
 elsif((($tmp[0] eq "chrX") | ($tmp[0] eq "chrY")) && $label!=0)
 {
 if($tmp[3]=~/NA/) {$tmp[3]="NA";$tmp[4]="NA";}
 elsif($tmp[4]=~/NA/) {$tmp[3]="NA";$tmp[4]="NA";}
 else{
 $tmp[3]=2*(2**$tmp[3])-1; #$tmp[3]=log($tmp[3])/log(2);
 $tmp[4]=2*(2**$tmp[4])-1; #$tmp[4]=log($tmp[4])/log(2);
 }
 }
 print TO "$tmp[0]	$tmp[1]	$tmp[2]	$tmp[3]	$tmp[4]\n";
}
close(F1);
close(TO);