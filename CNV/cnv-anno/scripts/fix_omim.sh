#remove duplcates lines in intermediates/omim_coding_genes.bed
sort ../intermediates/omim_coding_genes.bed | uniq -u > ../intermediates/omim_coding_genes_u.bed
sort -k1,1V -k2,2 -k3,3 ../intermediates/omim_coding_genes_u.bed > ../intermediates/omim_coding_genes.bed
rm ../intermediates/omim_coding_genes_u.bed

#Get genes that have duplicate records in refseq_coding_genes.txt
cut -f4 ../intermediates/refseq_coding_genes.txt | sort | uniq -c | sort -rn | head -20 | awk '$1==2 {print $2}' | sort > ../intermediates/refseq_dupgenes.txt

#find out which refseq duplcat genes are in Omim
grep -f ../intermediates/refseq_dupgenes.txt -w ../intermediates/omim_coding_genes.bed > ../intermediates/omim_inter_refseq_dupgenes.txt

#exclude duplcate genes in refseq from omim_coding_genes.bed
grep -f ../intermediates/refseq_dupgenes.txt -v  -w ../intermediates/omim_coding_genes.bed > ../intermediates/omim_no_refseq_dupgenes.txt

#get omim intersect of refseq dupgene records
grep -f ../intermediates/omim_inter_refseq_dupgenes.txt  -w ../intermediates/refseq_coding_genes.txt | cut -f1-4 > ../intermediates/refseq_dupgenes_records.txt

#combine dupgene records and omim_no_refseq_dupgenes.txt
cat ../intermediates/omim_no_refseq_dupgenes.txt ../intermediates/refseq_dupgenes_records.txt > ../intermediates/omim_coding_genes_new.bed

#sort 
sort -k1,1V -k2,2 -k3,3 ../intermediates/omim_coding_genes_new.bed > ../intermediates/omim_coding_genes_new_srt.bed

#change omim_coding_gens_new_srt.bed to omim_coding_genes.bed
mv ../intermediates/omim_coding_genes_new_srt.bed ../intermediates/omim_coding_genes.bed

#remove intermediates files
rm ../intermediates/omim_coding_genes_new.bed
rm ../intermediates/omim_in_refseq_dupgenes.txt
rm ../intermediates/omim_inter_refseq_dupgenes.txt
rm ../intermediates/omim_no_refseq_dupgenes.txt
rm ../intermediates/refseq_dupgenes.txt
rm ../intermediates/refseq_dupgenes_records.txt

