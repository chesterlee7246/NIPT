#-*-coding:utf-8-*-
#!/home/bioinfo/local/bin/python3

import os, sys, argparse
import gzip

def ParseArg():
    p = argparse.ArgumentParser(description="generate CNV database for cnv-anno with python build_cnv_db.py gnomad dgv decipher clingen score_list")
    p.add_argument("gnomad",type=str, help="Gnomad original dataset")
    p.add_argument("dgv", type=str, help="Dgv original dataset")
    p.add_argument("decipher", type=str, help="Decipher original dataset")
    p.add_argument('clingen', type=str, help="Clingen original dataset")
    p.add_argument("score_list",type=list, help="The scores used to filter the Clingen curated cnvs")
    if len(sys.argv)==1:
        print >>sys.stderr,p.print_help()
        sys.exit(0)
    return p.parse_args()

def gnomad_cnv(gnomad):
    """
    Get the CNV with frequency >1% and len >= 50000 from gnomad_v2.1_sv.sites.vcf_hg19.gz
    """
    out_file = '../intermediates/gnomad_common_tmp.bed'
    out_final = out_file.replace('_tmp.bed', '_cnv.bed')
    fout = open(out_file, 'w')
    fout.write('\t'.join(['#chr', 'start', 'end', 'cnv_type', 'frequency']) + '\n')
    with gzip.open(gnomad, 'rt') as fin:
        for line in fin:
            if line.startswith('#'):
                continue
            line = line.strip().split('\t')
            if line[4] == '<DEL>' or line[4] == '<DUP>':
                chrom = 'chr' + line[0]
                start = line[1]
                info = line[7]
                end_s = info.index('END=') + len('END=')
                end_e = info[end_s:].index(';')
                end = info[end_s:end_s+end_e]
                if int(end) - int(start) < 50000:
                    continue
                af_s = info.index('AF=') + len('AF=')
                af_e = info[af_s:].index(';')
                af = '%.3f' % (float(info[af_s:af_s+af_e]))
                if ',' in af:
                    print(line)
                if float(af) < 0.01:
                    continue
                fout.write('\t'.join([chrom, start.strip(), end.strip(), line[4].replace('<', '').replace('>', ''), af]) + '\n')
    fout.close()
    os.system('(head -n 1 ' + out_file  + ' && tail -n +2 ' + out_file + '| sort  -k1,1 -V -k2,2n  -k3,3n)  > ' + out_final)
    os.system('rm ' + out_file)
    return 

def dgv_cnv(dgv,range_type='outer'):
    """ 
    Get the CNV with frequency >1% and len >= 50000 from DGV.GS.March2016.50percent.GainLossSep.Final.hg19.gff3.gz
    """
    out_file = '../intermediates/dgv_common_tmp.bed'
    out_final = out_file.replace('_tmp.bed', '_cnv_' + range_type + '.bed')
    fout = open(out_file, 'w')
    start, end = range_type + '_start', range_type + '_end'
    keys_lst = [start, end, 'variant_sub_type', 'Frequency']
    fout.write('\t'.join(['#chr'] + keys_lst) + '\n')
    res_dic = {}
    with gzip.open(dgv, 'rt') as fin:
        for line in fin:
            fields = line.strip().split('\t')
            infos = fields[8].split(';')
            key_dic = {key:'' for key in keys_lst}
            for e in infos:
                for key in key_dic.keys():
                    if e.startswith(key):
                        key_dic[key] = e.replace(key+'=', '').replace('Gain', 'DUP').replace('Loss', 'DEL')
            res = [fields[0]]
            if float(key_dic['Frequency'].strip('%'))* 0.01 < 0.01 or int(key_dic[end]) - int(key_dic[start]) < 50000:
                continue
            for key in keys_lst:
                res.append(key_dic[key])
            res[-1] = "%.3f" % (float(res[-1].strip('%'))*0.01)
            if '_'.join(res) not in res_dic:
                res_dic['_'.join(res)] = 1
                fout.write('\t'.join(res) + '\n')
    fout.close()
    os.system('(head -n 1 ' + out_file  + ' && tail -n +2 ' + out_file + '| sort  -k1,1 -V -k2,2n  -k3,3n)  > ' + out_final)
    os.system('rm ' + out_file)
    return

def decipher_pcnv(decipher):
    # fin = open('../databases/Decipher_Patient_Info_E2C.txt', 'r')
    fin = open(decipher, 'r')
    f1 = open('../intermediates/decipher_pathogenic_cnv.txt', 'w')
    f2 = open('../intermediates/decipher_likeyly_pathogenic_cnv.txt', 'w')
    fin.readline()
    for line in fin:
        line = line.strip().split('\t')
        chrom = 'chr' + line[1]
        start, end = line[2], line[3]
        patho_stat = line[6].strip()
        phenotype = line[8] + '（DECIPHER ' + line[0].strip() + '）'
        if 'pathogenic' not in patho_stat:
            continue
        cnv_type = line[-1]
        if cnv_type == 'snp':
            continue
        if cnv_type == 'copy_number_loss':
            cnv_type = 'DEL'
        elif cnv_type == 'copy_number_gain':
            cnv_type = 'DUP'
        if 'Definitely' in patho_stat:
            f1.write('\t'.join([chrom, start.strip(), end.strip(), cnv_type, phenotype]) + '\n')
        else:
            f2.write('\t'.join([chrom, start.strip(), end.strip(), cnv_type, phenotype]) + '\n')
    fin.close()
    f1.close()
    f2.close()
    return 

def clingen_cnv(clingen, score_list):
    """
    Use ClinGen_region_curation_list_GRCh37.tsv
    """
    fin = open(clingen, 'r')
    fout = open('../intermediates/tmp.txt', 'w')
    for line in fin:
        if line.startswith('#'):
            continue
        line = line.strip().split('\t')
        region_name = line[1]
        hi_score = line[4]
        ts_score = line[9]
        region = line[3]
        chrom = region[:region.index(':')]
        start = region[region.index(':')+1:region.index('-')]
        end = region[region.index('-')+1:]
        name = line[2]
        if hi_score in score_list:
            fout.write('\t'.join([chrom, start.strip(), end.strip(), 'DEL', region_name]) + '\n')
        if ts_score in score_list:
            fout.write('\t'.join([chrom, start.strip(), end.strip(), 'DUP', region_name]) + '\n')
    fin.close()
    fout.close()
    os.system('sort  -k1,1 -V -k2,2n  -k3,3n ../intermediates/tmp.txt > ../intermediates/ClinGen_pathogenic_cnv.txt')
    os.system('rm tmp.txt')
    return


args = ParseArg()
gnomad = args.gnomad
dgv = args.dgv
decipher = args.decipher
clingen = args.clingen
score_list = args.score_list

gnomad_cnv(gnomad)
dgv_cnv(dgv)
decipher_pcnv(decipher)
clingen_cnv(clingen, score_list)



