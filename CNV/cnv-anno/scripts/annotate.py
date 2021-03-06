#-*-coding:utf-8-*-
#!/home/bioinfo/local/bin/python3

import os, sys, argparse

def ParseArg():
    p = argparse.ArgumentParser(description="CNV annotation with chromsome regions")
    p.add_argument("-d","--database_dir",type=str, help="the input database dir")
    p.add_argument("-c","--chrom",type=str, help="the input chromsome")
    p.add_argument("-s","--start", type=int, help="the input position of start")
    p.add_argument("-e","--end", type=int, help="the input position of end")
    p.add_argument("-t","--cnv_type", type=str, help="the input cnv_type")
    if len(sys.argv)==1:
        print >>sys.stderr,p.print_help()
        sys.exit(0)
    return p.parse_args()


def get_gene_info(chrom, start, end, file):
    inc_genes = set()
    inv_genes = set()
    f = open(file, 'r')
    for line in f:
        line = line.strip().split('\t')
        if line[0] != chrom:
            continue
        gene_min= min(int(line[1]), int(line[2]))
        gene_max = max(int(line[1]), int(line[2]))
        if gene_min >= start and gene_max <= end:
            inc_genes.add(line[3])
        else:
            if (gene_max >= start and gene_max <= end) or (gene_min <= end and gene_max >= end) or (gene_min <= start and gene_max >= end):
                inv_genes.add(line[3])
    f.close()
    return list(sorted(inc_genes)), list(sorted(inv_genes))


def get_cnv_info(chrom, start, end, cnv_type, file):
    cnv = []
    f = open(file, 'r')
    for line in f:
        line = line.strip().split('\t')
        if line[0] != chrom or (line[3] != cnv_type and line[3].lower() != cnv_type):
            continue
        if int(line[1]) > end and int(line[2]) < start:
            continue
        if 'DECIPHER_70_Syndrome' in file or 'decipher' in file or 'ClinGen' in file:
            union_len = int(line[2]) - int(line[1]) + 1
        else:
            union_len = max(end, int(line[2])) - min(start, int(line[1])) + 1
        inter_len = min(end, int(line[2])) - max(start, int(line[1])) + 1
        if inter_len * 1.0/union_len >= 0.8:
            if 'decipher' in file:
                cnv.append([chrom, line[1], line[2],line[4]])
            elif 'DECIPHER_70_Syndrome' in file:
                cnv.append([chrom, line[1], line[2], line[4], line[6]])
            elif 'ClinGen' in file:
                cnv.append([chrom, line[1], line[2], line[4]])
            else:
                cnv.append([chrom, line[1], line[2]])
    f.close()
    return cnv

def get_decipher_info(db_dir, chrom, start, end, cnv_type):
    decipher_dpatho = db_dir + '/decipher_pathogenic_cnv.txt'
    decipher_lpatho = db_dir +'/decipher_likeyly_pathogenic_cnv.txt'
    decipher_dcnv = get_cnv_info(chrom, start, end, cnv_type, decipher_dpatho)
    decipher_ddict = {}
    decipher_dphenotype_list = []
    for info in decipher_dcnv:
        key = '_'.join(info[:3])
        decipher_dphenotype_list.append(info[3])
        if key not in decipher_ddict:
            decipher_ddict[key] = 1
        else:
            decipher_ddict[key] += 1
    decipher_dcnvs = [k + '(' + str(v) + ')' for k, v in sorted(decipher_ddict.items(), key=lambda x: x[1], reverse=True)]

    decipher_lcnv = get_cnv_info(chrom, start, end, cnv_type, decipher_lpatho)
    decipher_ldict = {}
    decipher_lphenotype_list = []
    for info in decipher_lcnv:
        key = '_'.join(info[:3])
        decipher_lphenotype_list.append(info[3])
        if key not in decipher_ldict:
            decipher_ldict[key] = 1
        else:
            decipher_ldict[key] += 1
    decipher_lcnvs = [k + '(' + str(v) + ')' for k, v in sorted(decipher_ldict.items(), key=lambda x: x[1], reverse=True)]

    decipher_dicts = [decipher_ddict, decipher_ldict]
    decipher_cnvs = [decipher_dcnvs, decipher_lcnvs]
    decipher_phenos = [decipher_dphenotype_list, decipher_lphenotype_list]
    res_cnv = []
    for i in range(len(decipher_dicts)):
        cnvs = '|'.join(decipher_cnvs[i])
        ncnv_npat = str(len(decipher_dicts[i])) + '_' + str(sum(decipher_dicts[i].values()))
        phenos = '|'.join(decipher_phenos[i])
        res_cnv.extend([ncnv_npat, cnvs, phenos])
    return res_cnv


def get_decipher_syndrome(db_dir, chrom, start, end, cnv_type):
    DecipherSyndrome = db_dir + '/DECIPHER_70_Syndrome.txt'
    DecipherSyndrome_cnv = get_cnv_info(chrom, start, end, cnv_type, DecipherSyndrome)
    DecipherSyndrome_cnvs = [x[0] + ':'+x[1] + '-'+x[2] + '_'+x[3] + '_'+x[4] for x in DecipherSyndrome_cnv]
    num_DS_CNV = len(DecipherSyndrome_cnvs)
    DS_CNV_tmp = []
    for DS_CNV in range(0,num_DS_CNV):
        DS_CNV_tmp.append(DecipherSyndrome_cnvs[DS_CNV])
    DS_CNVs = '|'.join(DS_CNV_tmp)
    return [str(num_DS_CNV), DS_CNVs]


def cnv_anno(db_dir,chrom,start,end,cnv_type):
    print("???????????? ", chrom, start, end, cnv_type)
    # title = ['Chr','Start', 'End', 'Length', 'type', '?????????RefSeq???????????????_??????','?????????RefSeq???????????????_??????',\
                                               #'?????????DECIPHER???????????????_??????','?????????DECIPHER???????????????_??????',\
                                                # '?????????OMIM???????????????_??????','?????????OMIM???????????????_??????', \
                                                    # '?????????HI?????????_??????','?????????HI?????????_??????',\
                                                    # '?????????TS?????????_??????','?????????TS?????????_??????',\
                                                    # '?????????ACMG-LOF?????????_??????','?????????ACMG-LOF?????????_??????',\
                                                    # '?????????GNOMAD freq>1%?????????>=50Kb???cnv???_CNV', \
                                                    # '?????????DGV freq>1%???CNV???_CNV', \
                                                    # '?????????ClinGen?????????CNV???_CNV??????_?????????',\
                                                    # '?????????DECIPHER?????????CNV??????_?????????','DECIPHER?????????CNV_?????????','DECIPHER?????????CNV??????',\
                                                    # '?????????DECIPHER????????????CNV??????_?????????','DECIPHER????????????CNV_?????????','DECIPHER????????????CNV??????',\
                                                    # '?????????DECIPHER????????????',\
                                                    # '?????????DECIPHER???????????????_??????_??????']
    
    #????????????????????????
    inc_refseq, inv_refseq = get_gene_info(chrom, start, end, db_dir + '/refseq_coding_genes.txt')
    inc_deci, inv_deci = get_gene_info(chrom, start, end, db_dir + '/decipher_protein_coding_regions_GRCh38.bed')
    inc_hi, inv_hi = get_gene_info(chrom, start, end, db_dir + '/hi_genes_coord.txt')
    inc_ts, inv_ts = get_gene_info(chrom, start, end, db_dir + '/ts_genes_coord.txt')
    inc_lof, inv_lof = get_gene_info(chrom, start, end, db_dir + '/lof_coord.txt')
    inc_omim, inv_omim = get_gene_info(chrom, start, end, db_dir+'/omim_coding_genes.bed')
    res_gene = []
    for gene_list in [inc_refseq, inv_refseq, inc_deci, inv_deci, inc_omim, inv_omim, inc_hi, inv_hi, inc_ts, inv_ts, inc_lof, inv_lof]:
        res_gene.append('_'.join([str(len(gene_list)) , '|'.join(gene_list)]))
   
    #??????CNV????????????
    gnomad = db_dir +'/gnomad_common_cnv.bed'
    dgv = db_dir + '/dgv_common_cnv_outer.bed'
    clingen = db_dir + '/ClinGen_pathogenic_cnv.txt'
    gnomad_cnv = get_cnv_info(chrom, start, end, cnv_type, gnomad)
    dgv_cnv = get_cnv_info(chrom, start, end, cnv_type, dgv)
    clingen_cnv = get_cnv_info(chrom, start, end, cnv_type, clingen)
    res_cnv = []
    for cnvs in [gnomad_cnv, dgv_cnv]:
        tmp = []
        for cnv in cnvs:
            cnv = cnv[0] + ':'+cnv[1] + '-' + cnv[2]
            tmp.append(cnv)
        res_cnv.append('_'.join([str(len(cnvs)) , '|'.join(tmp)]))

    tmp = []
    for cnv in clingen_cnv:
        cnv_rec = cnv[0] + ':' + cnv[1] + '-' + cnv[2] + '_'+ cnv[3]
        tmp.append(cnv_rec)
    res_cnv.append('_'.join([str(len(tmp)), '|'.join(tmp)]))

    #???????????????Decipher???????????????????????????????????????CNV????????????
    decipher_cnvs = get_decipher_info(db_dir, chrom, start, end, cnv_type)
    res_cnv.extend(decipher_cnvs)

    #??????Decipher Syndrome????????????
    syndrom_info = get_decipher_syndrome(db_dir, chrom, start, end, cnv_type)
    res_cnv.extend(syndrom_info)
    res = res_gene + res_cnv
    return res

#?????????????????????python3 annotate.py -d  ../intermediates/  -c chr4  -s 77220001 -e 77460000 -t DUP
# args = ParseArg()
# db_dir = args.database_dir
# chrom = args.chrom
# start = args.start
# end = args.end
# cnv_type = args.cnv_type
# result = cnv_anno(db_dir,chrom,start,end,cnv_type)
# print(result)
