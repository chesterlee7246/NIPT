#!/bin/perl
if (@ARGV != 2){
        die "Usage: perl $0 linGen_gene_curation_list_GRCh37.tsv *_Cytoband_Annotation.txt\n";
}
open IN,"$ARGV[0]" || die 'no such file' ;
open INT,"$ARGV[1]" || die 'no such file';

my $outfile = $ARGV[1]; $outfile=~s/_Cytoband_Annotation\.txt$/_Cytoband_ClinGen_Annotation.txt/; die if($outfile eq $ARGV[1]);

my %ClinGen;
while(<IN>)
{
        chomp;
        next if(/^#/);
        my @line = split /\t/,$_;
        my ($gene,$location,$haplo_score, $haplo_dscrpt, $triplo_score, $triplo_dscrpt, $update_date) = @line[0,3,4,5,9,10,14];
        my @PMID_haplo = @line[6,7,8];
        my $PMID_haplo = join ",",@PMID_haplo;
        $PMID_haplo = $PMID_haplo=~/\d+/ ? $PMID_haplo : "";

        my @PMID_triplo = @line[11,12,13];
        my $PMID_triplo = join ",",@PMID_triplo;
        $PMID_triplo = $PMID_triplo=~/\d+/ ? $PMID_triplo : "";

        my @info = ($gene, $haplo_score, $haplo_dscrpt, $PMID_haplo, $triplo_score, $triplo_dscrpt, $PMID_triplo, $update_date);
        $ClinGen{$location} = join "\t",@info;
}
close(IN);


my $bool = 0;

open OUT,">$outfile" || die "$!";
print OUT "SampleID\tchrom\tloc.start\tloc.end\tcnv.info\tgene_ClinGen\tHaploinsufficiency_Score\tHaploinsufficiency_Description\tPMID_haplo\tTriplosensitivity_Score\tTriplosensitivity_Description\tPMID_triplo\tDate_Last_Evaluated\n";
while(<INT>)
{
        chomp;
        next if($_=~/^ID/); 
        my @line = split /\t/,$_;
        my $info_cnv = join "\t",(@line[0..3,13]);
        my $chr=$line[1];
	my $start=$line[2];
	my $end=$line[3];      
#	print $chr."\t".$start."\t".$end."\n";       
 
        foreach (sort keys %ClinGen){
		(my $chr_1, $start_1, $end_1)=$_=~/(.*):(\d+)-(\d+)/;
		if($chr eq $chr_1){
			if(($start_1 >= $start && $start_1 <= $end) || ($end_1 >= $start && $end_1 <= $end)){
				print OUT "$info_cnv\t$ClinGen{$_}\n";
				$bool++;
				}
			}
	}
}
		

#        my $gene_list = $line[-1];
#        my @gene_list = split /;/,$gene_list;

#        foreach my$gene(@gene_list){
#                if(exists $ClinGen{$gene}){
#                        print OUT "$info_cnv\t$ClinGen{$gene}\n";
#                        $bool++;
close INT;
close OUT;

#if($bool==0){   `rm $outfile`;  }
