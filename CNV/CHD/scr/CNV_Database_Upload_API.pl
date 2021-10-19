#!/usr/bin/perl
use strict;
use warnings;
use Encode qw/_utf8_on/;
use Try::Tiny;
use DBI;
use utf8;
binmode(STDERR,":utf8");
binmode(STDOUT,":utf8");

open(FH,$ARGV[0]); ##CNV_Annotation

my ($hospital ,$run ,$sample ,$test_date,$binsize,$method)=("","","","","","");
$hospital=$ARGV[1]; ##样本来源医院
$run=$ARGV[2]; ##run号
$sample=$ARGV[3]; ##样本编号
$test_date="20".substr($run,3,2)."-".substr($run,5,2)."-".substr($run,7,2);
$binsize=$ARGV[4]; ##分析采用的bin大小
$method=$ARGV[5]; ##检测分类

if($ARGV[0]=~/Annotation.txt$/)
{
while(<FH>)
{
 next if $_=~/^ID/;
 my ($chrom ,$start ,$end ,$region ,$type ,$number ,$submitter ,$cytoband ,$note,$mosaic,$size)=("","","","","","","","","","","");
 my @tmp=split /\t/,$_;
 #$sample=$tmp[0];
 $chrom=$tmp[1];
 $start=$tmp[2];
 $end=$tmp[3];
 $region=$tmp[13];
 if($region=~/^dup/) {$type="dup";}
 elsif($region=~/^del/) {$type="del";}
 elsif($region=~/^\+/) {$type="gain";}
 elsif($region=~/^Trisomy/) {$type="gain";}
 elsif($region=~/^\-/) {$type="loss";}
 elsif($region=~/^Monosomy/) {$type="loss";}
 elsif($region=~/^Mosaic\.dup/) {$type="dup";}
 elsif($region=~/^Mosaic\.del/) {$type="del";}
 elsif($region=~/^Mosaic\.\+/) {$type="gain";}
 elsif($region=~/^Mosaic\.Trisomy/) {$type="gain";}
 elsif($region=~/^Mosaic\.\-/) {$type="loss";}
 elsif($region=~/^Mosaic\.Monosomy/) {$type="loss";}
 $number=$tmp[5];
 $submitter=$tmp[15];
 $cytoband=$tmp[9];
 $size=$tmp[8];
 if($submitter=~/ISCA/i || $submitter=~/DECIPHER/i){
  for(my $i=15;$i<=$#tmp;$i++)
  {
  if($note eq "") {$note=$tmp[$i];}
  else{
  $note.="\t".$tmp[$i];
  }
  }
 }
 $mosaic=$tmp[14];
 if($note eq "") {$note="NULL";}

my $database="cnv"; #数据库
my $host='172.16.10.33';#数据库ip
my $port=3306; #数据库端口
my $db_user='cnv'; #数据库账号
my $db_password='6L2inux~'; #数据库密码

#-------------------------------------#
#连接数据库
my $dbh = DBI->connect("DBI:mysql:database=$database;host=$host;port=$port","$db_user","$db_password",{'RaiseError' => 1});
$dbh->do("SET NAMES utf8");
my $insert_id;
#-------------------------------------#
#插入新记录
try{
	$dbh->{'AutoCommit'} = 0;   #关闭事务自动提交
	if ($dbh->{'AutoCommit'}) {
		die "Cannot start transaction!:$!\n";
	}
	#id hospital run sample test_date chrom start end region type number submitter cytoband binsize note method mosaic 
	if($note ne "NULL"){
	my $sql = "insert into cnv (hospital ,run ,sample ,test_date,chrom ,start ,end ,region ,type ,number ,submitter ,cytoband ,binsize,note,method,mosaic, size) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);";
	#my $sth=$dbh->do($sql,undef,("新疆佳音","SQR170403002", "R170327006","2017-03-27","chrY",24890000,26520000,"chrY:24890000-26520000","gain","3","DGV","",40000,"测试",'CHD',0, 100000)); #执行插入语句
	my $sth=$dbh->do($sql,undef,($hospital,$run, $sample,$test_date,$chrom,$start,$end,$region,$type,$number,$submitter,$cytoband,$binsize,$note,$method,$mosaic, $size)); #执行插入语句
	}
	else{
	my $sql = "insert into cnv (hospital ,run ,sample ,test_date,chrom ,start ,end ,region ,type ,number ,submitter ,cytoband ,binsize,method,mosaic, size) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);";
	#my $sth=$dbh->do($sql,undef,("新疆佳音","SQR170403002", "R170327006","2017-03-27","chrY",24890000,26520000,"chrY:24890000-26520000","gain","3","DGV","",40000,"测试",'CHD',0, 100000)); #执行插入语句
	my $sth=$dbh->do($sql,undef,($hospital,$run, $sample,$test_date,$chrom,$start,$end,$region,$type,$number,$submitter,$cytoband,$binsize,$method,$mosaic, $size)); #执行插入语句
	}
	$insert_id = $dbh->{q{mysql_insertid}};
	$dbh->commit(); #提交事务
}catch{
	$dbh->rollback(); #出现错误将执行回滚
	die $_;
};

print $insert_id,"\n";

#-------------------------------------#
#取出刚插入的记录
$dbh->{'AutoCommit'} = 1;   #开启事务自动提交(如果未在程序中设置AutoCommit,默认是1)。
if (not $dbh->{'AutoCommit'}) {
	die "Cannot start transaction!:$!\n";
}
my $sql2 = "select * from cnv where id = $insert_id";
my $sth2=$dbh->prepare($sql2);
$sth2->execute();

while(my $ref=$sth2->fetchrow_hashref){
	map {_utf8_on $ref->{$_}} keys %$ref ; #防止数据库某些数据未开启utf8标记
	print "id:\t",$ref->{id},"\n",
			"hospital:\t",$ref->{hospital},"\n",
			"run:\t",$ref->{run},"\n",
			"sample:\t",$ref->{sample},"\n",
			"chrom:\t",$ref->{chrom},"\n",
			"start:\t",$ref->{start},"\n",
			"end:\t",$ref->{end},"\n",
			"region:\t",$ref->{region},"\n",
			"type:\t",$ref->{type},"\n",
			"number:\t",$ref->{number},"\n",
			"submitter:\t",$ref->{submitter},"\n",
			"cytoband:\t",$ref->{cytoband},"\n",
			#"note:\t",$ref->{note},"\n";
	print "--------------\n";
}

}
close(FH);
}
elsif($ARGV[0]=~/Cytoband.txt$/){
my $database="cnv"; #数据库
my $host='172.16.10.33';#数据库ip
my $port=3306; #数据库端口
my $db_user='cnv'; #数据库账号
my $db_password='6L2inux~'; #数据库密码

#-------------------------------------#
#连接数据库
my $dbh = DBI->connect("DBI:mysql:database=$database;host=$host;port=$port","$db_user","$db_password",{'RaiseError' => 1});
$dbh->do("SET NAMES utf8");
my $insert_id;
#-------------------------------------#
#插入新记录
try{
	$dbh->{'AutoCommit'} = 0;   #关闭事务自动提交
	if ($dbh->{'AutoCommit'}) {
		die "Cannot start transaction!:$!\n";
	}
	#id hospital run sample test_date chrom start end region type number submitter cytoband binsize note method mosaic 

	my $sql = "insert into cnv (hospital ,run ,sample ,test_date ,binsize,method) values(?,?,?,?,?,?);";
	#my $sth=$dbh->do($sql,undef,("新疆佳音","SQR170403002", "R170327006","2017-03-27","chrY",24890000,26520000,"chrY:24890000-26520000","gain","3","DGV","",40000,"测试",'CHD',0, 100000)); #执行插入语句
	my $sth=$dbh->do($sql,undef,($hospital,$run, $sample,$test_date,$binsize,$method)); #执行插入语句

	$insert_id = $dbh->{q{mysql_insertid}};
	$dbh->commit(); #提交事务
}catch{
	$dbh->rollback(); #出现错误将执行回滚
	die $_;
};

print $insert_id,"\n";

#-------------------------------------#
#取出刚插入的记录
$dbh->{'AutoCommit'} = 1;   #开启事务自动提交(如果未在程序中设置AutoCommit,默认是1)。
if (not $dbh->{'AutoCommit'}) {
	die "Cannot start transaction!:$!\n";
}
my $sql2 = "select * from cnv where id = $insert_id";
my $sth2=$dbh->prepare($sql2);
$sth2->execute();

while(my $ref=$sth2->fetchrow_hashref){
	map {_utf8_on $ref->{$_}} keys %$ref ; #防止数据库某些数据未开启utf8标记
	print "id:\t",$ref->{id},"\n",
			"hospital:\t",$ref->{hospital},"\n",
			"run:\t",$ref->{run},"\n",
			"sample:\t",$ref->{sample},"\n",
			#"chrom:\t",$ref->{chrom},"\n",
			#"start:\t",$ref->{start},"\n",
			#"end:\t",$ref->{end},"\n",
			#"region:\t",$ref->{region},"\n",
			#"type:\t",$ref->{type},"\n",
			#"number:\t",$ref->{number},"\n",
			#"submitter:\t",$ref->{submitter},"\n",
			#"cytoband:\t",$ref->{cytoband},"\n",
			#"note:\t",$ref->{note},"\n";
	print "--------------\n";
}
}
__DATA__

数据库结构
+-----------+---------------------------------+-----------------------------+
| Field     | Type                            | Comment                     |
+-----------+---------------------------------+-----------------------------+
| id        | int(10)                         |                             |
| hospital  | varchar(255)                    | 医院                        |
| run       | varchar(40)                     |                             |
| sample    | varchar(40)                     | 样本名                      |
| test_date | date                            |                             |
| chrom     | varchar(30)                     |                             |
| start     | int(10)                         |                             |
| end       | int(10)                         |                             |
| region    | varchar(255)                    | CNV描述                     |
| type      | enum('gain','loss','dup','del') |                             |
| number    | double(10,5)                    | CNV数量                     |
| submitter | varchar(255)                    | 已验证数据库                |
| cytoband  | varchar(50)                     |                             |
| binsize   | int(10)                         | 窗口大小，区分精度          |
| note      | varchar(255)                    | 备注                        |
| method    | varchar(30)                     | 检测类型:CHD,PGS...         |
| mosaic    | int(10)                         | 嵌合比例                    |
+-----------+---------------------------------+-----------------------------+
