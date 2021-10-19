#!/bin/python
#coding=utf-8
#mail: wang338@basecare.cn

import datetime
import time
import sys
import os
import re

def getEveryDay(begin_date,end_date):
    date_list = []
    begin_date = datetime.datetime.strptime(begin_date, "%Y-%m-%d")
    end_date = datetime.datetime.strptime(end_date,"%Y-%m-%d")
    while begin_date <= end_date:
        date_str = begin_date.strftime("%Y-%m-%d")
        date_list.append(date_str)
        begin_date += datetime.timedelta(days=1)
    return date_list

site_d={"GuiZhou":"贵州站点","AYFY":"安徽妇幼","GYSY":"广医三院","HBRY":"湖北人民","HongKong":"香港站点","JiaYin":"新疆佳音","LanZhou":"兰州站点","LinYi":"临沂站点","NanTong":"南通站点","NJFY":"南京妇幼","ShanDa":"山大生殖","ShengJing":"盛京站点","SuZhou":"苏州本部","TangDu":"唐都站点","XiangYa":"中信湘雅","JXFY":"江西妇幼","BJBK":"北京贝康","XuZhou":"徐州站点"}

proj_d={"PGS":"^\d*[P|N]","CNV":"^\d*R","NIPT":"^\d*C"}

if __name__=="__main__":
    if len(sys.argv)!=5:
        sys.exit("\nUsage: python "+sys.argv[0]+" project_dir(/data/PGS_result|..) project_type(PGS|CNV|NIPT) begin_date(2019-12-05|..) end_date(2019-12-10|..)"+"\n")
    indir=sys.argv[1]
    project_type=sys.argv[2]
    begin=sys.argv[3]
    end=sys.argv[4]
    outf=open("project_stat.txt",'w')
    outf.write("项目\t站点\tRun_id\t数据下机时间\t数据完成分析时间\t该项目规定交付周期\t该项目实际交付周期\t是否逾期\t样本数\t波动较大数\t后期备注波动较大数\t检测无结果数\t备注\n")
    date_lst=getEveryDay(begin,end)
    site_lst=os.listdir(indir)
    for each in site_lst:
        if os.path.isfile(indir+"/"+each):
            continue
        if each in ["YanFa","JiaYin"]:
            continue
        else:
            site_dir=indir+"/"+each
        run_lst=os.listdir(site_dir)
        for line in run_lst:
            if line.startswith("SQR") and not line.endswith("nt"):
                run_dir=site_dir+"/"+line
                run_date=time.strftime('%Y-%m-%d',time.localtime(os.path.getctime(run_dir)))
                if run_date in date_lst:
                    smp_nu=0
                    wave_nu=0
                    noresult_nu=0
                    outf.write(project_type+"\t"+site_d[each]+"\t"+line+"\t"+run_date+"\t"+run_date+"\t"+"\t"+run_date+"\t"+"否"+"\t")
                    if os.path.isfile(run_dir+"/index2id_bak.txt"):
                        index_file=run_dir+"/index2id_bak.txt"
                    elif os.path.isfile(run_dir+"/index2id.bak.txt"):
                        index_file=run_dir+"/index2id.bak.txt"
                    elif os.path.isfile(run_dir+"/index2id.txt"):
                        index_file=run_dir+"/index2id.txt"
                    else:
                        sys.exit("err: There is no index2id.txt in "+run_dir+"!!!")
                    indxf=open(index_file,'r')
                    for line1 in indxf:
                        line1=line1.strip()
                        if re.search(proj_d[project_type],line1.split("\t")[1]):
                            smp_nu+=1
                            mapd=''
                            sd=''
                            try:
                                index=line1.split("\t")[0]
                                mapq_file=run_dir+"/"+index+"_rawlib_rmdup_MAPQ10_Fbin_GC_All_Merge400Kb_Normalized_LogRR_MAPD_INFO.txt"
                                sd_file=run_dir+"/"+index+"_400Kb_DNAcopy_Info_CNV_RealCNV_LogRR_Effective_MAPD_INFO.txt"
                                mapdf=open(mapq_file,"r")
                                sdf=open(sd_file,"r")
                                for line2 in mapdf:
                                    line2=line2.strip()
                                    if line2.startswith("##MAPD"):
                                        mapd=line2.split("\t")[1]
                                mapdf.close()
                                for line3 in sdf:
                                    line3=line3.strip()
                                    if line3.startswith("##SD"):
                                        sd=line3.split("\t")[1]
                                sdf.close()
                                if (float(sd)>0.15 and float(sd)<0.4) or (float(mapd)>0.15 and float(mapd)<0.4):
                                    wave_nu+=1
                                elif float(sd)>0.4 or float(mapd)>0.4:
                                    noresult_nu+=1
                            except Exception as err:
                                continue
                    indxf.close() 
                    if project_type != "PGS":
                        wave_nu=0
                        noresult_nu=0
                    outf.write(str(smp_nu)+"\t"+str(wave_nu)+"\t"+"\t"+str(noresult_nu)+"\t"+"\t"+"\n")
    outf.close()
