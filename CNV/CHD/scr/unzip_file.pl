#!/usr/bin/perl -w
use strict;
unless(@ARGV==1){	die "perl $0 zip_dir\n";	}
my $dir=$ARGV[0]; #dir of *.zip

#`cd '$dir'`;

opendir(P1,$dir);
while(my $file=readdir(P1))
{
	next if($file=~/^\./);
	if($file=~/\.zip$/){
		`unzip $file -d $dir`;
#		`rm $file`;
	}
}
closedir(P1);
#`rm *_BamDuplicates.json`;
