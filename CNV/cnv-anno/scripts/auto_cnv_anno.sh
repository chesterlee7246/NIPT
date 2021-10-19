#/usr/bin/bash

#run this script with the command: sh auto_cnv_anno.sh in_file out_file
#specify the input and output file

db=../databases/
#files used by build_gene_db.py
gencode=${db}gencode.v19.annotation.gff3.gz
refgene=${db}ref_GRCh37.p13_top_level.gff3.gz
hi_bed=${db}ClinGen_haploinsufficiency_gene_GRCh37.bed
ts_bed=${db}ClinGen_triplosensitivity_gene_GRCh37.bed
lof=${db}PVS1.LOF.genes.hg19
coord_web=${db}coordinates_from_web.txt
#files used by build_cnv_db.py
gnomad=${db}gnomad_v2.1_sv.sites.vcf_hg19.gz
dgv=${db}DGV.GS.March2016.50percent.GainLossSep.Final.hg19.gff3.gz
decipher=${db}Decipher_Patient_Info_E2C.txt
clingen=${db}ClinGen_region_curation_list_GRCh37.tsv

#scores used to filter both hi/ts genes and pathogenic CNV
score_list=['3']

echo "build gene databases for cnv-anno"
python3 build_gene_db.py $gencode $refgene $hi_bed $ts_bed $lof $coord_web $score_list

echo "build cnv database for cnv-anno"
python3 build_cnv_db.py $gnomad $dgv $decipher $clingen  $score_list


