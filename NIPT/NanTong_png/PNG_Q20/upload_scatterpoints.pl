#!/usr/bin/perl -w
use strict;

my $HT=$ARGV[0];
open(HT,$HT);
my @info=<HT>;
close(HT);
my $path=$ARGV[1];

my $cnv=$HT; $cnv=~s/html$/txt/;
system("perl $path/plot_chromosome.pl $cnv NULL $path");
my $png=$cnv; $png=~s/txt$/png/;
my $repng=$png; $repng=~s/.png$/_resize.png/;
#system("convert -resize 1100x300 $png $repng");
my $base64=`base64 -w 0 $png`;
my @html=();
my $Info="";
$Info="\<div style\=\"width\:1100px\;margin\: 0 auto\;\"\>\n";
push(@html,$Info);
$Info="\<img style\=\"float\:left\;max\-width\:1100px\" src\=\"data\:image\/png\;base64\,".$base64."\" \/\>\n";
push(@html,$Info);
$Info="\<\/div\>\n\n";
push(@html,$Info);
#system("rm $repng");

for(my $i=0;$i<=$#info;$i++)
{
 if($i>=9 && $i<=66) {
 push(@html,$info[$i]);
 }
}

my $HTML=$HT; $HTML=~s/\.html$/_ScatterPoints.html/;
 open(HM,">$HTML");
 print HM "@html";
 close(HM);
 