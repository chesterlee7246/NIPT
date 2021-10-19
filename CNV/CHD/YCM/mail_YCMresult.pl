#!/usr/bin/perl -w
use strict;
unless(@ARGV==1){	die "perl $0 result_dir\n";	}
my ($result_dir) = @ARGV;
if($result_dir =~ /\./){	$result_dir = `pwd`;chomp $result_dir;	}
my $project = "YCM";

$result_dir =~ /CHD\/(\w+)\/(SQR\w+)/;
my ($site, $run_ID) = ($1, $2);
my $file_YCM = "$result_dir\/summary_YCM_last_$run_ID\.txt";
open OO,">$file_YCM" || die "$!";
opendir(P1,$result_dir);
while(my $file=readdir(P1))
{
	if($file =~ /last.txt$/){
		print "$file\n";
		open IN,"<$file" || die "$!";
		while(<IN>){
			next if(/^#/);
			chomp;
			print OO "$run_ID\t$site\t$_\n";
		}
		close IN;
	}
}
closedir(P1);
close OO;

my $zip_dir = "$result_dir\/Result_YCM\_$site\_$run_ID";
`mkdir $zip_dir` unless(-d $zip_dir);
`cp $result_dir\/ChrY*.png $result_dir\/ChrY*.pdf $result_dir\/summary_YCM_last_$run_ID\.txt $zip_dir`;
`zip -r -j $zip_dir\.zip $zip_dir`;

my $attachment = `uuencode $zip_dir\.zip $zip_dir\.zip`;
my $message=<< "MSS";
张军，你好！
	
  附件是$site\站点$run_ID\中$project\数据的分析结果，烦请查收。如有问题请随时联系。
  结果路径：	$result_dir

祝好！

--
王涛

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
To: zhang109\@basecare.cn
From: wang338\@basecare.cn
CC: wang338\@basecare.cn,lv386\@basecare.cn
Subject: $site\站点$project\分析结果\($run_ID\)

$message

$attachment
END_TAG
}
