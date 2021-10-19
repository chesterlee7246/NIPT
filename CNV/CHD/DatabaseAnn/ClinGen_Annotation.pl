#!/usr/bin/perl -w
use strict;
unless(@ARGV==2){	die "perl $0 bin_dir/ClinGen_gene_curation_list_GRCh37.tsv *_Cytoband_Annotation.txt\n";	}
open(F1,$ARGV[0]); ##ClinGen
open(F2,$ARGV[1]); ##Annotation Report

my $outfile = $ARGV[1]; $outfile=~s/_Cytoband_Annotation\.txt$/_Cytoband_ClinGen_Annotation.txt/; die if($outfile eq $ARGV[1]);

my %ClinGen;
while(<F1>)
{
	chomp;
	next if(/^#/);
	my @line = split /\t/,$_;
	my ($gene, $haplo_score, $haplo_dscrpt, $triplo_score, $triplo_dscrpt, $update_date) = @line[0,4,5,9,10,14];

	my @PMID_haplo = @line[6,7,8];
	my $PMID_haplo = join ",",@PMID_haplo;	
	$PMID_haplo = $PMID_haplo=~/\d+/ ? $PMID_haplo : "";

	my @PMID_triplo = @line[11,12,13];
	my $PMID_triplo = join ",",@PMID_triplo;
	$PMID_triplo = $PMID_triplo=~/\d+/ ? $PMID_triplo : "";

	my @info = ($gene, $haplo_score, $haplo_dscrpt, $PMID_haplo, $triplo_score, $triplo_dscrpt, $PMID_triplo, $update_date);
	$ClinGen{$gene} = join "\t",@info;
}
close(F1);

my $bool = 0;

open OUT,">$outfile" || die "$!";
print OUT "SampleID\tchrom\tloc.start\tloc.end\tcnv.info\tgene_ClinGen\tHaploinsufficiency_Score\tHaploinsufficiency_Description\tPMID_haplo\tTriplosensitivity_Score\tTriplosensitivity_Description\tPMID_triplo\tDate_Last_Evaluated\n";
while(<F2>)
{
	chomp;
	next if(!/OmimGene/);

	my @line = split /\t/,$_;
	my $info_cnv = join "\t",(@line[0..3,13]);

	my $gene_list = $line[-1];
	my @gene_list = split /;/,$gene_list;

	foreach my$gene(@gene_list){
		if(exists $ClinGen{$gene}){
			print OUT "$info_cnv\t$ClinGen{$gene}\n";
			$bool++;
		}
	}
}
close F2;
close OUT;

if($bool==0){	`rm $outfile`;	}
