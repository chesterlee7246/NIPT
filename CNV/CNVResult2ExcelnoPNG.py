#!/usr/bin/python2.7
# _*_ coding:utf-8 _*_

import os
import sys
import json
import xlwt
from PIL import Image

cddir = os.path.abspath(sys.argv[1]) # 数据主目录
StartID = sys.argv[2] # RUN号
sites = sys.argv[3] # 站点

RunList = []

for root, dirs, files in os.walk(cddir):
    for dirlist in dirs:
        if dirlist.startswith(StartID): # and (dirlist.endswith("001") or dirlist.endswith("002")):
            RunList.append(dirlist)

AllData = []
AllData.append(['RunNum','indexid','samplename','raw_reads','uniq_reads','uniq_rate','dup_reads','dup_frac','map_rate','coverage','sd','mapd','CNVs','sex'])
for RunNum in RunList:
    run_dir = cddir + "/" + RunNum
    index_file = run_dir + "/index2id.txt"
    if os.path.isfile(run_dir + "/index2id_bak.txt"):
        index_file = run_dir + "/index2id_bak.txt"
    elif os.path.isfile(run_dir + "/index2id.bak.txt"):
        index_file = run_dir + "/index2id.bak.txt"
    elif os.path.isfile(run_dir + "/index2id_old.txt"):
        index_file = run_dir + "/index2id_old.txt"

    indexname = []
    if os.path.isfile(index_file):
        indexfile=open(index_file,'r')
        for lines in indexfile:
            lines=lines.strip()
            indexid = lines.split("\t")[0]
            sample_name = lines.split("\t")[1]
            if 'R' in sample_name:
                indexname.append([indexid,sample_name])
        indexfile.close()

    for idname in indexname:
        indexid = idname[0]
        samplename = idname[1]
        CNV1Mb_file=run_dir + "/" + indexid + "_100Kb_DNAcopy_Info_CNV_RealCNV_LogRR_Effective_Extract_Abnormal_CNV_Merge_1Mb_Cytoband_Annotation_Report.txt"
        CNVs=''
        if os.path.isfile(CNV1Mb_file):
            CNV1Mbf=open(CNV1Mb_file,'r')
            for CNVlines in CNV1Mbf:
                CNVlines=CNVlines.strip()
                if 'ID' != CNVlines.split("\t")[0]:
                    if CNVlines.split("\t")[13][0] == '+' or CNVlines.split("\t")[13][0] == '-':
                        CNVs=CNVs + CNVlines.split("\t")[13] + ";"
                    else:
                        CNVs=CNVs+CNVlines.split("\t")[13] + "[" + str(float(CNVlines.split("\t")[8])/1000000) + "Mb];"
            CNV1Mbf.close()
        if CNVs=='':
            CNVs='Null'
        if CNVs[0] == '+' or CNVs[0] == '-':
            CNVs = "\'" + CNVs

        CNV100Kb_file=run_dir + "/" + indexid + "_100Kb_DNAcopy_Info_CNV_RealCNV_LogRR_Effective_Extract_Abnormal_CNV_Merge_100Kb_Cytoband.txt"
        CNVs500K=''
        # num400cnvs=0
        if os.path.isfile(CNV100Kb_file):
            CNV100Kbf=open(CNV100Kb_file,'r')
            for lengthcnvs in CNV100Kbf:
                lengthcnvs=lengthcnvs.strip()
                if 'ID' != lengthcnvs.split("\t")[0] and int(lengthcnvs.split("\t")[8]) >= 400000 and int(lengthcnvs.split("\t")[8]) < 1000000:
                    # num400cnvs = num400cnvs + 1
                    CNVs500K=CNVs500K+lengthcnvs.split("\t")[13] + "[" + str(float(lengthcnvs.split("\t")[8])/1000000) + "Mb];"
            # if num400cnvs > 0 :
            #     continue
            CNV100Kbf.close()
        if CNVs500K=='':
            CNVs500K='Null'

        cov_file= run_dir + "/" + indexid + "_rawlib_rmdup_unique_Cov.txt"
        coverage='Null'
        if os.path.isfile(cov_file):
            covf=open(cov_file,'r')
            for cov in covf:
                cov=cov.strip()
                if cov.startswith("Cov"):
                    coverage1=cov.split("\t")[-1]
                    coverage=str(float(coverage1)*100)+"%"
            covf.close()

        uni_read_file=run_dir + "/" + indexid+"_rawlib_rmdup_MAPQ10_Nbin.txt"
        uniq_reads=''
        uniq_rate=''
        if os.path.isfile(uni_read_file):
            unifile=open(uni_read_file,'r')
            for uni in unifile:
                uni=uni.strip()
                if uni.startswith("##unique"):
                    uniq_reads=uni.split("\t")[-1]
            unifile.close()

        mapd_file=run_dir + "/" + indexid + "_100Kb_DNAcopy_Info_CNV_RealCNV_LogRR_Effective_MAPD_INFO.txt"
        mapd = ''
        sd = ''
        if os.path.isfile(mapd_file):
            mapdf=open(mapd_file,'r')
            i=0
            for line2 in mapdf:
                line2=line2.strip()
                i+=1
                if i==1:
                    sd=str('%0.4f' %(float(line2.split("\t")[1])))
                if i==2:
                    mapd=str('%0.4f' %(float(line2.split("\t")[1])))
            mapdf.close()

        dup_file=run_dir + "/" + indexid+"_BamDuplicates.json"
        dup_reads=1
        total_reads1=100
        total_map=0.0001
        dup_frac=0.0001
        map_rate=0.0001
        uniq_rate=0.0001
        if os.path.isfile(dup_file):
            dup_json=json.load(open(dup_file,'r'))
            dup_reads=dup_json["duplicate_reads"]
            total_reads1=dup_json["total_reads"]
            total_map=dup_json["total_mapped_reads"]
            dup_frac=str(float('%.4f' %(dup_json["fraction_duplicates"]))*100)+"%"
            map_rate=str(float('%.4f' %(float(total_map)/float(total_reads1)))*100)+"%"
            uniq_rate=str(float('%.4f' %(float(int(uniq_reads))/float(total_reads1)))*100)+"%"
        raw_reads = total_reads1

        effective_file=run_dir + "/" + indexid + "_100Kb_DNAcopy_Info_CNV_RealCNV_LogRR_Effective.txt"
        sex = 'female'
        if os.path.isfile(effective_file):
            effile=open(effective_file,'r')
            for lines in effile:
                lines = lines.strip()
                if 'chrY' == lines.split("\t")[1]:
                    sex = 'male'
            effile.close()

        AllData.append([RunNum,indexid,samplename,str(raw_reads),str(uniq_reads),str(uniq_rate),str(dup_reads),str(dup_frac),str(map_rate),str(coverage),str(sd),str(mapd),CNVs,sex])

workbook = xlwt.Workbook(encoding='utf-8')
worksheet = workbook.add_sheet('sheet1')
alignment = xlwt.Alignment()
# 水平居中
alignment.horz = xlwt.Alignment.HORZ_CENTER
# 垂直居中
alignment.vert = xlwt.Alignment.VERT_CENTER
style = xlwt.XFStyle()
style.alignment = alignment
# 设置单元格宽度、高度
worksheet.col(0).width = 3000
worksheet.col(14).width = 8000
# worksheet.row(0).height_mismatch = True
# worksheet.row(0).height = 3000

for i in range(0,len(AllData)):
    worksheet.write(i, 0, AllData[i][0], style)
    worksheet.write(i, 1, AllData[i][1], style)
    worksheet.write(i, 2, AllData[i][2], style)
    worksheet.write(i, 3, AllData[i][3], style)
    worksheet.write(i, 4, AllData[i][4], style)
    worksheet.write(i, 5, AllData[i][5], style)
    worksheet.write(i, 6, AllData[i][6], style)
    worksheet.write(i, 7, AllData[i][7], style)
    worksheet.write(i, 8, AllData[i][8], style)
    worksheet.write(i, 9, AllData[i][9], style)
    worksheet.write(i,10, AllData[i][10], style)
    worksheet.write(i,11, AllData[i][11], style)
    worksheet.write(i,12, AllData[i][12], style)
    worksheet.write(i,13, AllData[i][13], style)

workbook.save(cddir + "/" + sites + "_" + StartID +'.xls')
