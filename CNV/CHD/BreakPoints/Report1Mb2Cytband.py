#!/usr/bin/python2.7
# _*_ coding:utf-8 _*_

import os
import sys

input_Report4Mb    = sys.argv[1] # 4MbReport_anno文件
input_LOGRRCytband = sys.argv[2] # LOGRRCytband文件

### 1. 提取靶区坐标
Report4Mb = [] #所有CNV的坐标列表
if os.path.exists(input_Report4Mb):
    Report4Mb_info = open(input_Report4Mb,"r")
    Report4Mb_info_lines = Report4Mb_info.readline()
    while Report4Mb_info_lines:
        Report4Mb_info_line_data = Report4Mb_info_lines.split('\t')
        if Report4Mb_info_line_data[0] != "ID":
            Report4Mb.append([Report4Mb_info_line_data[1],Report4Mb_info_line_data[2],Report4Mb_info_line_data[3],Report4Mb_info_line_data[13].strip()])
        Report4Mb_info_lines = Report4Mb_info.readline()
    Report4Mb_info.close()


### 2. LOGRRCytband位点坐标
LOGRRCytband_info = open(input_LOGRRCytband,"r")
LOGRRCytband_info_lines = LOGRRCytband_info.readline()

LOGRRCytband   = [] #所有位点的坐标列表
while LOGRRCytband_info_lines:
    LOGRRCytband_info_line_data = LOGRRCytband_info_lines.split('\t')
    if LOGRRCytband_info_line_data[0] != "Chromosome":
        LOGRRCytband.append([LOGRRCytband_info_line_data[0],LOGRRCytband_info_line_data[1],LOGRRCytband_info_line_data[2],LOGRRCytband_info_line_data[3],LOGRRCytband_info_line_data[4],LOGRRCytband_info_line_data[5].strip()])
    LOGRRCytband_info_lines = LOGRRCytband_info.readline()
LOGRRCytband_info.close()

### 3. 区域相交位点提取
# outfile_name = input_LOGRRCytband.split(".")[0]+"_new.txt"
outfile_name = input_LOGRRCytband
outfile = open(outfile_name,"w")
outfile.write('Chromosome''\t''Start''\t''End''\t''LogRR''\t''ZScore''\t''CytBand''\t''CNV'+"\n")

num = 0
for i in range(0,len(LOGRRCytband)):
    cytband_str = 'Null'
    new_logrr = []
    if len(Report4Mb) == 0:
        new_logrr = [LOGRRCytband[i][0],LOGRRCytband[i][1],LOGRRCytband[i][2],LOGRRCytband[i][3],LOGRRCytband[i][4],LOGRRCytband[i][5],cytband_str]
    else:
        for j in range(0,len(Report4Mb)):
            if LOGRRCytband[i][0] == Report4Mb[j][0]:
                if (int(LOGRRCytband[i][1]) >= int(Report4Mb[j][1]) and int(LOGRRCytband[i][1]) <= int(Report4Mb[j][2])) or (int(LOGRRCytband[i][2]) >= int(Report4Mb[j][1]) and int(LOGRRCytband[i][2]) <= int(Report4Mb[j][2])):
                    cytband_str = Report4Mb[j][3]
        new_logrr = [LOGRRCytband[i][0],LOGRRCytband[i][1],LOGRRCytband[i][2],LOGRRCytband[i][3],LOGRRCytband[i][4],LOGRRCytband[i][5],cytband_str]
    outfile.write("\t".join(new_logrr)+"\n")
outfile.close()
