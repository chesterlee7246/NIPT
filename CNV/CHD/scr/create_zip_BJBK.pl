#!/usr/bin/perl -w
use strict;
unless(@ARGV==1){	die "perl $0 result_dir\n";	}
my ($result_dir) = @ARGV;
if($result_dir =~ /\./){	$result_dir = `pwd`;chomp $result_dir;	}
my $project = "CHD";

$result_dir =~ /CHD\/(\w+)\/(SQR\w+)/;
my ($site, $run_ID) = ($1, $2);

my $zip_dir = "$result_dir\/Result_$project\_$site\_$run_ID";
`mkdir $zip_dir`;
`cp $result_dir\/*100Kb_Cytoband*.txt $zip_dir`;
#`cp $result_dir\/*_LogRR_CytoBand_Mosaic.png $zip_dir`;
#`cp $result_dir\/*_LogRR_Extract_CNV.png $zip_dir`;
`zip -r -j $zip_dir\.zip $zip_dir`;

my $attachment = `uuencode $zip_dir\.zip $zip_dir\.zip`;
my $message=<< "MSS";
陈梅，你好！
	
  附件是$site\站点$run_ID\中$project\数据的分析结果，烦请查收。如有问题请随时联系。

祝好！

--
张军

MSS

print "Mail of $site $run_ID is sent!\n";

&sendmail($message,$attachment);

sub sendmail{
    my ($message,$body)=@_;
    if(not defined $message or not $message){
        return;
    }
    open(MAIL,'|/usr/lib/sendmail -t');
    select(MAIL);
print << "END_TAG";
To: chen203\@basecare.cn
From: zhang109\@basecare.cn
CC: zhang109\@basecare.cn,wang338\@basecare.cn
Subject: $site\站点$project\分析结果\($run_ID\)

$message

$attachment
END_TAG
}
