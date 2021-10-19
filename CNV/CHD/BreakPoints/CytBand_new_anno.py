#!/usr/bin/python2.7
# _*_ coding:utf-8 _*_

import sys
#sys.path.append(sys.path[0])
path = sys.argv[2]+"/../../cnv-anno/scripts" ###  "cnv-anno/scripts"
print path
sys.path.append(path)
import annotate

InputFile = sys.argv[1]
outfile_name = InputFile.split(".")[0]+"_new_anno.txt"

cytoband_file = open(InputFile, "r")
outfile = open(outfile_name,"w",1)
cytoband_file_lines = cytoband_file.readline()
cytoband_file_new_anno = []
#outfile.write('ID''\t''Chrom''\t''Start''\t''End''\t''seg.mean''\t''rlen''\t''cytband''\t''cnv_result''\t'
#                               '包含的编码基因数量_基因''\t''涉及的编码基因数量_基因''\t'
#                               '包含的单倍剂量不足基因数量_基因''\t''涉及的单倍剂量不足基因数量_基因''\t'
#                               '包含的三倍剂量敏感基因数量_基因''\t''涉及的三倍剂量敏感基因数量_基因''\t'
#                               '包含的ACMG功能缺失基因数量_基因''\t''涉及的ACMG功能缺失基因数量_基因''\t'
#                               '包含的Gnomad数据库中频率大于1%且长度不小于50Kb的cnv数量_CNV''\t''包含的DGV数据库中频率大于1%的cnv数量_CNV''\t'
#                               '包含的Clingen数据库中致病性cnv数量_CNV''\t''包含的Decipher数据库中的致病性CNV数量_病例数量''\t'
#                               'Decipher数据库中的致病性CNV_病例数量''\t'
#                               'Decipher数据库中的致病性CNV对应表型''\t''包含的Decipher数据库中的可能致病CNV数量_病例数量''\t' 
#                               'Decipher数据库中的可能致病CNV_病例数量''\t'
#                               'Decipher数据库中的可能致病CNV对应表型''\t'
#                               'Decipher自建综合征数据库中涉及综合征数量''\t'
#                               'Decipher自建综合征数据库中涉及综合征位置坐标_综合征名称_表型'+"\n")
outfile.write('ID''\t''Chrom''\t''Start''\t''End''\t''seg.mean''\t''rlen''\t''cytband''\t''cnv_result''\t'
                               '包含的RefSeq编码基因数_基因''\t''涉及的RefSeq编码基因数_基因''\t'
                               '包含的DECIPHER编码基因数_基因''\t''涉及的DECIPHER编码基因数_基因''\t'
                               '包含的OMIM编码基因数_基因''\t''涉及的OMIM编码基因数_基因''\t'
                               '包含的单倍剂量不足基因数_基因''\t''涉及的单倍剂量不足基因数_基因''\t'
                               '包含的三倍剂量敏感基因数_基因''\t''涉及的三倍剂量敏感基因数_基因''\t'
                               '包含的ACMG功能缺失基因数_基因''\t''涉及的ACMG功能缺失基因数_基因''\t'
                               '涉及的GNOMAD频率大于1%且长度不小于50Kb的CNV数_CNV''\t'
                               '涉及的DGV频率大于1%的CNV数_CNV''\t''涉及的CinGen致病性CNV数_CNV区域_区域名称''\t' 
                               '涉及的DECIPHER的致病性CNV数_病例数''\t'
                               '涉及的DECIPHER的致病性CNV_病例数''\t'
                               '涉及的DECIPHER的致病性CNV对应表型''\t'
                               '涉及的DECIPHER的可能致病CNV数_病例数''\t'
                               '涉及的DECIPHER的可能致病CNV_病例数''\t'
                               '涉及的DECIPHER的可能致病CNV对应表型''\t'
                               '涉及的DECIPHER综合征数''\t'
                               '涉及的DECIPHER综合征坐标_名称_表型'+"\n")

while cytoband_file_lines:
    cytoband_file_line_data = cytoband_file_lines.split('\t')
    
    if cytoband_file_line_data[1] != 'chrom':
        ID = cytoband_file_line_data[0]
        Chrom = cytoband_file_line_data[1]
        Start   = int(cytoband_file_line_data[2])
        End   = int(cytoband_file_line_data[3])
        segmean   = float(cytoband_file_line_data[5])
        rlen = cytoband_file_line_data[8]
        cytband = cytoband_file_line_data[9]
        cnv_result = cytoband_file_line_data[13]

        CnvType = ''
        if segmean > 0:
            CnvType = 'DUP'
        elif segmean < 0:
            CnvType = 'DEL'
        #result = annotate.cnv_anno(sys.path[0]+"/../intermediates",Chrom,Start,End,CnvType)
        result = annotate.cnv_anno(path+"/../intermediates",Chrom,Start,End,CnvType)        

        list_old = [ID,Chrom,str(Start),str(End),str(segmean),str(rlen),cytband,cnv_result] + result
        outfile.write("\t".join(list_old)+"\n")
    cytoband_file_lines = cytoband_file.readline()

cytoband_file.close()
outfile.close()
