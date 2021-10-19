#!/usr/bin/perl -w
use strict;

my $zip=$ARGV[0];
my $dir=$zip; $dir=~s/.zip$//;
system("mkdir $dir");
system("unzip $zip -d $dir");

opendir(PH,$dir);
my $path=$ARGV[1];

system("perl $path/Auto_Parallel.pl $dir $path");
