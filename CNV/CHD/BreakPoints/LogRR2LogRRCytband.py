#!/usr/bin/python2.7
# _*_ coding:utf-8 _*_

import os
import sys

input_LOGRR = sys.argv[1]#位点坐标文件
input_cytband = sys.argv[2]#靶区坐标文件

cwd = os.getcwd()#获取当前路径

###读取分析结果
LOGRR_info = open(input_LOGRR,"r")
outfile_name = input_LOGRR.split(".")[0]+"_cytband.txt"
LOGRR_info_lines = LOGRR_info.readline()

### 1. 提取位点坐标
All_LOGRR_list   = [] #所有位点的坐标列表
    
while LOGRR_info_lines:
    LOGRR_info_line_data = LOGRR_info_lines.split('\t')
    if LOGRR_info_line_data[0] != "Chromosome":
        Chromosome = LOGRR_info_line_data[0]
        Start = LOGRR_info_line_data[1]
        End = LOGRR_info_line_data[2]
        LogRR = LOGRR_info_line_data[3]
        ZScore = LOGRR_info_line_data[4].strip()


        All_LOGRR_list.append([Chromosome,Start,End,LogRR,ZScore])
       
    LOGRR_info_lines = LOGRR_info.readline()
LOGRR_info.close()

#print len(All_LOGRR_list)

### 2. 提取靶区坐标
cytband_info = open(input_cytband,"r")
cytband_info_lines = cytband_info.readline()

All_cytband_list   = [] #所有靶区的坐标列表
    
while cytband_info_lines:
    cytband_info_line_data = cytband_info_lines.split('\t')

    Chromosome = cytband_info_line_data[0]
    Start = cytband_info_line_data[1]
    End = cytband_info_line_data[2]
    CytBand = cytband_info_line_data[3]

    All_cytband_list.append([Chromosome,Start,End,CytBand])
       
    cytband_info_lines = cytband_info.readline()
cytband_info.close()

#print len(All_cytband_list)

### 3. 靶区包含位点提取
outfile = open(outfile_name,"w")
outfile.write('Chromosome''\t''Start''\t''End''\t''LogRR''\t''ZScore''\t''CytBand'+"\n")

num = 0
for i in range(0,len(All_LOGRR_list)):
    cytband_list = []
    cytband_str = ''
    new_logrr = []
    for j in range(0,len(All_cytband_list)):
        if All_LOGRR_list[i][0] == All_cytband_list[j][0]:
            if int(All_LOGRR_list[i][1]) >= int(All_cytband_list[j][1]) and int(All_LOGRR_list[i][2]) <= int(All_cytband_list[j][2]):
                cytband_list.append(All_cytband_list[j][3])
            elif int(All_LOGRR_list[i][1]) >= int(All_cytband_list[j][1]) and int(All_LOGRR_list[i][1]) <= int(All_cytband_list[j][2]) and int(All_LOGRR_list[i][2]) > int(All_cytband_list[j][2]):
                cytband_list.append(All_cytband_list[j][3])
            elif int(All_LOGRR_list[i][2]) >= int(All_cytband_list[j][1]) and int(All_LOGRR_list[i][2]) <= int(All_cytband_list[j][2]) and int(All_LOGRR_list[i][1]) < int(All_cytband_list[j][1]):
                cytband_list.append(All_cytband_list[j][3])
    if len(cytband_list) >= 3:
        cytband_list_tmp = []
        cytband_list_tmp.append(cytband_list[0])
        cytband_list_tmp.append(cytband_list[-1])
        cytband_list = cytband_list_tmp
    if len(cytband_list) == 2:
        num = num + 1
    cytband_str = '-'.join(cytband_list)
    new_logrr = [All_LOGRR_list[i][0],All_LOGRR_list[i][1],All_LOGRR_list[i][2],All_LOGRR_list[i][3],All_LOGRR_list[i][4],cytband_str]
    outfile.write("\t".join(new_logrr)+"\n")
outfile.close()
