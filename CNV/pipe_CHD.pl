#!/usr/bin/perl -w
use strict;
unless(@ARGV==2){	die "perl $0 bin_dir result_dir\n";	}
my ($bin_dir, $result_dir) = @ARGV;
if($result_dir =~ /\./){
        my $tmp = `pwd`;chomp $tmp;
        $result_dir =~ s/\./$tmp/;
}
$result_dir =~ /project\/CHD\/(\w+)\/(SQR\d+)\//;
my ($site, $run_id) = ($1, $2);

`perl /home/bioadmin/YingyingXia/project/CHD/BJBK/parallel_logRR.pl $result_dir $bin_dir\/LOGRR/`;
`perl $bin_dir\/Auto_DNAcopy_BreakPoints.pl $result_dir $bin_dir\/BreakPoints/ $bin_dir\/DatabaseAnn/`;

`perl $bin_dir\/Upload_Scripts/upload_chd_info_SiteCommon.pl $result_dir $bin_dir\/Upload_Scripts`;
`python /home/bioadmin/YingyingXia/project/CHD/get_sampleinfo.py $result_dir/index2id.txt $site $run_id $result_dir/sample_info.txt`
#`perl /home/bioadmin/YingyingXia/project/CHD/BJBK/create_zip_BJBK.pl $result_dir`;
#`perl $bin_dir\/scr/Auto_CHD_Mysql_CNV.pl $result_dir XJJY 40000 $bin_dir\/scr`;
