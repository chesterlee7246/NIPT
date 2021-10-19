#!/usr/b/in/perl
use strict;
use warnings;
use utf8;
use Cwd qw /abs_path/;
use Getopt::Long;
use File::Basename;
#use Data::Dump qw'pp';
use List::Util qw/max min/;
our $script_home=abs_path(dirname(__FILE__));
our $YCM_home="$script_home/../";
our (%ignore,%index); #global variable
our ($ignore_file,$samtools,$bedtools,$Rscript,$bin_home,$data_home,$amplicon,$svm_predict,$svm_trait_file,$model,$class,$hg19); #config file
our ($sample,$bin_size,$out_dir,$control,$config,$svm_out,$format,$name); #params
our ($region); #for png coordinate lower and upper
our %regions=(
	AZF=>[14252761,28557769],
	YS=>[2649806,28557769],
	AZFBC=>[19560684,28557769],
); 

&check_params();
&import_config($config);
if($format eq "bed"){
	$sample=&bedtobam($sample,$name);
}
&generate_report($sample);

sub usage{
	print STDERR <<USAGE;
		perl $0 --sample <sample.bam> --format <bam|bed> --name <prefix of output file>  --config <config.ini> --binsize <40000> --outdir  <outdir> --control <controlfile.list> --svm_out <out.txt> --region <AZF|YS|AZFBC>
		
USAGE
exit;
}


sub check_params{
	GetOptions(
		"sample|s=s"=>\$sample,
		"name|n=s"=>\$name,
		"format|f=s"=>\$format,
		"binsize|b=i"=>\$bin_size,
		"outdir|o=s"=>\$out_dir,
		"control|c=s"=>\$control,
		"config=s"=>\$config,
		"svm_out|m=s"=>\$svm_out,
		"region=s"=>\$region,
	);

	if(not defined $sample){
		&usage();
	}

	$config ||= "$YCM_home/config/config.ini"; 
	$bin_size ||= 40000 ;
	$out_dir ||= "./";
	$region ||= "YS";
	$format ||= "bam";
	$region = uc $region;
	if(not defined $regions{$region}){
		$region="YS";
	}
	if($format =~ /BED/i){
		$format='bed';
	}elsif($format =~/BAM/i){
		$format="bam";
	}else{
		$format="bam";
	}
	$name ||= basename($sample);
	$name  =~s/\.(bam|bed)$//gi;
}

sub bedtobam($$){
	my ($bed_file,$name)=@_;
	my $bam_tmp="$out_dir/$name.tmp.bam";
	my $bam="$out_dir/$name.bam";
	system("$bedtools bedtobam -i $bed_file -g $hg19  > $bam_tmp") and die "Cannot convert bed to bam!\n";
	system("$samtools sort  $bam_tmp  -o $bam") and die "Cannot sort bam!\n";
	system("$samtools index $bam") and die "Cannot index $bam!\n";
	return $bam;
}

sub import_config($){
	my $file=shift;
	open my $fh, "$file" or die "Couldn't open the configuration file '$file'.\n";
	my $eval_string = join "", <$fh>;
	close $fh;
	eval $eval_string;
	die "Couldn't interpret the configuration file ($file) that was given.\nError details follow: $@\n" if $@;
}

sub generate_depth($){
	my $bam=shift;
	(my $prefix=basename($bam))=~s/\.bam//gi;
	my $depth_file="$out_dir/$prefix.depth";
	(my $tmp_bam=$bam)=~s/\.bam/\.bai/g;
	if(not (-e "$bam.bai" or -e $tmp_bam)){
		system("$samtools index $bam") and die "Cannot create index for $bam\n";
	}
	system("$samtools depth -r chrY $bam >$depth_file") and die "Cannot calculate depth for $bam\n";
	return $depth_file;	
}

sub generate_report($){
	my ($bam)=@_;
	my $bins_file=&generate_bins($bam);
        #my $bins_file=&generate_bins($bam)."bak";
	(my $prefix=basename($bam))=~s/\.bam$/.log/g;
	my $log="$out_dir/$prefix";
	my ($start,$end)=@{$regions{$region}};
	my $cmd="$Rscript $script_home/cnv.R -f $bins_file -s $bin_size -d $amplicon -l $log --start $start --end $end";
	my $control_binsize_file=undef;
	if(defined $control){
		$control_binsize_file=&parse_control($control);
		$cmd .= " -c ".$control_binsize_file;
	}
	system($cmd) and die "Cannot generate the report for $bam!\n";

	my $result=&generate_predict_report($bam);
	my %hash=&parse_log($log);
#	my $fh=*STDOUT;
	my $fh;
	if(defined $svm_out){
		open $fh,">$out_dir/$svm_out" or die $!;
	}
	my $last_result=&generate_last_result(\%hash,$result);
	(my $last_file=basename($bam))=~s/\.bam/.last.txt/g;
	$last_file="$out_dir/$last_file";
	(my $tmp=$bam)=~s/\.bam//g;
	my ($chr,$sample,$index)=split /-/,$tmp;
	print $last_file ,"\n";
	open my $last_fh,">","$last_file" or die $!;
	print $last_fh "#sample\tindex\tclass\trange\tsize\n";
	print $last_fh "$sample\tIonXpress_$index\t$last_result\n";
	close $last_fh;
	print $fh "SVM predicted result:", join("\t",$result);
	close $fh;
	#unlink $bins_file;
	if(defined $control_binsize_file){
		open my $cfh,"<",$control_binsize_file or die $!;
		while(<$cfh>){
			chomp;
			unlink $_ if -e $_;
		}
		close $cfh;
	}
}

sub generate_last_result{
	my ($dnacopy,$svm)=@_;
	my ($class,$range,$size,$prob)=split /\t/,$svm;
	open my $amp,"<",$amplicon or die $!;
	my %hash=();
	while(<$amp>){
		chomp;
		next if /^chromosome/i;
		my ($chr,$start,$end,$region,undef)= split /\t/;
		$hash{$region}{$start}=$end;
	}
	my $result="";
	if(not defined $dnacopy->{del} and not defined $dnacopy->{dup}){
		$result="正常\tNULL\tNULL";
	}else{
		if($prob>0.35 and $class ne "OK"){
			$class=~s/\s*del/缺失/g;
			$class=~s/\s*dup/重复/g;
			$result="$class\t$range\t$size";
		}else{
			my @tmp_n=();
			my @tmp_r=();
			my @tmp_s=();
			for my $start(keys %{$dnacopy->{del}}){
				push @tmp_n,&AZF_judegment($start,$dnacopy->{del}{$start})."缺失";
				push @tmp_r,"chrY:$start-$dnacopy->{del}{$start}";
				push @tmp_s,&generate_size($start,$dnacopy->{del}{$start});
			}
			for my $start (keys %{$dnacopy->{dup}}){
				push @tmp_n,&AZF_judegment($start,$dnacopy->{dup}{$start})."重复";
				push @tmp_r,"chrY:$start-$dnacopy->{dup}{$start}";
				push @tmp_s,&generate_size($start,$dnacopy->{dup}{$start});
			}
			$result=join(";",@tmp_n)."\t".join(";",@tmp_r)."\t".join(";",@tmp_s);
		}
	}
	return $result;
}
#***************AZFa ,AZFb+c判断函数************************
sub AZF_judegment{
    my @begin=(14352761,19964826);
	my @stop= (15154862,27793830);
    my ($start,$end)=@_;
	my @rate=();
	for (my $i=0;$i<@begin;$i++){
	   if ($begin[$i]<=$end && $stop[$i] >=$start){
	      $rate[$i]=(min($stop[$i],$end)-max($begin[$i],$start)+1)/(max($stop[$i],$end)-min($begin[$i],$start)+1);
		  next;
	    }
	}
	
	if(@rate){
	   my $num=@rate;
	   if ($rate[$num-1]>=0.6){
	      if ($num==1){return "AZFa";}
		  else {return "AZFb+c";}
	    }
	   else {
	      return "chrY:"."$start-$end";
	    } 
	}
	else{
	   return "chrY:"."$start-$end";
	}
		
}
#*****************************************************
sub generate_size{
	my ($start,$end)=@_;
	my %units=(
		M=>1000000,
		K=>1000,
	);
	my $range=$end-$start+1;
	my $result="";
	if(int($range/$units{M})){
		$result=sprintf("%.1fMb",$range/$units{M});
	}else{
		$result=sprintf("%dKb",int($range/$units{K}));
	}
	return $result;
}

sub parse_log{
	my $log=shift;
	open my $fh,"<","$log" or die $!;
	my %hash=();
	while(<$fh>){
		chomp;
		my ($sample_name,$delinfo,$dupinfo)=split /\t/;
		my @delinfo = split /;/ , $delinfo;
		my @dupinfo = split /;/ , $dupinfo;
		if(@delinfo){
			for my $d(@delinfo){
				my ($chr,$start,$end)= $d=~/(chrY):(\d+)-(\d+)/i;
				$hash{del}{$start}=$end;
			}
		}
		if(@dupinfo){
			for my $d(@dupinfo){
				my ($chr,$start,$end)= $d=~/(chrY):(\d+)-(\d+)/;
				$hash{dup}{$start}=$end;
			}
		}
	}
	return %hash;
}

sub parse_control($){
	open my $fh,"<",$control or die $!;
	my $control_file="$out_dir/control.$bin_size.txt";
	open my $ct,">",$control_file or die $!;
	while(<$fh>){
		chomp;
		print $ct &generate_bins($_),"\n";
	}
	close $fh;
	close $ct;
	return $control_file;
}

sub generate_bins($){
	my $bam=shift;
	my $depth_file=&generate_depth($bam);#generate depth file
	&loaded_ignore_region();#generate %ignore
	open my $fh ,"<" , "$depth_file" or die $!;
	while(<$fh>){
		next if /^\s*$/;
		chomp;
		my ($chr,$position,$depth,$ignore)=split /\t/;
		$index{$chr}{int(($position-1)/$bin_size)}{total_depth} += $depth;
		if(defined $ignore and $ignore eq "ignore"){
			$index{$chr}{int(($position-1)/$bin_size)}{ignore}="ignore";
		}
	}
	close $fh;

	for my  $chr (sort keys %ignore){
		for my $p (sort {$a <=> $b} keys %{$ignore{$chr}}){
			for my $index ($p .. $ignore{$chr}{$p}){
				$index{$chr}{$index}{ignore}="ignore";
			}
		}
	}
	no warnings;
	open my $dp,">","$depth_file.bins" or die $!;
	for my $chr (sort keys %index){
		my ($last,undef )= sort {$b <=> $a} keys %{$index{$chr}};
		for (my $i=0;$i<=$last;$i++){
			print $dp "$chr\t", $i*$bin_size+1, "\t", ($i+1)*$bin_size,"\t",$index{$chr}{$i}{total_depth}/$bin_size,"\t$i\t",$index{$chr}{$i}{ignore},"\n";
		}
	}
	use warnings;
	close $dp;
	unlink $depth_file;
	return "$depth_file.bins";
}

sub loaded_ignore_region{
	open my $ignore_fh ,"<" ,"$ignore_file" or die $!;
	while(<$ignore_fh>){
		chomp;
		next if /^#/;
		my ($chr,$start,$end,$note)=split /\t/;
		$ignore{$chr}{int(($start-1)/$bin_size)}=int(($end-1)/$bin_size);
	}
	close $ignore_fh;
}

sub generate_svm_trait($){
	my $bam=shift;
	my @result=`samtools bedcov $svm_trait_file $bam`;
	my %bs=();

	for my $line(@result){
		my ($chr,$start,$end,$regions,$note,$basepairs)=split /\t/,$line;
		$bs{$note}{depth} += $basepairs/($end-$start);
		$bs{$note}{cn}++;
	}
	my @regions= qw/b5b6 p3_p4 b1_4  g  Gr r  t  u2 u3 y1_y2 y3_y4/;
	my $svm_input_file="$out_dir/$name.svm.input";

	open my $fh,">",$svm_input_file or die $!;
	my $i=1;
	print $fh "0\t",join("\t" ,map { $i++.":".sprintf("%.4f",$bs{$_}{depth}/($bs{control}{depth}/$bs{control}{cn}))} @regions),"\n";
	close $fh;
	return $svm_input_file;
}

sub svm_predict($){
	my $bam=shift;
	my $file=&generate_svm_trait($bam);
	my $output_file="$out_dir/$name.svm.output";
	system("$svm_predict -b 1 $file $model $output_file") and die "Cannot predict the status of YCM";
	return $output_file;
}

sub generate_predict_report($){
	my $bam=shift;
	my $file=&svm_predict($bam);
	open my $fh,"<",$file or die $!;
	my ($labels,$prob)=<$fh>;
	close $fh;
	my @labels=split " ",$labels;
	my @prob=split " ",$prob;
	my $p=0;
	for (my $i=1;$i<@prob;$i++){
		if($labels[$i] eq $prob[0]){
			$p=$prob[$i];
			last;
		}
	}
	return &interpret_svm_out($prob[0])."\t$p";
}

sub interpret_svm_out($){
	my $id=shift;
	open my $fh,"<",$class or die $!;
	while(<$fh>){
		chomp;
		if(/^$id\s+/){
			my ($id,$desc,$number,$regions,$size)=split /\s+/ ;
			return join("\t",($desc,$regions,$size));
		}
	}
}

