#!/bin/perl
$result_dir=$ARGV[0];
#$bin_dir=$ARGV[1];
#$site=$ARGV[2];
#$run_id=$ARGV[3];
open OU,">$result_dir\/index2id_YCM.txt" || die "$!";
open IN,"<$result_dir\/index2id.txt" || die "$!";
while(<IN>)
{	
	my @line = split;
	my ($idx, $sample_id) = @line[0,1];
	next if($sample_id !~ /^\d*R/);
	if($line[-1] eq 'Y'){
		print OU "$sample_id\t$idx\n";
#	my $index = $idx;
#	$idx =~ s/IonXpress_0*//;
#        my $info = `python $bin_dir\/YCM/ext_sampleInfo_from_ERP.py $sample_id $site $run_id`; chomp $info;
#	my ($erp_sampleID, $erp_index, $erp_y) = split /,/,$info;
#	if($erp_index eq $idx){
#		if($erp_y eq "y"){
#                       print OU "$sample_id\t$index\n";
#		}
	}#else{  print "!!!WARNING: index of $sample_id is different in ERP and IonProton: erp=$erp_index\tseq=$idx\n";  }
}
close IN;
close OU;
