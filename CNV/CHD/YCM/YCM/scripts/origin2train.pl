#!/usr/bin/perl
use strict;
use warnings;

if(@ARGV!=1){
	print STDERR <<EOF;
		perl $0 origin.txt
EOF
exit;
}

my $file=shift;
open my $fh,"<","$file" or die $!;
while(<$fh>){
	next if /^#/;
	chomp;
	#b5b6    p3_p4   b1_4    g       Gr      r       t       u2      u3      y1_y2   y3_y4   code    status
	my @tmp=split /\t/;
	my $i=1;
	print $tmp[$#tmp-1],"\t",join ("\t",map {$i++.":".$_ } @tmp[0..$#tmp-2]),"\n";
}
