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
$hospital=$ARGV[1]; ##������ԴҽԺ
$run=$ARGV[2]; ##run��
$sample=$ARGV[3]; ##�������
$test_date="20".substr($run,3,2)."-".substr($run,5,2)."-".substr($run,7,2);
$binsize=$ARGV[4]; ##�������õ�bin��С
$method=$ARGV[5]; ##������

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

my $database="cnv"; #���ݿ�
my $host='172.16.10.33';#���ݿ�ip
my $port=3306; #���ݿ�˿�
my $db_user='cnv'; #���ݿ��˺�
my $db_password='6L2inux~'; #���ݿ�����

#-------------------------------------#
#�������ݿ�
my $dbh = DBI->connect("DBI:mysql:database=$database;host=$host;port=$port","$db_user","$db_password",{'RaiseError' => 1});
$dbh->do("SET NAMES utf8");
my $insert_id;
#-------------------------------------#
#�����¼�¼
try{
	$dbh->{'AutoCommit'} = 0;   #�ر������Զ��ύ
	if ($dbh->{'AutoCommit'}) {
		die "Cannot start transaction!:$!\n";
	}
	#id hospital run sample test_date chrom start end region type number submitter cytoband binsize note method mosaic 
	if($note ne "NULL"){
	my $sql = "insert into cnv (hospital ,run ,sample ,test_date,chrom ,start ,end ,region ,type ,number ,submitter ,cytoband ,binsize,note,method,mosaic, size) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);";
	#my $sth=$dbh->do($sql,undef,("�½�����","SQR170403002", "R170327006","2017-03-27","chrY",24890000,26520000,"chrY:24890000-26520000","gain","3","DGV","",40000,"����",'CHD',0, 100000)); #ִ�в������
	my $sth=$dbh->do($sql,undef,($hospital,$run, $sample,$test_date,$chrom,$start,$end,$region,$type,$number,$submitter,$cytoband,$binsize,$note,$method,$mosaic, $size)); #ִ�в������
	}
	else{
	my $sql = "insert into cnv (hospital ,run ,sample ,test_date,chrom ,start ,end ,region ,type ,number ,submitter ,cytoband ,binsize,method,mosaic, size) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);";
	#my $sth=$dbh->do($sql,undef,("�½�����","SQR170403002", "R170327006","2017-03-27","chrY",24890000,26520000,"chrY:24890000-26520000","gain","3","DGV","",40000,"����",'CHD',0, 100000)); #ִ�в������
	my $sth=$dbh->do($sql,undef,($hospital,$run, $sample,$test_date,$chrom,$start,$end,$region,$type,$number,$submitter,$cytoband,$binsize,$method,$mosaic, $size)); #ִ�в������
	}
	$insert_id = $dbh->{q{mysql_insertid}};
	$dbh->commit(); #�ύ����
}catch{
	$dbh->rollback(); #���ִ���ִ�лع�
	die $_;
};

print $insert_id,"\n";

#-------------------------------------#
#ȡ���ղ���ļ�¼
$dbh->{'AutoCommit'} = 1;   #���������Զ��ύ(���δ�ڳ���������AutoCommit,Ĭ����1)��
if (not $dbh->{'AutoCommit'}) {
	die "Cannot start transaction!:$!\n";
}
my $sql2 = "select * from cnv where id = $insert_id";
my $sth2=$dbh->prepare($sql2);
$sth2->execute();

while(my $ref=$sth2->fetchrow_hashref){
	map {_utf8_on $ref->{$_}} keys %$ref ; #��ֹ���ݿ�ĳЩ����δ����utf8���
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
my $database="cnv"; #���ݿ�
my $host='172.16.10.33';#���ݿ�ip
my $port=3306; #���ݿ�˿�
my $db_user='cnv'; #���ݿ��˺�
my $db_password='6L2inux~'; #���ݿ�����

#-------------------------------------#
#�������ݿ�
my $dbh = DBI->connect("DBI:mysql:database=$database;host=$host;port=$port","$db_user","$db_password",{'RaiseError' => 1});
$dbh->do("SET NAMES utf8");
my $insert_id;
#-------------------------------------#
#�����¼�¼
try{
	$dbh->{'AutoCommit'} = 0;   #�ر������Զ��ύ
	if ($dbh->{'AutoCommit'}) {
		die "Cannot start transaction!:$!\n";
	}
	#id hospital run sample test_date chrom start end region type number submitter cytoband binsize note method mosaic 

	my $sql = "insert into cnv (hospital ,run ,sample ,test_date ,binsize,method) values(?,?,?,?,?,?);";
	#my $sth=$dbh->do($sql,undef,("�½�����","SQR170403002", "R170327006","2017-03-27","chrY",24890000,26520000,"chrY:24890000-26520000","gain","3","DGV","",40000,"����",'CHD',0, 100000)); #ִ�в������
	my $sth=$dbh->do($sql,undef,($hospital,$run, $sample,$test_date,$binsize,$method)); #ִ�в������

	$insert_id = $dbh->{q{mysql_insertid}};
	$dbh->commit(); #�ύ����
}catch{
	$dbh->rollback(); #���ִ���ִ�лع�
	die $_;
};

print $insert_id,"\n";

#-------------------------------------#
#ȡ���ղ���ļ�¼
$dbh->{'AutoCommit'} = 1;   #���������Զ��ύ(���δ�ڳ���������AutoCommit,Ĭ����1)��
if (not $dbh->{'AutoCommit'}) {
	die "Cannot start transaction!:$!\n";
}
my $sql2 = "select * from cnv where id = $insert_id";
my $sth2=$dbh->prepare($sql2);
$sth2->execute();

while(my $ref=$sth2->fetchrow_hashref){
	map {_utf8_on $ref->{$_}} keys %$ref ; #��ֹ���ݿ�ĳЩ����δ����utf8���
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

���ݿ�ṹ
+-----------+---------------------------------+-----------------------------+
| Field     | Type                            | Comment                     |
+-----------+---------------------------------+-----------------------------+
| id        | int(10)                         |                             |
| hospital  | varchar(255)                    | ҽԺ                        |
| run       | varchar(40)                     |                             |
| sample    | varchar(40)                     | ������                      |
| test_date | date                            |                             |
| chrom     | varchar(30)                     |                             |
| start     | int(10)                         |                             |
| end       | int(10)                         |                             |
| region    | varchar(255)                    | CNV����                     |
| type      | enum('gain','loss','dup','del') |                             |
| number    | double(10,5)                    | CNV����                     |
| submitter | varchar(255)                    | ����֤���ݿ�                |
| cytoband  | varchar(50)                     |                             |
| binsize   | int(10)                         | ���ڴ�С�����־���          |
| note      | varchar(255)                    | ��ע                        |
| method    | varchar(30)                     | �������:CHD,PGS...         |
| mosaic    | int(10)                         | Ƕ�ϱ���                    |
+-----------+---------------------------------+-----------------------------+
