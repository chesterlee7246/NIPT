#!/usr/bin/python
#-*-coding:utf-8-*-
import os, re, sys
import shutil, glob, time, json
from optparse import OptionParser
import smtplib
from multiprocessing import Process, Pool
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email.header import Header
from email import encoders
from email.mime.multipart import MIMEMultipart
from email.mime.application import MIMEApplication
import MySQLdb
import numpy as np
import requests
import json
import ConfigParser
import commands
import requests.adapters
import subprocess
import random, math
import datetime


os.umask(002)
#控制写入质控数据库的Software_version,Database_Version, Pipeline_Version
version = "V1.0.0.1"

#import data into  mysql database
dbhost = "172.16.10.31"
dbuser = "dataqc"
dbpass = "2019"

#self.debug replace lims by lims_test
# lims = 'https://lims.basecare.cn'
lims = 'https://lims.bioerp.com'
lims_test = 'https://test.basecare.cn'
lims_ip = 'http://192.168.10.195:8069'
lims_ip_test = 'http://192.168.10.185:8069'
###lims接口登录信息###
name  = "api-user"
pwd = "MjI4JmFjdGlvbj03MCZtb2Rlb20201221"

class Pipeline():
    #把ip地址和文件目录、站点信息等类属性绑定到Pipeline实例（__init__方法第一个参数永远是self，表示创建的实例本身）
    def __init__(self, pip_dir, indir, site, lims,lims_test, lims_ip, lims_ip_test, debug=False):
        self.pip_dir = pip_dir
        self.site = site
        self.indir = indir
        self.lims = lims
        self.lims_test=lims_test
        self.lims_ip = lims_ip
        self.lims_ip_test = lims_ip_test
        self.debug = debug
        tmp = self.indir
        self.runid = os.path.basename(re.sub(r'\/*$', '', tmp))
        # self.date=self.runid[3:5]+"/"+self.runid[5:7]+"/"+self.runid[7:9]
        self.run_number = self.runid.split('-')[-1].split('_')[0].replace('.csv', '')
        self.time = self.run_number.replace('SQR', '')
        self.date = self.time[:2] + '/' + self.time[2:4] + '/' +self.time[4:6]

    def login(self):
        """登录获取session_id，并保存(返回session_id=ed383cc6cbfd4d83cb64855b5db47d2ca8e5f69b)"""
        response = requests.request("POST",  "http://192.168.10.123:8069/ir/get/session_id", data={'login': name, 'password': pwd})

        if response.text.find('!DOCTYPE HTML PUBLIC') > 0:
            print('网络错误')
            exit()
        # res = eval(response.text.replace('false', 'False'))
        res = json.loads(response.text)

        http_code = res.get('http_code')
        if http_code != 200:
            print('账号或密码错误，错误代码%s' % http_code)
            exit()

        data = res.get('data')
        api_txt = open(self.pip_dir + "/config/api.db", 'w')
        api_txt.write(str(data))
        api_txt.close()
        return 'session_id=' + data.get('session_id')

    def get_session_id(self):
        """
        读取上一次存储的session_id,若文件不存在则重新调用login()方法获取session_id,
        session_id的默认有效期是90天
        """
        try:
            file = open(self.pip_dir + "/config/api.db",'r')
            file_context = file.read()
        except IOError:
            file = open(self.pip_dir + "/config/api.db", 'w')
            file_context = ''
        file.close()
        if file_context.find('session_id') > 0:
            f_context = eval(file_context)
            session_id = f_context.get('session_id')
            expires = f_context.get('expires')
            now_time = datetime.datetime.now().strftime('%Y-%m-%d')
            if expires < now_time:
                Cookie = self.login()
            else:
                Cookie = 'session_id=' + session_id
        else:
            Cookie = self.login()

        ###验证Cookie是否有效####
        res1  = requests.request("POST", "http://192.168.10.123:8069/ir/get/session_id", headers = {"Cookie": Cookie}, data = {})
        if res1.text.find("!DOCTYPE") >0:
            Cookie = self.login()
        return Cookie

    def sample_types(self,company_id, barcode):
        #根据sample名称与站点编号(company id)拉取样本类型,返回值：normal/egel
        response = requests.request("POST", url="http://192.168.10.123:8069/nips/sample/search", headers={'Cookie': self.get_session_id()},data={"company_id": company_id, "barcode": barcode})
        sample_type = ""
        http_code = json.loads(response.text)["http_code"]
        if http_code == 200:
            if json.loads(response.text)["data"][0]["tags"]:
                sample_type = json.loads(response.text)["data"][0]["tags"][0].lower()
            else:
                sample_type = "normal"
            return sample_type
        elif http_code == 404:
            print(barcode + " may not exist in lims")
        elif http_code == 401:
            print("company_id不能为空")
        else:
            print("exame you sample")
        return sample_type

    def get_index2id(self):
        #把index、sample_name、样本类型和站点编号写入index2id文件，并返回其绝对路径
        fjson=self.indir + "/ion_params_00.json"
        findex2id=self.indir + "/index2id.txt"
        findex2id_tmp = self.indir + "/index2id_tmp.txt"
        os.system("perl {}/Lib/extract_sampleid_new.pl {} {} ".format(self.pip_dir, fjson, findex2id_tmp))
        other_sample = os.path.join(self.indir, "Other_sample")
        os.system("mkdir -p {}".format(other_sample))
        findex2id_write = open(findex2id, "w")
        ####规定SZMH的indexid##
        if self.site == "SZMH" or self.site == "SHRJ":
            for line in open(findex2id_tmp, "rt").readlines():
                line = line.strip().split('\t')
                sample_name = line[1].lower()
                if all([x not in sample_name for x in ['c', 'n', 'p']]) or (
                        sample_name.count('p') > 1 and 'nips-p' not in sample_name):
                    os.system("mv {}/{}* {}".format(self.indir, self.indir+"/"+line[0], other_sample))
                    continue
                if len(line) >= 3 and any([x in line[2].lower() for x in ['normal', 'egel', 'plus']]):
                    findex2id_write.write(line[0] + "\t" + line[1] + "\t" + line[2] + "\n")
                elif len(line) == 2:
                    findex2id_write.write(line[0] + "\t" + line[1] + "\tnormal\n")
            findex2id_write.close()
        else:
            for line in open(findex2id_tmp, "rt").readlines():
                trup = ("C", "A", "B", "NIPS")
                line = line.strip().split('\t')
                if  not line[1].startswith(trup):
                    print(line[1] + " may not NIPT sample")
                    os.system("mv {}* {}".format(self.indir + "/" + line[0], other_sample))
                    continue
                if len(line) != 3:
                    print(line[1] + " may not exist in lims or not defined sample_type")
                    os.system("mv {}* {}".format(self.indir + "/" + line[0], other_sample))
                    continue
                company_id = line[2]
                barcode = line[1]
                sample_type = self.sample_types(company_id, barcode)
                findex2id_write.write(line[0] + "\t" + line[1] + "\t" + sample_type + "\t" + line[2] + "\n")
            findex2id_write.close()
        return (findex2id)

    def sample_type(self):
        #返回index为key,样本类型为值的字典
        findex2id = self.get_index2id()
        idx_dict = {}
        for line in open(findex2id,"rt").readlines():
            line = line.strip().split("\t")
            sample_name = line[1].lower()
            if all([x not in sample_name for x in ['c', 'n', 'p']]) or (sample_name.count('p') > 1 and 'nips-p' not in sample_name):
                continue
            idx_dict[line[0]] = line[2]
        return idx_dict

    def z_score_sample_type(self):
        findex2id = self.get_index2id()
        idx_dict = {}
        for line in open(findex2id, "rt").readlines():
            line = line.strip().split("\t")
            sample_name = line[1].lower()
            if "c" not in sample_name:
                continue
            if self.site == "SHRJ" and "24c" in sample_name:
                continue
            idx_dict[line[0]] = line[2]
        return idx_dict

    def analysis(self):#确定样本类型,返回运行命令
        sample_types = self.sample_type()
        cmds = []
        for k, v in sample_types.items():
            nbin = "{}/{}_rawlib_rmdup_MAPQ60_Nbin.txt".format(self.indir, k)
            if not os.path.isfile(nbin):
                continue
            if 'egel' in v:
                cmds.append(self.egel_pip(nbin))
            else:
                cmds.append(self.normal_pip(nbin))
        return cmds

    def normal_pip(self, nbin):#常规样本的分析命令(MAPQ60的Nbin文件)
        return("perl "+self.pip_dir+"/NIPT/auto_run_analysis.pl "+nbin+" "+self.pip_dir + "/NIPT/")

    def egel_pip(self, nbin):#富集样本的分析命令(MAPQ60的Nbin文件)
        return("perl "+self.pip_dir+"/EGEL/auto_run_analysis.pl "+nbin+" "+self.pip_dir + "/EGEL/")
    
    def common_analysis(self):
        os.system("perl {}/EGEL/Calculate_Autosomal_ZScore.pl {}".format(self.pip_dir, self.indir))
        os.system("perl {}/EGEL/Calculate_ChrXY_ZScore.pl {}".format(self.pip_dir, self.indir))
        os.system("perl {}/EGEL/Extract_Zscore_Info.pl {}".format(self.pip_dir, self.indir))
        os.system("perl {}/EGEL/create_report_html_info.pl {} {} {}".format(self.pip_dir, self.indir, self.pip_dir, self.indir))
        os.system("perl {}/CNV/CHD/parallel_logRR_NIPT-CHD.pl {} {}".format(self.pip_dir, self.indir, self.pip_dir +'/CNV/CHD/LOGRR/'))
        os.system("perl {}/CNV/CHD/Auto_DNAcopy_BreakPoints.pl {} {} {}".format(self.pip_dir, self.indir, self.pip_dir +'/CNV/CHD/BreakPoints/', self.pip_dir +'/CNV/CHD/DatabaseAnn/'))

    def NanTong_png(self):
        os.system("perl {}/NIPT/NanTong_png/run_sample_id_png_info.pl {} {}".format(self.pip_dir, self.indir, self.pip_dir +'/NIPT/NanTong_png/'))
    
    def SZMH_NIPT_CHD(self):
        os.system("perl {}/CNV/CHD/parallel_logRR_NIPT-CHD.pl {} {}".format(self.pip_dir, self.indir, self.pip_dir +'/CNV/CHD/LOGRR/'))
        os.system("perl {}/CNV/CHD/Auto_DNAcopy_BreakPoints.pl {} {} {}".format(self.pip_dir, self.indir, self.pip_dir +'/CNV/CHD/BreakPoints/', self.pip_dir +'/CNV/CHD/DatabaseAnn/'))

    def SZMH_upload(self):
        os.system("perl {}/NIPT/SZMH_upload_oldLims/run_id_info.pl {} {}".format(self.pip_dir, self.indir,self.pip_dir + '/NIPT/SZMH_upload_oldLims/'))
        os.system("grep -v egel {} > {}".format(self.indir+"/index2id.bak.txt", self.indir+"/index2id.txt"))
        os.system("perl {}/NIPT/SZMH_upload_oldLims/run_sample_id_info.pl {} {}".format(self.pip_dir, self.indir, self.pip_dir +'/NIPT/SZMH_upload_oldLims/'))
        os.system("perl {}/NIPT/SZMH_upload_oldLims/run_sample_id_png_info.pl {} {}".format(self.pip_dir, self.indir, self.pip_dir +'/NIPT/SZMH_upload_oldLims/'))
        os.system("perl {}/NIPT/SZMH_upload_oldLims/run_sample_id_abnormal_info.pl {} {}".format(self.pip_dir, self.indir, self.pip_dir +'/NIPT/SZMH_upload_oldLims/'))
        ###苏州市立医院有egel###
        os.system("grep  egel {} > {}".format(self.indir + "/index2id.bak.txt", self.indir + "/index2id.txt"))
        os.system("perl {}/EGEL/SZMH_upload_oldLims/run_sample_id_info.pl {} {}".format(self.pip_dir, self.indir,self.pip_dir + '/EGEL/SZMH_upload_oldLims/'))
        os.system("perl {}/EGEL/SZMH_upload_oldLims/run_sample_id_png_info.pl {} {}".format(self.pip_dir, self.indir,self.pip_dir + '/EGEL/SZMH_upload_oldLims/'))
        os.system("perl {}/EGEL/SZMH_upload_oldLims/run_sample_id_abnormal_info.pl {} {}".format(self.pip_dir, self.indir,self.pip_dir + '/EGEL/SZMH_upload_oldLims/'))

    def upload(self):#上传分析好的样本
        os.system("python {}/NIPT/upload.py {} {}  {}".format(self.pip_dir,self.indir, self.site,self.pip_dir))

    def gc_gcv(self, idx):
        gc, gcv = 'false', 'false'
        gc_file = self.indir + '/' + idx + '_rawlib_rmdup_EachChromosomeGC_UR.txt'
        gcs = []
        if os.path.isfile(gc_file):
            with open(gc_file, 'rt') as gc:
                for line in gc:
                    line = line.strip().split('\t')
                    if not line:
                        continue
                    if line[0] == 'AllGC':
                        gc = float(line[-1]) * 100
                    else:
                        gcs.append(float(line[-1]))
            gc_mean = np.mean(gcs)
            gc_sd = np.std(gcs, ddof = 1)
            gcv = (gc_sd*1.0/gc_mean)*100
        if gc != 'false':
            gc = '%.2f'%gc + '%'
            gcv = '%.2f'%gcv + '%'
        return gc, gcv

    def plugin_report(self, report_date=None):
        Report_Date=time.strftime('%Y%m%d',time.localtime(time.time()))
        if report_date == None:
            report_date = Report_Date
        os.system("perl "+self.pip_dir+"/Lib/create_report_html_info.pl " + self.indir+" " + self.pip_dir+"/Lib " + report_date + " "  + self.site )

    def qc_report(self):
        html, sqls = self.make_qc_report()
        self.mail_qc_report(html)
        self.import_db(sqls)
    def make_qc_report(self):
        run_sql = "INSERT INTO `NIPT_run_QC`(`Site`,`Run_ID`,`Date`,`Sample_Num`,`Male_rate`,`Female_rate`,`Low_quality_Num`,`Effective_Reads_Num`,`All_reads_Num`,`Avarage_read_length`,`ISP_loading`,`Enrichment`,`Clonal`,`Final_Library`,`Empty_Wells`,`No_Template`,`Polyclonal`,`Low_Quality`,`Sequencer_number`) VALUES('%s','%s','%s',%s,'%s','%s',%s,'%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s')"
        sample_sql = "INSERT INTO `NIPT_QC` (`Site`,`Run_ID`,`Date`,`Index`,`Sample_name`,`sample_type`,`Raw_reads`,`Unique_reads`,`Unique_rate`,`Dup_reads`,`Dup_rate`,`Mapping_rate`,`Coverage`,`Fetal`,`Fetal2`,`Predict`,`chr13`,`chr18`,`chr21`,`chrX`,`Average_length`,`Hightest_x`,`Hightest_y`,`Hightest_width`,`Secondary_x`,`Secondary_y`,`Secondary_width`,`Other(Z>2.5)`,`Software_Version`,`Database_Version`,`Pipeline_Version`) VALUES('%s','%s','%s','%s','%s','%s','%s',%s, %s, %s, %s, %s,'%s','%s',%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,'%s','%s','%s')"
        sql = []
        run_html = "<tr><th>Site</th><th>Run_ID</th><th>Date</th><th>样本总数</th><th>男性样本比例</th><th>女性样本比例</th><th>低质量样本数</th><th>reads_mean_sd<br>（raw/uniq）</th><th>浓度均值</th><th>有效Reads(M)</th><th>总数据量(G)</th><th>平均读长(bp)</th><th>ISP_loading</th><th>Enrichment</th><th>Clonal</th><th>Final_Library</th><th>Empty_Wells</th><th>No_Template</th><th>Polyclonal</th><th>Low_Quality</th><th>测序仪编号</th></tr>\n"
        sample_html = "<tr><th>Index</th><th>Sample_name</th><th>Sample_type</th><th>Raw_reads</th><th>Unique_reads</th><th>Unique_rate</th><th>Dup_reads</th><th>Dup_rate</th><th>Mapping_rate</th><th>Fetal</th><th>Fetal2</th><th>Predict</th><th>chr19_mosaic</th><th>chr13</th><th>chr18</th><th>chr21</th><th>chrX</th><th>Average_length</th><th>Height_peak</th><th>Secondary_paek</th><th>Other(Z>2.5)</th></tr>\n"
        index2id = self.find_index_file()
        sample_format = "<tr>{}</tr>".format("<td>{}</td>" * 21)
        run_format = "<tr>{}</tr>".format("<td>{}</td>" * 21)
        run_info = self.run_info()
        sample_count, male_count, female_count, low_quality_Num = 0, 0, 0, 0
        male_sumfetal, female_sumfetal,male_avgfetal, female_avgfetal = 0, 0, 0, 0
        run_total_reads, run_uniq_reads = [], []
        sample_types = self.sample_type()
        with open(index2id, 'rt') as fh:
            for line in fh:
                arr = line.strip().split("\t")
                idx, sample_name  = arr[0:2]
                if idx not in sample_types:
                    continue
                sample_type = sample_types[idx]
                if not os.path.exists("{}/{}_rawlib_rmdup_MAPQ60_2000Kb_Fbin_GC_All_Normalized_Percentage_ZScore_All.txt".format(self.indir, idx)) and not \
                    os.path.exists("{}/{}_rawlib_rmdup_MAPQ60_Fbin_GC_Per_ZScore.txt".format(self.indir, idx)):
                    continue
                sample_count += 1
                sample_info = self.sample_info(idx)
                if sample_info['Fetal'] == 'NA':
                    continue
                gender = self.sample_gender(idx)
                wave = self.sample_wave(idx)
                if gender.lower() == 'male':
                    male_sumfetal = male_sumfetal + float(sample_info['Fetal'])
                    male_count += 1
                else:
                    female_count += 1
                    female_sumfetal = female_sumfetal + float(sample_info['Fetal'])
                run_total_reads.append(float(sample_info['total_reads'])/1000000)
                run_uniq_reads.append(float(sample_info['uniq_reads'])/1000000)
                #突出显示Z值>=2.58的chr13,18,21、X对应值
                chrs = ['13', '18', '21', 'X']
                color_end = "</font>"
                #按color_13, color_18, color_21, color_X的顺序将这几条染色体的颜色标识放入color_chr中
                color_chr = ['','','','']
                for i in range(len(chrs)):
                    chrom = 'chr' + chrs[i]
                    if abs(float(sample_info[chrom])) >= 2.58:
                        color_chr[i] = "<font color=\"#FF00FF\">"

                fetal_color, uniq_color = '',''
                fetal = float(sample_info['Fetal'])
                uniq_reads = int(self.sample_uniq_reads(idx))
                if 'plus' in sample_type:
                    if fetal < 0.10:
                        fetal_color = "<font color=\"#FF0000\">"
                    if uniq_reads < 3000000:
                        uniq_color = "<font color=\"#FF0000\">"
                else:
                    if 'egel' in sample_type:
                        if fetal < 0.10:
                            fetal_color = "<font color=\"#FF0000\">"
                        if uniq_reads < 1500000:
                            uniq_color = "<font color=\"#FF0000\">"
                    else:
                        if fetal < 0.035:
                            fetal_color = "<font color=\"#FF0000\">"
                        elif uniq_reads < 3000000:
                            uniq_color = "<font color=\"#FF0000\">"

                ##给质控表添加chr19的嵌合率##
                find_eff = "{}/{}_100Kb_DNAcopy_Info_CNV_RealCNV_LogRR_Effective.txt".format(self.indir,idx)
                eff = open(find_eff, "r")
                length_list = []
                mosaic_dict = {}
                for line in eff.readlines():
                    if line.startswith("#") or line.startswith("ID"):
                        continue
                    line = line.strip().split("\t")
                    if line[1] == "chr19":
                        length = int(int(line[3]) - int(line[2]) + 1)
                        seg_mean = line[5]
                        length_list.append(length)
                        mosaic_dict[length] = seg_mean
                ml_seg_m = mosaic_dict[np.max(length_list)]#最长的一段logRR拿出来计算嵌合率
                if ml_seg_m[0] == "-":
                    multi = "-"
                else:
                    multi = ""
                cnv_mosaic_tmp = os.popen("/home/bioinfo/local/bin/mosaic {}".format(ml_seg_m))
                cnv_mosaic = str(cnv_mosaic_tmp.readline().strip()).split(" ")[-1].replace("%", "")
                chr19_mosaic = multi+cnv_mosaic
                Height = str(wave["Hightest_x"]+", "+wave["Hightest_y"]+", "+wave["Hightest_width"])
                Secondary = str(wave["Secondary_x"]+", "+wave["Secondary_y"]+", "+wave["Secondary_width"])
                sample_html += sample_format.format(idx.replace('IonXpress_', ''), sample_name,sample_type, format(sample_info['total_reads'], ','), uniq_color + str(format(sample_info['uniq_reads'], ',')) + color_end, sample_info['uniq_rate'], format(sample_info['dup_reads'], ','), sample_info['dup_frac'], sample_info['map_rate'], fetal_color + str(sample_info['Fetal']) + color_end, sample_info['Fetal2'], sample_info['Predict'],chr19_mosaic, color_chr[0] + sample_info['chr13'] + color_end, color_chr[1] + sample_info['chr18'] + color_end, color_chr[2] + sample_info['chr21'] + color_end, color_chr[3] + sample_info['chrX'] + color_end, wave["Average"], Height,Secondary, sample_info['Other(Z>2.5)'])
                if sample_info['Predict'] == 'NA':
                    sample_info['Predict'] = 'NULL'
                sql.append(sample_sql % (self.site, run_info['id'], self.date, idx, sample_name, sample_type, sample_info['total_reads'], sample_info['uniq_reads'], sample_info['uniq_rate'], sample_info['dup_reads'], sample_info['dup_frac'], sample_info['map_rate'], sample_info['coverage'], sample_info['Fetal'], sample_info['Fetal2'],sample_info["Predict"], sample_info['chr13'], sample_info['chr18'], sample_info['chr21'], sample_info['chrX'],wave["Average"], wave["Hightest_x"],wave["Hightest_y"],wave["Hightest_width"],wave["Secondary_x"],wave["Secondary_y"],wave["Secondary_width"], sample_info['Other(Z>2.5)'], version, version, version))
        male_rate = str("%.0f" %(male_count * 100.0 / sample_count)) + '%(' + str(male_count) +')'
        female_rate = str("%.0f" % (female_count * 100.0/ sample_count)) + '%(' + str(female_count) + ')'

        if male_count != 0:
            male_avgfetal = str("%.4f" % (float(male_sumfetal) / male_count))

        else:
            male_avgfetal = " "
        if female_count != 0:
            female_avgfetal = str("%.4f" %(float(female_sumfetal)/female_count))
        else:
            female_avgfetal =" "
        avgfetal = male_avgfetal + "/" + female_avgfetal + "<br>（男/女）"
        #calculate raw_reads mean and sd for run
        run_raw_mean = round(np.mean(run_total_reads), 2)
        run_raw_sd = round(np.std(run_total_reads, ddof=1), 2)
        run_raw_mean_sd = str(run_raw_mean) + '±' + str(run_raw_sd) + "Mb"

        #calculate uniq_reads mean and sd for run
        run_uniq_mean = round(np.mean(run_uniq_reads), 2)
        run_uniq_sd = round(np.std(run_uniq_reads, ddof=1), 2)
        run_uniq_mean_sd = str(run_uniq_mean) + '±' + str(run_uniq_sd) + "Mb"
        reads_mean_sd = run_raw_mean_sd + "/ <br>" + run_uniq_mean_sd

        run_html += run_format.format(self.site, run_info['id'], self.date, sample_count, male_rate, female_rate, run_info['Low_quality_Num'], reads_mean_sd, avgfetal, run_info['reads'], run_info['gb'], run_info['length'], run_info['isp'], run_info['enrich'], run_info['clonal'], run_info['final'], run_info['empty'], run_info['noenrich'], run_info['polyclonal'], run_info['low'], run_info['instrument'])
        sql.append(run_sql % (self.site, run_info['id'], self.date, sample_count, male_rate, female_rate, run_info['Low_quality_Num'], run_info['reads'], run_info['gb'], run_info['length'], run_info['isp'], run_info['enrich'], run_info['clonal'], run_info['final'], run_info['empty'], run_info['noenrich'], run_info['polyclonal'], run_info['low'], run_info['instrument']))
        html = self.report_html()
        html += '<table width="90%" class="table">'
        html += run_html 
        html += "</table>"
        html += "<br /> <br />"
        html += '<table width="90%" class="table">'
        html += sample_html 
        html += "</table>"
        html += "</body>"
        return([html, sql])

    def report_html(self):
        html_header = """
        <head>
        <title></title>
        <style type="text/css">
        body,table{
        font-size:10px;
        }
        table{
        empty-cells:show;
        border-collapse: collapse;
        margin:0 auto;
        }
        td{
        height:30px;
        }

        .table{
        border:1px solid #cad9ea;
        color:#666;
        }
        .table th {
        background-repeat:repeat-x;
        height:30px;
        text-align:center;
        vertical-align:middle;
        }
        .table td,.table th{
        border:1px solid #cad9ea;
        padding:0 1em 0;
        text-align:center;
        vertical-align:middle;
        }
        .table tr.alter{
        background-color:#f5fafe;
        }
        </style>
        </head>
        <body>
        """
        return(html_header)
    def sample_info(self, idx):
        sample_info = dict()
        dup_info = self.sample_dup_rate(idx)
        sample_info['uniq_reads'] = self.sample_uniq_reads(idx)
        sample_info['coverage'] = self.sample_cov(idx)
        sample_info['dup_frac'] = float("%.4f" % dup_info['dup_frac'])
        sample_info['uniq_rate'] = float("%.4f" % dup_info['uniq_rate'])
        sample_info['map_rate'] = float("%.4f" % dup_info['map_rate'])
        sample_info['total_reads'] = dup_info['total_reads']
        sample_info['dup_reads'] = dup_info['dup_reads']
        ff = self.sample_fetal_info(idx)
        sample_info['Fetal'] = ff['Fetal1']
        sample_info['Fetal2'] = ff['Fetal2']
        sample_info['Predict'] = ff['Predict']
        z_info = self.sample_zscores(idx)
        sample_info['chr13'] = z_info['chr13']
        sample_info['chr18'] = z_info['chr18']
        sample_info['chr21'] = z_info['chr21']
        sample_info['chrX'] = z_info['chrX']
        sample_info['Other(Z>2.5)'] = z_info['Other(Z>2.5)']
        return(sample_info)

    def run_info(self):
        isp_info = self.isp_info()
        analysis_info = self.analysis_info()
        run_info = self.run_expinfo()
        run = dict()
        run['id'] = run_info['Run Name'][run_info['Run Name'].find("SQR"):run_info['Run Name'].find("SQR") + 12]
        run['gb'] = float("%.4f" %(isp_info['final'] / 1000000000))
        run['isp'] = float("%.4f" % (analysis_info['Bead Wells'] / (analysis_info['Total Wells'] - analysis_info['Excluded Wells'])))
        run['empty'] = float("%.4f" % (1 - run['isp']))
        run['enrich'] = float("%.4f" % (analysis_info['Live Beads'] / analysis_info['Bead Wells']))
        run['noenrich'] = float("%.4f" % (1 - run['enrich']))
        run['polyclonal'] = float("%.4f" % (isp_info['filtered_polyclonal'] / analysis_info['Live Beads']))
        run['clonal'] = float("%.4f" % (1 - run['polyclonal']))
        run['low'] = float("%.4f" % (isp_info['filtered_low_quality'] / (analysis_info['Live Beads'] - isp_info['filtered_polyclonal'])))
        run['reads'] = float("%.4f" %(isp_info['final_library_reads'] / 1000000))
        run['final'] = float("%.4f" % (isp_info['final_library_reads'] / (analysis_info['Live Beads'] - isp_info['filtered_polyclonal'])))
        run['instrument'] = run_info['Instrument']
        run['length'] = int(isp_info['final']/isp_info['final_library_reads'])
        run['Low_quality_Num'] = self.low_quality_num()
        return(run)

    def sample_wave(self, idx):
        wave_file = self.indir+"/"+ idx + "_rawlib.ionstats_alignment.txt"
        wave_dict = {}
        with open(wave_file, "rt") as fh:
            for line in fh:
                line = line.strip()
                if len(line) == 0:
                    continue
                line_sp = line.split("\t")
                line1_sp = line_sp[1].split(",")
                if line.startswith("Average"):
                    wave_dict["Average"] = line_sp[1]
                elif line.startswith("Highest Peak"):
                    wave_dict["Hightest_x"] = line1_sp[0]
                    wave_dict["Hightest_y_tmp"] = line1_sp[1]
                    wave_dict["Hightest_width"] = line1_sp[2]
                elif line.startswith("Others"):
                    wave_dict["Secondary_x"] = line1_sp[0]
                    wave_dict["Secondary_y_tmp"] = line1_sp[1]
                    wave_dict["Secondary_width"] = line1_sp[2]
            if "Secondary_x" not in wave_dict.keys():
                wave_dict["Secondary_x"], wave_dict["Secondary_y"], wave_dict["Secondary_width"] = 'NULL', 'NULL', 'NULL'
                wave_dict["Hightest_y"] = str(1)
            else:
                wave_dict["Secondary_y"] = str("%.2f" % float(float(wave_dict["Secondary_y_tmp"])/float(wave_dict["Hightest_y_tmp"])))
                wave_dict["Hightest_y"] = str(1)
        return wave_dict

    def analysis_info(self):
        analysis_file = self.indir + '/analysis.bfmask.stats'
        analysis_info = dict()
        with open(analysis_file, 'rt')  as fh:
            fh.readline()
            for line in fh:
                arr = line.strip().split(" = ")
                if len(arr) == 2:
                    analysis_info[arr[0]] = float(arr[1])
        
        return(analysis_info)

    def isp_info(self):
        ispfile = self.indir + "/BaseCaller.json"
        info = json.load(open(ispfile, 'rt'))
        isp_info = info['Filtering']['LibraryReport']
        for kk in isp_info:
            isp_info[kk] = float(isp_info[kk])
        isp_info['final'] = float(info['Filtering']['BaseDetails']["final"])
        return(isp_info)

    def run_expinfo(self):
        exp_file = self.indir+"/expMeta.dat"
        exp_info = dict()
        with open(exp_file, 'rt') as fh:
            for line in fh:
                arr = line.strip().split(" = ")
                if len(arr) == 2:
                    exp_info[arr[0]] = arr[1]
        return(exp_info)

    def sample_dup_rate(self, idx):
        dup_file = self.indir+"/"+idx+"_BamDuplicates.json"
        dup_info = dict()
        uniq_reads = self.sample_uniq_reads(idx)
        dup_json = json.load(open(dup_file,'rt'))
        dup_info['dup_reads'] = dup_json["duplicate_reads"]
        dup_info['dup_frac'] = float('%.4f' %(dup_json["fraction_duplicates"]))
        dup_info['total_reads'] = int(dup_json["total_reads"])
        total_map = dup_json["total_mapped_reads"]
        dup_info['map_rate'] = float(total_map)/dup_info['total_reads']
        dup_info['uniq_rate'] = float(uniq_reads)/dup_info['total_reads'] 
        return(dup_info)

    def sample_uniq_reads(self, idx):
        uni_read_file=self.indir+"/"+idx+"_rawlib_rmdup_MAPQ10_Nbin.txt"
        uniq_reads = -1
        with open(uni_read_file, 'rt') as fh:
            for uni in fh:
                if uni.startswith("##unique"):
                    uniq_reads = int(uni.strip().split("\t")[-1])
                    break
        return(uniq_reads)

    def sample_zscores(self, idx):
        egel_zfile = self.indir+"/"+idx+"_rawlib_rmdup_MAPQ60_2000Kb_Fbin_GC_All_Normalized_Percentage_ZScore_All.txt"
        norm_zfile=self.indir+"/"+idx+"_rawlib_rmdup_MAPQ60_Fbin_GC_Per_ZScore.txt"
        if os.path.isfile(egel_zfile):
            zscore_file = egel_zfile
        else:
            zscore_file = norm_zfile
        z_info = dict()
        z_other = 0
        with open(zscore_file, 'rt') as fh:
            for line in fh:
                if line.startswith("##"):
                    continue
                line = line.strip().split('\t')
                z = float(line[1])
                if abs(z) >= 2.58:
                    z_other += 1
                z_info[line[0]] = "%.3f" % z
        z_info['Other(Z>2.5)'] = z_other
        z_info['chrY'] = 'false'
        return z_info

    def sample_gender(self, idx):
        egel_zfile = self.indir+"/"+idx+"_rawlib_rmdup_MAPQ60_2000Kb_Fbin_GC_All_Normalized_Percentage_ZScore_All.txt"
        norm_zfile=self.indir+"/"+idx+"_rawlib_rmdup_MAPQ60_Fbin_GC_Per_ZScore.txt"
        if os.path.isfile(egel_zfile):
            zscore_file = egel_zfile
        else:
            zscore_file = norm_zfile
        gender = ''
        with open(zscore_file, 'rt') as fh:
            for line in fh:
                if line.startswith('##gender') or line.startswith('##Gender'):
                    line = line.strip().split('\t')
                    gender = line[1]
                    break
        return gender

    def sample_fetal_info(self, idx):#读取胎儿浓度信息文件
        fetal_info = dict()
        norm_y_file = self.indir + "/" + idx +'_rawlib_rmdup_MAPQ60_Fbin_GC_Per_ZScore.txt'
        egel_y_file = self.indir + "/" + idx +'_rawlib_rmdup_MAPQ60_2000Kb_Fbin_GC_All_Normalized_Percentage_ZScore_All.txt'
        assert os.path.isfile(norm_y_file) or os.path.isfile(egel_y_file), 'There is no file about fetal fraction'
        fetal1, fetal2, predict = '0.0000','0.0000','0.0000'
        if os.path.isfile(norm_y_file):#如果是常规样本(存在常规y浓度文件)
            size_file = self.indir + "/" + idx +'_rawlib_rmdup_Size_Info_Percentage.txt'
            if os.path.isfile(size_file):#如果是女胎，fetel1等于预测浓度
                with open(size_file, 'rt') as szf:
                    for line in szf:
                        if line.startswith('PFetal'):
                            line = line.strip().split('\t')
                            fetal1 = predict = "%.4f" % float(line[-1])
                            break
            if self.sample_gender(idx).lower() == 'male':#如果是男胎，fetel1改为y浓度
                with open(norm_y_file, 'rt') as yf:
                    for line in yf:
                        if line.startswith('##Gender'):
                            line = line.strip().split('\t')
                            fetal1 = fetal2 = "%.4f" % float(line[-1])
                            break
        elif os.path.isfile(egel_y_file):#如果是富集样本(存在富集y浓度文件)
            seqff_file = self.indir + "/" + idx +'_SeqFF_Fetal.txt'
            if os.path.isfile(seqff_file):#如果是女胎，fetel1等于预测浓度
                with open(seqff_file, 'rt') as f:
                    for l in f:
                        l = l.strip().split(',')
                        if l[0].strip() == '"PROTON"':
                            if l[-1] == 'NA':
                                fetal1 = predict = 'NA'
                            else:
                                fetal1 = predict = "%.4f" % float(l[-1])
                            break
            if self.sample_gender(idx).lower() == 'male':#如果是男胎，fetel1改为y浓度
                with open(egel_y_file, 'rt') as yf:
                    for line in yf:
                        if line.startswith('##concentration'):
                            line = line.strip().split('\t')
                            fetal1 = fetal2 = "%.4f" % float(line[-1])
        fetal_info['Fetal1'] = fetal1
        fetal_info['Fetal2'] = fetal2
        fetal_info['Predict'] = predict
        return fetal_info

    def low_quality_num(self):
        idx_type_dct = self.sample_type()
        low_qual_num = 0
        for idx in idx_type_dct.keys():
            nbin = "{}/{}_rawlib_rmdup_MAPQ60_Nbin.txt".format(self.indir, idx)
            if not os.path.isfile(nbin):
                continue
            sample_type = idx_type_dct[idx].lower()
            if self.sample_fetal_info(idx)['Fetal1'] == 'NA':
                fetal = 0
            else:
                fetal = float(self.sample_fetal_info(idx)['Fetal1'])
            uniq_reads = int(self.sample_uniq_reads(idx))
            if 'plus' in sample_type:
                if fetal < 0.10:
                    low_qual_num += 1
                elif uniq_reads < 3000000:
                    low_qual_num += 1
            else:
                if 'egel' in sample_type:
                    if fetal < 0.10:
                        low_qual_num += 1
                    elif uniq_reads < 1500000:
                        low_qual_num += 1
                else:
                    if fetal < 0.035:
                        low_qual_num += 1
                    elif uniq_reads < 3000000:
                        low_qual_num += 1
        return low_qual_num

    def sample_cov(self, idx):
        coverage = -0.001
        cov_file=self.indir+"/"+idx+"_rawlib_rmdup_unique_Cov.txt"
        if not os.path.isfile(cov_file):
            return(coverage)

        with open(cov_file, 'rt') as fh:
            for cov in fh:
                if cov.startswith("Cov"):
                    cov1 = cov.strip().split('\t')[-1]
                    coverage = float(cov1)
        return(coverage)

    def find_index_file(self):
        for ff in ['index2id_bak.txt', 'index2id.bak.txt', 'index2id.txt']:
            if os.path.isfile("{}/{}".format(self.indir, ff)):
                return("{}/{}".format(self.indir, ff))
        raise("Cannot find index2id.txt in {}".format(self.indir))

    def import_db(self, sqls):
        database = "Project_DataQC"
        if self.debug:
            database = "Project_DataQC_test"
        db = MySQLdb.connect(host=dbhost, user=dbuser, passwd=dbpass, db=database, charset='utf8')
        try:
            cursor = db.cursor()
            for sql in sqls:
                cursor.execute(sql)
            db.commit()
            cursor.close()
            db.close()
            self.logger("成功导入质控数据库！", 'INFO')
        except Exception as ex:
            self.logger(str(ex), 'ERROR')
            db.rollback()    
            db.close()

    def get_attachment(self):
        sample_type = self.z_score_sample_type()
        chr_z_file = self.indir + "/chr_z.txt"
        chr_z = open(chr_z_file, "w")
        chr_z.write("index\tchr1\tchr2\tchr3\tchr4\tchr5\tchr6\tchr7\tchr8\tchr9\tchr10\tchr11\tchr12\t\
        chr13\tchr14\tchr15\tchr16\tchr17\tchr18\tchr19\tchr20\tchr21\tchr22\tchrX\n")
        for k,v in sample_type.items():
            if "normal" in v:
                zscore_file = self.indir+"/"+ k +"_rawlib_rmdup_MAPQ60_Fbin_GC_Per_ZScore.txt"
            elif "egel" in v:
                zscore_file = self.indir+"/"+ k +"_rawlib_rmdup_MAPQ60_2000Kb_Fbin_GC_All_Normalized_Percentage_ZScore_All.txt"
            z = []
            z.append(k)
            with open(zscore_file,"rt") as fh:
                for line in fh:
                    if line.startswith("##") or line.startswith("chrY"):
                        continue
                    line = line.strip().split("\t")
                    z.append(line[1])
            chr_z.write("\t".join(z) + "\n")
        chr_z.close()
        run_info = self.run_info()
        run_id  = run_info["id"]
        os.system("Rscript {}//NIPT/Z_score_distribution.r {} {} {} {}".format(self.pip_dir, chr_z_file, self.indir, run_id, self.site))
        attachment = self.indir+"/"+self.site + "_"+run_id+"_zscore_distribution.pdf"
        return(attachment)

    def logger(self, msg, loglevel):
        Date=time.strftime('%Y_%m_%d %H:%M',time.localtime(time.time()))
        print("[{}]{}: {}".format(loglevel, Date, msg))
        
    def mail_info(self):
        mail_info = {}
        mail_config = "{}/{}".format(self.pip_dir, "config/mail.txt")
        with open(mail_config, 'rt') as fh:
            for line in fh:
                if line.startswith("#"):
                    continue
                tmp = line.strip().split('\t')
                site = tmp[0]
                mail_info[site] = {}
                mail_info[site]['from'] = tmp[1]
                mail_info[site]['name'] = tmp[2]
                mail_info[site]['to'] = tmp[3]
                mail_info[site]['cc'] = tmp[4]
        return(mail_info)
    
    def mail_data(self, sender, receivers, carbon_copy, subject, context, context_format='plain', attachment = None):
        message = MIMEMultipart()
        message['From'] = sender
        message['To'] =  receivers
        message['Cc'] =  carbon_copy
        smtpserver = '192.168.10.41'
        username = 'erp-send-user@biodiscover.com'
        password = '9L7inux~'
        to_list = (receivers+','+carbon_copy).split(',')
        message['Subject'] = Header(subject, 'utf-8')
        message.attach(MIMEText(context, context_format, 'utf-8'))
        if attachment != None:
            att1 = MIMEApplication(open(attachment, 'rb').read())
            att1.add_header('Content-Disposition', 'attachment', filename=os.path.basename(attachment))
            message.attach(att1)
        try:
            smtp = smtplib.SMTP()
            smtp.connect(smtpserver)
            smtp.login(username, password)
            smtp.sendmail(sender, to_list , message.as_string())
            self.logger("Sendmail Success",'INFO')
            smtp.quit()
        except smtplib.SMTPException:
            self.logger("Sendmail Failed",'ERROR')

    def mail_qc_report(self, html):
        mail_info = self.mail_info() #邮箱信息，发件人收件人抄送
        items = self.site
        if self.debug:
            items = 'BIOINFO_TEST'
        mail = mail_info[items]
        sender, receivers, carbon_copy = mail['from'], mail['to'], mail['cc']
        subject = '【站点{}】NIPT检测结果质控（测序单号：{}）'.format(self.site, self.run_number)
        context = '<html><p>{}:</p><p>\t您好！</p>\n\n\t<p>以下是{}站点NIPT质控结果，请查收！\n\n\t祝好！</p>\n\n\n{}</html>'.format(mail_info[items]['name'], self.site, html)
        attachment = self.get_attachment()
        self.mail_data(sender, receivers, carbon_copy, subject, context, 'html',attachment)#发送邮件


def analysis_parse_argument(argv):
    '''
    '''
    usage = "\n\t \033[31m %prog -i xxxx -s SuZhou -p full|analysis|upload|report... [-d]\033[0m"
    parser = OptionParser(usage=usage)
    parser.add_option("-i", "--input", type='string', dest='workdir', help="Work directory(run)")
    parser.add_option("-s", "--site", dest='site', type='string', help="Site Name(abbr), BJBK, JiaYin, LinYi, NanTong, ShengJing, SZMH, XuZhou, NNFY")
    parser.add_option("-d", "--debug", dest='debug', action="store_true",default=False, help="Debug status: if in the test mode, add -d to the command line(without any argument)")
    parser.add_option("-p", "--pipeline", dest='pipeline', default='full', type='string', 
            help="pipeline[full|analysis|upload|report]:full do 'analysis', 'upload', 'report'")
    (options, args) = parser.parse_args(argv)
    return(options, args)

def usage():
    analysis_parse_argument(["-h"])
    sys.exit()

def run_cmd(cmd):
    os.system(cmd)

if __name__=="__main__":
    argv = sys.argv
    if len(argv)==1:
        usage()
    pip_dir =  os.path.dirname(os.path.abspath(sys.argv[0]))
    options, args = analysis_parse_argument(argv)
    out_dir = os.path.abspath(options.workdir)
    cmd = options.pipeline
    pipeline = Pipeline(pip_dir, out_dir, options.site, lims,lims_test, lims_ip, lims_ip_test, options.debug)
    if cmd =='full':
        pool = Pool(10)
        for cmd in pipeline.analysis():
            print(cmd)
            pool.apply_async(func=run_cmd, args=(cmd,))
        pool.close()
        pool.join()
        pipeline.common_analysis()
        if pipeline.site == 'NanTong':
            pipeline.NanTong_png()
        if pipeline.site == 'SZMH':
            # pipeline.SZMH_NIPT_CHD()
            pipeline.SZMH_upload()
        #pipeline.plugin_report()
        pipeline.upload()
        pipeline.qc_report()

    elif cmd == 'analysis':
        pool = Pool(10)
        for cmd in pipeline.analysis():
            print(cmd)
            pool.apply_async(func=run_cmd, args=(cmd,))
        pool.close()
        pool.join()
        pipeline.common_analysis()
        if pipeline.site == 'NanTong':
            pipeline.NanTong_png()
        # if pipeline.site == 'SZMH':
        #     pipeline.SZMH_NIPT_CHD()

        #pipeline.plugin_report()
        
    elif cmd == 'upload':
        if pipeline.site == "SZMH":
            pipeline.SZMH_upload()
        else:
            pipeline.upload()

    elif cmd == 'report':
        pipeline.qc_report()

    else:
        usage()
        sys.exit()

