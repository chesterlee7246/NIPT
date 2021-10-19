#!/usr/bin/perl -w
use strict;
unless(@ARGV==2){	die "perl $0 bin_dir result_dir\n";	}
my ($bin_dir, $result_dir) = @ARGV;

`perl $bin_dir\/parallel_logRR_CNVRef.pl $result_dir $bin_dir\/LOGRR/`;
`perl $bin_dir\/Auto_DNAcopy_BreakPoints.pl $result_dir $bin_dir\/BreakPoints/ $bin_dir\/DatabaseAnn/`;

