#-*-coding:utf-8-*-
#!/home/bioinfo/local/bin/python3

import sys

class cnv_anno(object):

    def __init__(self, chrom, start, end, cnv_type, db_dir):
        self.chrom = chrom.lower()
        self.start = start
        self.end = end
        self.cnv_type = cnv_type
        self.db_dir = db_dir

    def sec_1(self):
        """
        Assess whether the CNV contain protein coding or other known functionally important elements
        Section 1: Initial assessment of genomic content
        """
        coding_info = self.db_dir + '/decipher_protein_coding_regions.bed'
        function_elem = self.db_dir + '/RefSeq_Functional_Element_records_20200727.txt'
        print('inside sec_1', self.chrom, self.start, self.end, self.cnv_type)
        with open(coding_info, 'rt') as f_coding:
            for line in f_coding:
                line = line.strip().split('\t')
                if line[0] != self.chrom:
                    continue
                if int(line[1]) >= self.start and int(line[2]) <= self.end:
                    return 0
        with open(function_elem, 'rt') as f_func:
            for line in f_func:
                line = line.strip('\n').split('\t')
                if line[0] == 'tax_id':
                    continue
                if 'chr' + line[10].strip().lower() != self.chrom:
                    continue
                if not line[12].isdigit() or not line[13].isdigit():
                    continue
                if int(line[12]) >= self.start and int(line[13]) <= self.end:
                    return 0
        return -0.60

    def overlap(self, cnv_type):
        if cnv_type.lower() == 'del':
            gene_file = self.db_dir + '/ClinGen_haploinsufficiency_gene_GRCh37.bed'
        elif cnv_type.lower() == 'dup':
            gene_file = self.db_dir + '/ClinGen_triplosensitivity_gene_GRCh37.bed'
        p_comp, p_par, b_comp, b_add = [], [], [], []
        with open(gene_file, 'rt') as fgene:
            for line in fgene:
                if line.startswith('track name'):
                    continue
                line = line.strip().split('\t')
                if line[0] != self.chrom:
                    continue
                score = int(line[4])
                if score != 3 and score != 40:
                    continue
                rec = [line[0], line[1], line[2], line[3]]
                gene_min = int(line[1])
                gene_max = int(line[2])
                if score == 3:
                    if gene_min >= self.start and gene_max <= self.end:
                        p_comp.append(rec)
                    elif (gene_max >= self.start and gene_max <= self.end) or (gene_min <= self.start and gene_max >= self.end) or (self.start >= gene_min and self.end <= gene_max) :
                        p_par.append(rec)
                else:
                    if self.start >= gene_min and self.end <= gene_max:
                        b_comp.append(rec)
                    elif (self.end >= gene_min and self.end <= gene_max) or (self.start <= gene_max and self.end >= gene_max) or (self.start >= gene_min and self.end <= gene_max):
                        b_add.append(rec)
        return p_comp, p_par, b_comp, b_add

    def inv_gene_feature(self, p_par, feature_name):
        """
        get the region for 3'UTR, 5'UTR and coding regions
        """
        db = 'Homo_sapiens.GRCh37.87.gtf'
        for p in p_par:
            chrom, start, end, gname = p
            os.system('zcat ' + db + ' |grep ' + gname + ' |grep ' + feature_name + ' > ' + feature_name + '.txt' )
            f = open(feature_name + '.txt', 'r')
            for line in f:
                line = line.strip().split('\t')
                s, e = int(line[3]), int(line[4])
                if start >= s and start <= e or end >= s and end <= e:
                    return True
        return False


    def sec_2cd(self, p_par):
        """
        need to implement whether other established pathogenic variants have been reported in the last exon
        """
        utr_3 = self.inv_gene_feature(p_par, 'three_prime_utr')
        utr_5 = self.inv_gene_feature(p_par, 'five_prime_utr')
        cds = self.inv_gene_feature(p_par, 'CDS')
        last_exon = False ## to be implemented
        other_exon = False
        if not utr_3 and utr_5:
            if cds:
                return 0.90
            else:
                return 0
        elif not utr_5 and utr_3:
            if last_exon and other_exon:
                return 0.90
            elif last_exon:
                return 0.90
            else:
                return 0

    def sec_2e(self, p_par):
        return  0

    def sec_2(self):
        p_comp, p_par, b_comp, b_add = self.overlap(self.cnv_type)
        if p_comp:
            return 1
        elif p_par:
            return self.sec_2cd(p_par) + self.sec_2e(p_par)
        elif b_add:
            return 0
        elif b_comp:
            return -1
        else:
            return 0

    def genes(self):
        inc_genes, inv_genes = set(), set()
        coding_genes = self.db_dir +'/decipher_protein_coding_regions.bed'
        with open(coding_genes, 'rt') as fgenes:
            for line in fgenes:
                line = line.strip().split('\t')
                if line[0] != self.chrom:
                    continue
                gene_min = int(line[1])
                gene_max = int(line[2])
                if gene_min >= self.start and gene_max <= self.end:
                    inc_genes.add(line[3])
                elif (gene_max >= self.start and gene_max <= self.end) or (self.end >= gene_min and self.end <= gene_max):
                    inv_genes.add(line[3])
        return list(sorted(inc_genes)), list(sorted(inv_genes))

    def sec_3(self):
        inc_genes, inv_genes = self.genes()
        n = len(inc_genes) + len(inv_genes)
        if self.cnv_type == 'del':
            if n <= 24:
                return 0
            elif n <= 34:
                return 0.45
            else:
                return 0.90
        else:
            if n <= 34:
                return 0
            elif n <= 49:
                return 0.45
            else:
                return 0.90


if __name__ == "__main__":
    args = sys.argv
    db_dir = '/home/liao426/cnv-anno/intermediates'
    fin = open(sys.argv[1], 'r')
    fout = open(sys.argv[1].replace('.txt', '_del_result.txt'), 'w')
    for line in fin:
        line = line.strip().split('\t')
        if line[0] == 'Chr':
            line.extend(['Sec_1', 'Sec_2', 'Sec_3'])
            fout.write('\t'.join(line) + '\n')
        elif line[3].lower() == 'del':
            chrom, start, end, cnv_type = 'chr'+line[0], int(line[1]), int(line[2]), line[3]
            cnv_info = cnv_anno(chrom, start, end, cnv_type, db_dir)
            line.extend([str(x) for x in [cnv_info.sec_1(), cnv_info.sec_2(), cnv_info.sec_3()]])
            fout.write('\t'.join(line) + '\n')
    fin.close()
    fout.close()


#  python3 cnv_anno.py chr4 143440001 151200000  DUP /home/liao426/cnv-anno/intermediates
#  python3 cnv_anno.py chr1 104680001 106560000 DEL /home/liao426/cnv-anno/intermediates
