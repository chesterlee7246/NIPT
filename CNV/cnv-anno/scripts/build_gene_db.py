#-*-coding:utf-8-*-
#!/home/bioinfo/local/bin/python3

import os, sys, argparse
import gzip
from collections import defaultdict

def ParseArg():
    p = argparse.ArgumentParser(description="generate Gene database for cnv-anno with python build_gene_db.py gencode")
    p.add_argument("gencode",type=str, help="gencode gff file for hg19")
    p.add_argument("refgene", type=str, help="refgene gff file for hg19")
    p.add_argument("hi_bed", type=str, help="ClinGen_haploinsufficiency_gene_GRCh37.bed")
    p.add_argument('ts_bed', type=str, help="ClinGen_triplosensitivity_gene_GRCh37.bed")
    p.add_argument('lof', type=str, help="acmg 2015 PVS1.LOF.genes.hg19")
    p.add_argument('coord_web', type=str, help="coordinates from NCBI for genes that are not included in gencode and refgene")
    p.add_argument("score_list",type=list, help="The scores used to filter the Clingen curated genes")
    if len(sys.argv)==1:
        print >>sys.stderr,p.print_help()
        sys.exit(0)
    return p.parse_args()

def info_dict(region_info):
    infos = region_info.split(';')
    dic = defaultdict(str)
    for info in infos:
        k, v = info.split('=')[0], info.split('=')[1]
        dic[k] = v
    return dic


def get_all_gencode_regions(gencode):
    """
    find protein coding gene regions from gencode.v19.annotation.gff3.gz
    """
    f_out1 = open('../intermediates/gencode_regions.bed', 'w')
    all_genes = defaultdict(list)
    with gzip.open(gencode, 'rt') as fg:
        for line in fg:
            if line.startswith('#'):
                continue
            line = line.strip().split('\t')
            info_dic = info_dict(line[-1])
            if line[2] != 'gene' or info_dic['gene_type'] != 'protein_coding':
                continue
            gene_type = info_dic['gene_type']
            gname = info_dic['gene_name']
            info = [line[0], line[3], line[4],gene_type]
            all_genes[gname].append(info)
        
        #把相同基因名的几个区域合并成最大的
        gene_merged_dict = {}
        protein_coding_regions = {}
        for gene in all_genes:
            info = all_genes[gene]
            if len(info) == 1:
                gene_type = info[0][-1]
                if gene_type == 'protein_coding':
                    protein_coding_regions[gene] = info[0][:3] + [gene, 'protein_coding']
                res = info[0][:3] + [gene, gene_type]
                f_out1.write('\t'.join(res) +'\n')
                if gene not in gene_merged_dict:
                    gene_merged_dict[gene] = res
            else:
                types = set(x[-1] for x in info)
                if len(types) != 1:
                    if 'protein_coding' in types:
                        gene_type = 'protein_coding'
                else:
                    gene_type = list(types)[0]
                start = min([int(x[1]) for x in info])
                end = max([int(x[2]) for x in info])
                if gene_type == 'protein_coding':
                    protein_coding_regions[gene] = [info[0][0], str(start), str(end), gene, 'protein_coding']
                new_res = [info[0][0], str(start), str(end), gene, gene_type]
                f_out1.write('\t'.join(new_res) + '\n')
                if gene not in gene_merged_dict:
                    gene_merged_dict[gene] = new_res
    f_out1.close()

    fweb = open('../databases/coordinates_from_web.txt')
    for line in fweb:
        if line.startswith('#'):
            continue
        line = line.strip().split('\t')
        if line[4] == 'Protein_coding' and line[3] not in protein_coding_regions:
            protein_coding_regions[line[3]] = line[:5]
    os.system('sort -V -k1,1 -k2,2 -k3,3  ../intermediates/gencode_regions.bed -o ../intermediates/gencode_protein_regions.bed')
    os.system('rm ../intermediates/gencode_regions.bed')
    return gene_merged_dict

def get_all_refgene_regions(refgene):
    fout = open('../intermediates/refgene_regions.bed', 'w')
    gene_region_dict = {}
    with gzip.open(refgene, 'rt') as f:
        for line in f:
            if line.startswith('#'):
                continue
            line = line.strip().split('\t')
            if line[2] == 'gene' and line[0].startswith('NC'):
                if line[0] == 'NC_012920.1':
                    chrom = 'chrM'
                else:
                    chrom = line[0].split('.')[0][-2:]
                    if int(chrom) == 23:
                        chrom = 'chrX'
                    elif int(chrom) == 24:
                        chrom = 'chrY'
                    else:
                        chrom = 'chr' + str(int(chrom))
                start = line[8].index('Name=') + len('Name=')
                end = line[8][start:].index(';')
                gene_name = line[8][start:start+end]
                info = [chrom, line[3], line[4]]
                if gene_name not in gene_region_dict:
                    gene_region_dict[gene_name] = [info]
                else:
                    gene_region_dict[gene_name].append(info)
        
        #把相同基因名的几个区域合并成最大的
        gene_merged_dict = {}
        for gene in gene_region_dict:
            infos = gene_region_dict[gene]
            if len(infos) == 1:
                res = infos[0] + [gene]
                if gene not in gene_merged_dict:
                    gene_merged_dict[gene] = res
                fout.write('\t'.join(res) + '\n')
            else:
                chrom = infos[0][0]
                start = min([int(x[1]) for x in infos])
                end = max([int(x[2]) for x in infos])
                res = [chrom, str(start), str(end), gene]
                if gene not in gene_merged_dict:
                    gene_merged_dict[gene] = res
                fout.write('\t'.join(res) + '\n')
    f.close()
    fout.close()
    os.system('sort -V -k1,1 -k2,2 -k3,3  ../intermediates/refgene_regions.bed -o ../intermediates/refgene_regions.bed')
    return gene_merged_dict

def make_alias_db():
    os.system("""gzip -cd ../databases/Homo_sapiens.gene_info.gz | awk '{if($1==9606) print $3"\t" $5}' > ../intermediates/gene_alias_database.txt""")
    return

#get HI and TS gene coordinates
def get_hits_coord(score_list, in_file, out_file):
    f = open(in_file, 'r')
    fout = open(out_file, 'w')
    f.readline()
    for line in f:
        line = line.strip().split('\t')
        if line[4] in score_list:
            fout.write('\t'.join(line) + '\n')
    f.close()
    fout.close()
    return


def get_alias(gene, alias_db):
    alias = set()
    falias = open(alias_db, 'r')
    for line in falias:
        line = line.strip().split('|')
        if gene in line:
            alias |= set(line)
    falias.close()
    return list(alias)


def coord_web(coord_web_file):
    f = open(coord_web_file, 'r')
    coord_dict ={}
    for line in f:
        if line.startswith('#'):
            continue
        line = line.strip().split('\t')
        if line[3] not in coord_dict:
            coord_dict[line[3]] = [line[0], line[1], line[2], line[4]]
    return coord_dict


def get_coord_for_gene(genes, gene_merged_dict, alias_db, gene_coord_file):
    fout = open(gene_coord_file, 'w')
    web_dict = coord_web('../databases/coordinates_from_web.txt')
    needs_alias = set()
    for gene in genes:
        if gene in gene_merged_dict.keys():
            fout.write('\t'.join(gene_merged_dict[gene]) + '\n')
        else:
            alias = get_alias(gene, alias_db)
            flag = 0
            for name in alias:
                if name in gene_merged_dict.keys():
                    fout.write('\t'.join(gene_merged_dict[name][:3] + [gene] + [gene_merged_dict[name][-1]]) + '\n')
                    flag = 1
                    break
                elif name in web_dict:
                    fout.write('\t'.join(web_dict[name][:3] + [gene] + web_dict[name][-1]) + '\n')
            if flag == 0:
                needs_alias.add(gene)
    fout.close()
    os.system('sort -V -k1,1 -k2,2 -k3,3 ' + gene_coord_file + ' -o ' + gene_coord_file)
    if len(needs_alias) > 0:
        fout2 = open(gene_coord_file.replace('.txt', '') + '_needs_check.txt', 'w')
        for gene in needs_alias:
            fout2.write(gene + '\n')
        fout2.close()
    return list(needs_alias)


args = ParseArg()
gencode = args.gencode
refgene = args.refgene
hi_bed = args.hi_bed
ts_bed = args.ts_bed
lof = args.lof
coord_web_file = args.coord_web
score_list = args.score_list

gencode_gene_regions = get_all_gencode_regions(gencode)
refgene_gene_regions = get_all_refgene_regions(refgene)
web_dict = coord_web(coord_web_file)
all_code_regions = gencode_gene_regions
for key in refgene_gene_regions.keys():
    if key not in all_code_regions:
        all_code_regions[key] = refgene_gene_regions[key]
for key in web_dict.keys():
    if key not in all_code_regions:
        all_code_regions[key] = web_dict[key]

alias_db = "../intermediates/gene_alias_database.txt"
make_alias_db()

hi_coord = '../intermediates/hi_genes_coord.txt'
get_hits_coord(score_list, hi_bed, hi_coord)
ts_coord = '../intermediates/ts_genes_coord.txt'
get_hits_coord(score_list, ts_bed, ts_coord)

f = open(lof, 'r')
lof_genes = set()
for line in f:
    gene = line.strip()
    lof_genes.add(gene)
lof_genes = list(lof_genes)
f.close()

lof_coord = '../intermediates/lof_coord.txt'
lof_genes_needs_alias = get_coord_for_gene(lof_genes, gencode_gene_regions, alias_db, lof_coord)
if len(lof_genes_needs_alias) > 0:
    print("Needs to manually check lof_genes_needs_check and add the coordinates")



    