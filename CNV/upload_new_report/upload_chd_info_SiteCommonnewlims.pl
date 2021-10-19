#!/usr/bin/perl -w
use strict;
unless(@ARGV==2){	die "perl $0 result_dir bin_dir\n";	}
my ($result_dir, $bin_dir) = @ARGV;

if($result_dir =~ /\./){
	my $tmp = `pwd`;chomp $tmp;
	$result_dir =~ s/\./$tmp/;
}
$result_dir =~ /analysis\/CNV\/(\w+)\//;
my $site = $1;
print "$site\t$result_dir\n";

my $f1=$ARGV[0]."/expMeta.dat";
my $f2=$ARGV[0]."/BaseCaller.json";
my $f3=$ARGV[0]."/analysis.bfmask.stats";

my $p1=$ARGV[1]; ##½Å±¾Ä¿Â¼

open(F1,$f1);
open(F2,$f2);
open(F3,$f3);

my ($run_name, $instrument) = ("","");
while(<F1>)
{
	if($_=~/^Run Name/){
		$_=~s/\s+//g;
		my @tmp=split /[\_\-\.]/,$_;
		
		for(my $i=0;$i<=$#tmp;$i++){
			if($tmp[$i]=~/^SQR/){	$run_name=$tmp[$i];next;	}
		}
	}elsif($_=~/^Instrument/){
		$_=~s/\s+//g;
		my @tmp=split /\=/,$_;
		$instrument=$tmp[1];
	}
}
close(F1);

my ($polyclonal, $low, $final, $gb);
while(<F2>)
{
	my $info = $_;
	$_=~s/\s+//g;	$_=~s/\,//g;
	my @tmp=split /\:/,$_;

	if($info=~/\"filtered_polyclonal\"/){	$polyclonal=$tmp[1];	}
	elsif($info=~/\"filtered_low_quality\"/){	$low=$tmp[1];	}
	elsif($info=~/\"final_library_reads\"/){	$final=$tmp[1];	}
	elsif($info=~/\"final\"/){	$gb=$tmp[1];	}
}
close(F2);

my ($total, $empty, $bead, $live, $exclud);
while(<F3>)
{
	my $info = $_;
	$_=~s/\s+//g;
	my @tmp=split /\=/,$_;

  if($info=~/^Total Wells/){	$total=$tmp[1];	}
  elsif($info=~/^Excluded Wells/){	$exclud=$tmp[1];	}
  elsif($info=~/^Empty Wells/){	$empty=$tmp[1];	}
  elsif($info=~/^Bead Wells/){	$bead=$tmp[1];	}
  elsif($info=~/^Live Beads/){	$live=$tmp[1];	}
}
close(F3);

my $reads=$final/1000000; $reads=sprintf("%.1f",$reads);
my $Gb=$gb/1000000000; $Gb=sprintf("%.1f",$Gb);
my $len=int($gb/$final);
my $isp=($bead/($total-$exclud))*100; $isp=sprintf("%.1f",$isp);
my $Empty=100-$isp; $Empty=sprintf("%.1f",$Empty);
my $enrich=($live/$bead)*100; $enrich=sprintf("%.1f",$enrich);
my $no=100-$enrich; $no=sprintf("%.1f",$no);
my $Polyclonal=($polyclonal/$live)*100; $Polyclonal=sprintf("%.1f",$Polyclonal);
my $clonal=100-$Polyclonal; $clonal=sprintf("%.1f",$clonal);
my $Low=($low/($live-$polyclonal))*100; $Low=sprintf("%.1f",$Low);
my $Final=($final/($live-$polyclonal))*100; $Final=sprintf("%.1f",$Final);

$reads.="Mb"; $Gb.="Gbp"; $len.="bp"; $isp.="%"; $Empty.="%"; $enrich.="%"; $no.="%"; $Polyclonal.="%"; $clonal.="%"; $Low.="%"; $Final.="%";

my %report_file=();
my %png1=();
my %png2=();
opendir(DIR,$result_dir);
while(my $file=readdir(DIR))
{	
	if($file=~/^IonXpress_0*(\d+)_/){
		my $index = $1;
		
		if($file=~/CytoBand_Mosaic.png$/){	$png2{$index}=$file;	}
		elsif($file=~/Extract_CNV.png$/){	$png1{$index}=$file;	}
		elsif($file=~/100Kb_Cytoband_Annotation_Report.txt$/){	$report_file{$index}=$file;	}
	}
}
closedir(DIR);

my %id = ();
my $indexf = "$result_dir\/index2id.txt";
open(IDF,$indexf);
while(<IDF>)
{
	chomp($_);
	my @tmp=split /\t/,$_;
	my ($index, $name) = @tmp[0,1];
	$index =~ s/IonXpress_0*//;
	$id{$index} = $name;
}
close(IDF);

foreach my$index(sort {$a<=>$b} keys %png1)
{
	my $name = $index<10 ? "0".$index : $index;
	$name = "IonXpress_0".$name;
	my $rawReads_info = `grep total_reads $result_dir\/$name\_BamDuplicates.json`;
	my @tt0 = split /\s/,$rawReads_info;
	my $rawReads = $tt0[-1];	

	my $tmp4unique = `head -1 $result_dir\/$name\_rawlib_rmdup_MAPQ10_Nbin.txt`; chomp $tmp4unique;
	my @tt4unique = split /\s/,$tmp4unique;
	my $uniqReads = $tt4unique[-1];

	my $cov_info=`grep Cov $result_dir\/$name\_rawlib_rmdup_unique_Cov.txt`;
	my @tt4= split /\s/,$cov_info;
	my $cov=$tt4[-1]; $cov=sprintf("%.2f",$cov*100)."%";

	my $Scatterplot = $result_dir."/".$png1{$index};
	my $Cytoband = $result_dir."/".$png2{$index};
	my $cnv = "";
	my $cnvsize = "";
	my $result_reading = "";

	my (%CNV, @aneuploid, @microCNV);
	if(exists $report_file{$index}){
		my $cnvf=$result_dir."/".$report_file{$index};
		open(CF,$cnvf);
		while(<CF>){
			next if $_=~/^ID/;
			chomp($_);
			my @tmp=split /\t/,$_;
			my $final_result = $tmp[13];
			my $size = $tmp[8];

			my ($chr, $s) = @tmp[1,2];
			$chr =~ s/chr//;
			my $chr_chinese = $chr=~/[XY]/ ? $chr : $chr."号";

			if($size>=(1000*1000) || ($size<(1000*1000) && ($_=~/Decipher_Syndrome/i ||($_=~/Decipher/i && $_=~/pathogenic/i)||($_=~/ISCA/i && $_=~/pathogenic/i))) ){
				if($final_result=~/d[elup]+/){
					$final_result =~ /(d[elup]+)(\(\S+\)).seq\[GRCh37\/hg19\]\((\S+)-(\S+)\)X/;
					my ($type, $region, $ss, $ee) = ($1, $2, $3, $4);
					my $cc = $type.$region;
					if(!exists $CNV{$cc}){  push @microCNV, $cc;    }

					my $type_chinese = $type eq "dup" ? "重复" : "缺失" ;
				
#               my $s = join("",(split(/,/,$ss)));
#               my $e = join("",(split(/,/,$ee)));
#					my $abs_size = ($e-$s+1)/1000000;
#               $abs_size = $abs_size."Mb";
					
					$CNV{$cc}[0] += $size/(1000*1000);

					$region =~ s/\(//g; $region =~ s/\)//g;
					my $tt = $final_result =~ /mosaic/i ? "嵌合" : "发生";
					$CNV{$cc}[1] = $chr_chinese."染色体的".$region."区域".$tt.($size/1000000)."Mb".$type_chinese;
   			}else{
					$final_result =~ /([\+\-]+[\w\.\(\)]+)/;
					my $cc = $1;
					if(!exists $CNV{$cc}){  push @aneuploid, $cc;   }
	
					my $type = $final_result=~/^-/ ? "单体" : "三体" ; 
					if($final_result =~ /mosaic/i){ $type = "嵌合".$type;       }

					$CNV{$cc}[0] += $size/(1000*1000);
					$CNV{$cc}[1] = $chr_chinese."染色体".$type;
   			}

#				my $final_size = sprintf("%.2f",($size/1000000))."Mb";
			}
		}
		close(CF);
	}
	my @arr_CNV = (@aneuploid, @microCNV);

	if(scalar(@arr_CNV)==0){
		$cnv = "null";
		$cnvsize = "null";
		$result_reading = "null";
	}else{
		my (@arr_cnv, @arr_size, @arr_reading);
		foreach my$key(@arr_CNV){
			push @arr_cnv, $key;
			push @arr_size, sprintf("%.2f",$CNV{$key}[0])."Mb";
			push @arr_reading, $CNV{$key}[1];
		}
		$cnv = join ";",@arr_cnv;
		$cnvsize = join ";",@arr_size;
		$result_reading = join ",",@arr_reading;
		$result_reading .= "";
	}
	$cnv = "'$cnv'";
	$cnvsize = "'$cnvsize'";
	$result_reading = "'$result_reading'";
	print $cnv,$cnvsize,$result_reading;
	my $idx = $id{$index};

	my $select_y = "False";
	if(not system("grep '$idx' $result_dir\/index2id_YCM.txt")){
		$select_y = "True";
		my ($sample_ID, $Ion_index, $Y_type, $Y_region, $Y_size);

		my $tmp = $index<10 ? "00".$index : "0".$index;
		open INY,"<$result_dir\/ChrY-$idx\-$tmp\.last.txt" || die "$!";
		while(<INY>){
			next if(/^#/);
			chomp;
			($sample_ID, $Ion_index, $Y_type, $Y_region, $Y_size) = split /\t/,$_;
			$Y_type =~ s/\s+//g;
		}
		close INY;

		my $Y_pic = "$result_dir\/ChrY-$idx\-$tmp\.png";

		print "$site $run_name $reads $Gb $len $isp $enrich $clonal $Final $Empty $no $Polyclonal $Low $instrument $idx $index $cnv $cnvsize $result_reading $Scatterplot $Cytoband $rawReads $uniqReads $select_y $Y_type $Y_size $Y_region $Y_pic \n";
        system("python $bin_dir/uploadCNVnew.py $idx $reads $Gb $len $isp $enrich $clonal $Final $Empty $no $Polyclonal $Low $instrument $run_name $index $rawReads $uniqReads $cov $cnv $cnvsize $result_reading $Scatterplot $Cytoband $select_y '$Y_type' '$Y_size' '$Y_region' '$Y_pic' ");
		#system("python $p1/chd_rpc_$site\.py $run_name $reads $Gb $len $isp $enrich $clonal $Final $Empty $no $Polyclonal $Low $instrument $idx $index $cnv $cnvsize $result_reading $Scatterplot $Cytoband $rawReads $uniqReads $select_y '$Y_type' '$Y_size' '$Y_region' '$Y_pic' ");
#		system("python $p1/chd_rpc_SiteCommon.py $site $run_name $reads $Gb $len $isp $enrich $clonal $Final $Empty $no $Polyclonal $Low $instrument $idx $index $cnv $cnvsize $result_reading $Scatterplot $Cytoband $rawReads $uniqReads $select_y '$Y_type' '$Y_size' '$Y_region' '$Y_pic' ");
	}else{
		print "$site $run_name $reads $Gb $len $isp $enrich $clonal $Final $Empty $no $Polyclonal $Low $instrument $idx $index $cnv $cnvsize $result_reading $Scatterplot $Cytoband $rawReads $uniqReads $select_y\n";
	   system("python $bin_dir/uploadCNVnew.py $idx $reads $Gb $len $isp $enrich $clonal $Final $Empty $no $Polyclonal $Low $instrument $run_name $index $rawReads $uniqReads $cov $cnv $cnvsize $result_reading $Scatterplot $Cytoband $select_y");

		#system("python $p1/chd_rpc_$site\.py $run_name $reads $Gb $len $isp $enrich $clonal $Final $Empty $no $Polyclonal $Low $instrument $idx $index $cnv $cnvsize $result_reading $Scatterplot $Cytoband $rawReads $uniqReads '$select_y'");
#		system("python $p1/chd_rpc_SiteCommon.py $site $run_name $reads $Gb $len $isp $enrich $clonal $Final $Empty $no $Polyclonal $Low $instrument $idx $index $cnv $cnvsize $result_reading $Scatterplot $Cytoband $rawReads $uniqReads '$select_y'");
	}
#	system("python push_cnv_data.py $idx $reads $Gb $len $isp $enrich $clonal $Final $Empty $no $Polyclonal $Low $instrument $run_name $index $rawReads $uniqReads $cnv $cnvsize $result_reading $Scatterplot $Cytoband $select_y $Y_type $Y_size $Y_region $Y_pic");
}
