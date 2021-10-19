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

`perl $bin_dir\/scr/unzip_file.pl $result_dir`;
`perl $bin_dir\/parallel_logRR.pl $result_dir $bin_dir\/LOGRR/`;

open OU,">$result_dir\/index2id_YCM.txt" || die "$!";
open IN,"<$result_dir\/index2id.txt" || die "$!";
while(<IN>)
{
	my @line = split;
	my ($idx, $sample_id) = @line[0,1];
	next if($sample_id !~ /^R|^C|^[1-9]|^N/);
	my $index = $idx;
	$idx =~ s/IonXpress_0*//;

	my $info = `python $bin_dir\/YCM/ext_sampleInfo_from_ERP.py $sample_id $site $run_id`; chomp $info;
	my ($erp_sampleID, $erp_index, $erp_y) = split /,/,$info;
	if($erp_index eq $idx){
		if($erp_y eq "y"){
			print OU "$sample_id\t$index\n";
		}
	}else{	print "!!!WARNING: index of $sample_id is different in ERP and IonProton: erp=$erp_index\tseq=$idx\n";	}
}
close IN;
close OU;

if(-s "$result_dir\/index2id_YCM.txt"){
	`bash $bin_dir\/YCM/YCM/scripts/batch_YCM.sh $result_dir $result_dir`;
	`perl $bin_dir\/YCM/mail_YCMresult.pl $result_dir`;
}

`perl $bin_dir\/Auto_DNAcopy_BreakPoints.pl $result_dir $bin_dir\/BreakPoints/ $bin_dir\/DatabaseAnn/`;

`perl $bin_dir\/Upload_Scripts/upload_chd_info_SiteCommon.pl $result_dir $bin_dir\/Upload_Scripts`;
`python /home/bioadmin/YingyingXia/project/CHD/get_sampleinfo.py $result_dir/index2id.txt $site $run_id $result_dir/sample_info.txt`
#`perl $bin_dir\/scr/create_zip.pl $result_dir`;
#`perl $bin_dir\/scr/Auto_CHD_Mysql_CNV.pl $result_dir XJJY 40000 $bin_dir\/scr`;
