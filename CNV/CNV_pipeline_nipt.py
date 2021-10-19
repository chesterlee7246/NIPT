#!/usr/bin/python
#---encoding:utf8---#
import os, re, sys, stat
import shutil, glob, time, json
from optparse import OptionParser
import smtplib
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email.header import Header
from email import encoders
from email.mime.multipart import MIMEMultipart
import MySQLdb
import subprocess

version = "1.0.0.16"

#import data into  mysql database
dbhost = "172.16.10.31"
dbuser = "dataqc"
dbpass = "2019"
dbname = "Project_DataQC"
#self.debug replace dbname by dbname_test
dbname_test = "Project_DataQC_test"

#self.debug replace lims by lims_test
lims = 'https://lims.bioerp.com'
lims_test = 'https://test.basecare.cn'
lims_ip = 'http://192.168.10.195:8069'
lims_ip_test = 'http://192.168.10.185:8069'

#all sites
SITES = {
        "AYFY":'normal',
        "BJBK":'normal',
        "HBRY":'normal',
        "JNYY":'normal',
        "JXFY":'normal',
        "NJFY":'normal',
        "RJYY":'normal',
        "LinYi":'normal',
        "JiaYin":'normal',
        "SuZhou":'normal',
        "NanTong":'normal',
        "GuiZhou":'normal',
        "LanZhou":'normal',
        "ShengJing":'normal',
        'XiangYa':"normal",
        "GYSY":"normal",
        "TangDu":'normal', 
        "ShanDa":"normal", 
        "HongKong":'HK',
        "Test":'normal',
        "YanFa":'normal',
        "XuZhou":'normal',
        "SHRJ":'normal'
        }

def chmod_for_curator(analysis_dir):
    os.chmod(analysis_dir, stat.S_IRUSR| stat.S_IWUSR | stat.S_IXUSR |stat.S_IRGRP | stat.S_IWGRP | stat.S_IXGRP)
    for root, dirs, files in os.walk(analysis_dir):
        for xfile in files:
            fp = os.path.join(root, xfile)
            os.chmod(fp, stat.S_IRUSR| stat.S_IWUSR| stat.S_IRGRP| stat.S_IWGRP)
        for xdir in dirs:
            dp = os.path.join(root, xdir)
            os.chmod(dp, stat.S_IRUSR| stat.S_IWUSR| stat.S_IXUSR | stat.S_IRGRP| stat.S_IWGRP | stat.S_IXGRP)
#            os.chmod(dp, stat.S_IMODE(os.stat(dp)[stat.ST_MODE]) |stat.S_IRUSR | stat.IWUSR | stat.S_IRGRP | stat.S_IXGRP | stat.S_IWGRP)

class Pipeline():
    def __init__(self, pip_dir, indir, site,lims,lims_test, lims_ip, lims_ip_test, debug=False ,ycm=False):
        self.pip_dir = pip_dir
        self.site = site
        self.indir = indir
        self.lims = lims
        self.lims_test=lims_test
        self.lims_ip = lims_ip
        self.lims_ip_test = lims_ip_test
        self.debug = debug
        self.ycm = ycm
        tmp = self.indir
        self.runid = os.path.basename(re.sub(r'\/*$', '', tmp))
        self.date=self.runid[3:5]+"/"+self.runid[5:7]+"/"+self.runid[7:9]

    def analysis(self):
        self.logger("Start Analysis", 'INFO')
        eval("self.{}_pip()".format(SITES[self.site]))
        self.logger("Analysis Finished", 'INFO')

    def normal_pip(self):
        os.system("perl "+self.pip_dir+"/CHD/parallel_logRR.pl "+self.indir+" "+self.pip_dir+"/CHD/LOGRR")
        if self.ycm:
            os.system("perl "+self.pip_dir+"/CHD//YCM/get_YCM.pl "+self.indir)
            os.system("bash "+self.pip_dir+"/CHD/YCM/YCM/scripts/batch_YCM.sh "+self.indir+" "+self.indir)
        os.system("perl "+self.pip_dir+"/CHD/Auto_DNAcopy_BreakPoints.pl "+self.indir+" "+self.pip_dir+"/CHD/BreakPoints "+self.pip_dir+"/CHD/DatabaseAnn")
        chmod_for_curator(self.indir)

    def upload(self):
        normal = '/upload_new_report/upload_chd_info_SiteCommon.pl'
        upload_bin_dir =  self.pip_dir + "/upload_new_report/"
        upload_bat = {
                'XiangYa':'/upload_new_report/upload_chd_info_SiteCommon_XiangYa.pl',
                'ShengJing':'/upload_new_report/upload_chd_info_SiteCommon_Shengjing.pl',
                }
        script = self.pip_dir + normal
        if self.site in upload_bat:
            script = self.pip_dir + upload_bat[self.site]

        ip = self.lims_ip.split("//")[1].split(":")[0]
        if subprocess.call(["ping", "-c", "2", ip])==0:
            self.lims = self.lims_ip
        if self.debug:
            self.lims = self.lims_test
            ip = self.lims_ip_test.split("//")[1].split(":")[0]
            if subprocess.call(["ping", "-c", "2", ip])==0:
                self.lims = self.lims_ip_test

        os.system("perl " + script + " " + self.indir + " " +  upload_bin_dir )

    def plugin_report(self, report_date=None):
        Report_Date=time.strftime('%Y%m%d',time.localtime(time.time()))
        if report_date == None:
            report_date = Report_Date
        os.system("perl "+self.pip_dir+"/CHD/create_report_html.pl " + self.indir+" " + self.pip_dir+"/CHD " + report_date + " "  + self.site )

    def qc_report(self):
        html, sqls = self.make_qc_report()
        self.mail_qc_report(html)
        self.import_db(sqls)
        print(sqls)

    def make_qc_report(self):
        run_sql = "INSERT INTO CNV_run_QC(`Site`,`Run_ID`,`Run_Date`,`Sample_Num`,`Low_quality_Num`,`Effective_Reads_Num`,`All_reads_Num`,`Average_read_length`,`ISP_loading`,`Enrichment`,`Clonal`,`Final_Library`,`Empty_Wells`,`No_Template`,`Polyclonal`,`Low_Quality`,`Sequencer_number`) VALUES('%s','%s','%s',%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,'%s')"
        sample_sql = "INSERT INTO CNV_QC(`Site`,`Run_ID`,`Date`,`Index`,`Sample_name`,`Raw_reads`,`Unique_reads`,`Unique_rate`,`Dup_reads`,`Dup_fraction`,`Mapping_rate`,`Coverage`,`MAPD`,`SD`,`Software_Version`,`Database_Version`,`Pipeline_Version`) VALUES('%s','%s','%s','%s','%s',%s,%s,%s,%s,%s,%s,%s,%s,%s,'%s','%s','%s')"
        sql = []
        run_html = "<tr><th>Site</th><th>Run_ID</th><th>Date</th><th>总样本数量</th><th>波动较大样本数</th><th>有效Reads(M)</th><th>总数据量(G)</th><th>平均读长(bp)</th><th>ISP loading</th><th>Enrichment</th><th>Clonal</th><th>Final Library</th><th>Empty Wells</th><th>No Template</th><th>Polyclonal</th><th>Low Quality</th><th>测序仪编号</th></tr>"
        sample_html = "<tr><th>Site</th><th>Run_ID</th><th>Date</th><th>Index</th><th>Sample_name</th><th>Raw_reads</th><th>Unique_reads</th><th>Unique_fraction</th><th>Dup_reads</th><th>Dup_fraction</th><th>Mapping_rate</th><th>Coverage</th><th>MAPD</th><th>SD</th></tr>\n"
        index2id = self.find_index_file()
        sample_format = "<tr>{}</tr>".format("<td>{}</td>" * 14)
        run_format = "<tr>{}</tr>".format("<td>{}</td>" * 17)
        run_info = self.run_info()
        sample_count = 0
        noise_count = 0
        with open(index2id, 'rt') as fh:
            for line in fh:
                arr = line.strip().split("\t")
                idx, sample_name  = arr[0:2]
                if not os.path.exists("{}/{}_rawlib_rmdup_MAPQ10_Fbin_GC_All_Merge_Normalized_LogRR_MAPD_INFO.txt".format(self.indir, idx)):
                    continue
                sample_count += 1
                sample_info = self.sample_info(idx)
                total_reads=''
                uniq_reads=''
                coverage=''
                mapd=''
                sd=''
                if sample_info['mapd'] >= 0.15 or sample_info['sd'] >=0.15:
                    noise_count += 1
                if sample_info['total_reads'] < 2000000:
                    total_reads="<td style=\"color:#FF0000\" >"+str(format(sample_info['total_reads'], ','))
                else:
                    total_reads="<td>"+str(format(sample_info['total_reads'], ','))
                if sample_info['uniq_reads']< 1000000:
                    uniq_reads="<td style=\"color:#FF0000\" >"+str(format(sample_info['uniq_reads'], ','))
                else:
                    uniq_reads="<td>"+str(format(sample_info['uniq_reads'], ','))
                if sample_info['coverage'] < 0.04:
                    coverage="<td style=\"color:#FF0000\" >"+str(sample_info['coverage'])
                else:
                    coverage="<td>"+str(sample_info['coverage'])
                if sample_info['mapd'] >= 0.15:
                    mapd="<td style=\"color:#FF0000\" >"+str(sample_info['mapd'])
                else:
                    mapd="<td>"+str(sample_info['mapd'])
                if sample_info['sd'] >= 0.15:
                    sd="<td style=\"color:#FF0000\" >"+str(sample_info['sd'])
                else:
                    sd="<td>"+str(sample_info['sd'])
                sample_html += "<tr><td>"+self.site+"</td><td>"+self.runid+"</td><td>"+self.date+"</td><td>"+idx+"</td><td>"+sample_name+"</td>"+total_reads+"</td>"+uniq_reads+"</td><td>"+str(sample_info['uniq_rate'])+"</td><td>"+str(format(sample_info['dup_reads'], ','))+"</td><td>"+str(sample_info['dup_frac'])+"</td><td>"+str(sample_info['map_rate'])+"</td>"+coverage+"</td>"+mapd+"</td>"+sd+"</td></tr>\n"
#                sample_html += sample_format.format(self.site, self.runid, self.date, idx, sample_name, format(sample_info['total_reads'], ','), format(sample_info['uniq_reads'], ','), sample_info['uniq_rate'], format(sample_info['dup_reads'], ','), sample_info['dup_frac'], sample_info['map_rate'], sample_info['coverage'], sample_info['mapd'], sample_info['sd'])
                sql.append(sample_sql % (self.site, self.runid, self.date, idx, sample_name, sample_info['total_reads'], sample_info['uniq_reads'], sample_info['uniq_rate'], sample_info['dup_reads'], sample_info['dup_frac'], sample_info['map_rate'], sample_info['coverage'], sample_info['mapd'],sample_info['sd'], version, version, version))
        run_html += run_format.format(self.site, self.runid, self.date, sample_count, noise_count, format(run_info['reads'], ','), format(run_info['gb'], ','), run_info['length'], run_info['isp'], run_info['enrich'], run_info['clonal'], run_info['final'], run_info['empty'], run_info['noenrich'], run_info['polyclonal'], run_info['low'], run_info['instrument'])
        sql.append(run_sql % (self.site, self.runid, self.date, sample_count, noise_count, run_info['reads'], run_info['gb'], run_info['length'], run_info['isp'], run_info['enrich'], run_info['clonal'], run_info['final'], run_info['empty'], run_info['noenrich'], run_info['polyclonal'], run_info['low'], run_info['instrument']))
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
        sample_info['sd'] = float("%.4f" % self.sample_sd(idx))
        sample_info['mapd'] = float("%.4f" % self.sample_mapd(idx))
        dup_info = self.sample_dup_rate(idx)
        sample_info['uniq_reads'] = self.sample_uniq_reads(idx)
        sample_info['coverage'] = self.sample_cov(idx)
        sample_info['dup_frac'] = float("%.4f" % dup_info['dup_frac'])
        sample_info['uniq_rate'] = float("%.4f" % dup_info['uniq_rate'])
        sample_info['map_rate'] = float("%.4f" % dup_info['map_rate'])
        sample_info['total_reads'] = dup_info['total_reads']
        sample_info['dup_reads'] = dup_info['dup_reads']
        return(sample_info)

    def run_info(self):
        isp_info = self.isp_info()
        analysis_info = self.analysis_info()
        run_info = self.run_expinfo()
        run = dict()
        run['gb'] = isp_info['final']
        run['isp'] = float("%.4f" % (analysis_info['Bead Wells'] / (analysis_info['Total Wells'] - analysis_info['Excluded Wells'])))
        run['empty'] = float("%.4f" % (1 - run['isp']))
        run['enrich'] = float("%.4f" % (analysis_info['Live Beads'] / analysis_info['Bead Wells']))
        run['noenrich'] = float("%.4f" % (1 - run['enrich']))
        run['polyclonal'] = float("%.4f" % (isp_info['filtered_polyclonal'] / analysis_info['Live Beads']))
        run['clonal'] = float("%.4f" % (1 - run['polyclonal']))
        run['low'] = float("%.4f" % (isp_info['filtered_low_quality'] / (analysis_info['Live Beads'] - isp_info['filtered_polyclonal'] )))
        run['reads'] = isp_info['final_library_reads']
        run['final'] = float("%.4f" % (isp_info['final_library_reads'] / (analysis_info['Live Beads'] - isp_info['filtered_polyclonal'])))
        run['instrument'] = run_info['Instrument']
        run['length'] = float("%.4f" % (isp_info['final']/isp_info['final_library_reads']))
        return(run)

    def version_info(self):
        version_file = self.indir + "/version.txt"
        version_info = dict()
        with open(version_file, 'rt') as fh:
            for line in fh:
                key1, value1 = line.strip().split('=')
                version_info[key1] = value1
        return(version_info)

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
        ispinfo = dict()
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

    def sample_sd(self, idx):
        sd_file = self.indir+"/"+idx+"_100Kb_DNAcopy_Info_CNV_RealCNV_LogRR_Effective_MAPD_INFO.txt"
        sd = -0.001
        with open(sd_file, 'rt') as fh:
            sd = float(fh.readline().strip().split("\t")[1])
        return(sd)
        
    def sample_mapd(self, idx):
        mapd_file = self.indir+"/"+idx+"_rawlib_rmdup_MAPQ10_Fbin_GC_All_Merge_Normalized_LogRR_MAPD_INFO.txt"
        mapd = -0.001
        with open(mapd_file, 'rt') as fh:
           mapd = float(fh.readline().strip().split("\t")[1])
        return mapd

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
        return(uniq_reads)

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
        database = dbname
        if self.debug:
            database = dbname_test
        db = MySQLdb.connect(host=dbhost, user=dbuser, passwd=dbpass, db=database, charset='utf8')
        cursor = db.cursor()
        try:
            for sql in sqls:
                cursor.execute(sql)
            db.commit()
            cursor.close()
            db.close()
            self.logger("成功导入质控数据库！", 'INFO')
        except Exception as ex:
            self.logger(str(ex), 'ERROR')
            db.rollback()
            cursor.close()
            db.close()
    
    def mail_qc_report(self, html):
        mail_info = self.mail_info()
        items = 'BIOINFO'
        if self.debug:
            items = 'BIOINFO_TEST'
        sender = 'zhang109@basecare.cn'
        receivers =  mail_info[items]['to']
        carbon_copy = mail_info[items]['cc']
        subject = '【站点{}】CNV检测结果质控（测序单号：{}）'.format(self.site, self.runid)
        context = '<html><p>{}:</p><p>\t您好！</p>\n\n\t<p>以下是{}站点CNV质控结果，请查收！\n\n\t祝好！</p>\n\n\n{}</html>'.format(mail_info[items]['name'], self.site, html)
        self.mail_data(sender, receivers, carbon_copy, subject, context, 'html')
        
    def mail_data(self, sender, receivers, carbon_copy, subject, context, context_format='plain', attachment=None):
        message = MIMEMultipart()
        message['From'] = sender
        message['To'] =  receivers
        message['Cc'] =  carbon_copy
        smtpserver = '192.168.10.41'
        username = 'erp-send-user@biodiscover.com'
        password = '9L7inux~'

        message['Subject'] = Header(subject, 'utf-8')
        message.attach(MIMEText(context, context_format, 'utf-8'))
        if attachment != None:
            att1 = MIMEText(open(attachment, 'rb').read(), 'base64', 'utf-8')
            att1["Content-Type"] = 'application/multipart'
            att1["Content-Disposition"] = 'attachment; filename="{}"'.format(os.path.basename(attachment))
            message.attach(att1)
        try:
            smtp = smtplib.SMTP()
            smtp.connect(smtpserver)
            smtp.login(username, password)
            to = (receivers +','+ carbon_copy).split(",")
            smtp.sendmail(sender, to , message.as_string())
            self.logger("Sendmail Success",'INFO')
            smtp.quit()
        except smtplib.SMTPException:
            self.logger("Sendmail Failed",'ERROR')
                
    def mail_result(self):
        mail_info = self.mail_info()
        zip_file = self.archive()
        items = self.site
        if self.debug:
            items = "Test"
        sender = 'zhang109@basecare.cn'
        receivers =  mail_info[items]['to']
        carbon_copy = mail_info[items]['cc']
   
        subject = '【站点{}】CNV检测结果（测序单号：{}）'.format(self.site, self.runid)
        context = '{}:\n\t您好！\n\n\t附件是{}站点CNV检测结果，请查收！\n\n\t祝好！'.format(mail_info[self.site]['name'], self.site)
        self.mail_data(sender, receivers, carbon_copy, subject, context, attachment=zip_file)

    def logger(self, msg, loglevel):
        Date=time.strftime('%Y_%m_%d %H:%M',time.localtime(time.time()))
        print("[{}]{}: {}".format(loglevel, Date, msg))

    def archive(self):
        tmp = self.indir
        zip_dir = "{}/Result_CNV_{}_{}".format(self.indir, self.site, self.runid)
        if not os.path.isdir(zip_dir):
            os.mkdir(zip_dir)
        file_names = glob.glob("{}/*100Kb_Cytoband*.txt".format(self.indir))
        for ff in file_names:
            shutil.copy(ff, zip_dir)
        return(shutil.make_archive(zip_dir, 'zip', zip_dir))

    def mail_info(self):
        mail_info = {}
        mail_config = "{}/{}".format(self.pip_dir, "config/mail.txt")
        with open(mail_config, 'rt') as fh:
            for line in fh:
                if line.startswith("#"):
                    continue
                tmp = line.strip().split('\t')
                mail_info[tmp[0]] = {}
                mail_info[tmp[0]]['to'] = tmp[2]
                mail_info[tmp[0]]['name'] = tmp[1]
                mail_info[tmp[0]]['cc'] = tmp[3]
        return(mail_info)

    def plot1(self):
        os.system("perl "+self.pip_dir+"/Auto_DNAcopy_BreakPoints_draw.pl "+self.indir+" "+self.pip_dir+"/CHD/BreakPoints "+self.pip_dir+"/CHD/DatabaseAnn")
        chmod_for_curator(self.indir)

    def plot2(self):
        os.system("perl "+self.pip_dir+"/Auto_DNAcopy_BreakPoints_onlyDraw.pl "+self.indir+" "+self.pip_dir+"/CHD/BreakPoints "+self.pip_dir+"/CHD/DatabaseAnn")
        chmod_for_curator(self.indir)

def analysis_parse_argument(argv):
    '''
    '''
    usage = "\n\t \033[31m %prog -i xxxx -s SuZhou -p full|analysis|plot1|plot2|mail|upload|report... [-d]\033[0m"
    parser = OptionParser(usage=usage)
    parser.add_option("-i", "--input", type='string', dest='workdir', help="Work directory(run)")
    parser.add_option("-s", "--site", dest='site', type='string', help="Site Name(abbr)")
    parser.add_option("-d", "--debug", dest='debug', action="store_true", default=False, help="Debug status")
    parser.add_option("-y", "--ycm", dest='ycm', action="store_true", default=False, help="add ycm annalysis")
    parser.add_option("-p", "--pipeline", dest='pipeline', default='full', type='string', 
            help="pipeline[full|analysis|plot1|plot2|mail|upload|report]:full do 'analysis', 'upload', 'report'; plot1 do plot from effective file, plot2 do plot from annotation file")
    (options, args) = parser.parse_args(argv)
    return(options, args)

def usage():
    analysis_parse_argument(["-h"])
    sys.exit()

if __name__=="__main__":
    argv = sys.argv
    if len(argv)==1:
        usage()
    pip_dir =  os.path.dirname(os.path.abspath(sys.argv[0]))
    options, args = analysis_parse_argument(argv)
    out_dir = os.path.abspath(options.workdir)
    cmd = options.pipeline
    pipeline = Pipeline(pip_dir, out_dir, options.site,lims,lims_test,lims_ip,lims_ip_test,options.debug ,options.ycm)

    if cmd =='full':
        pipeline.analysis()
#        pipeline.plugin_report()
        pipeline.upload()
        pipeline.qc_report()

    elif cmd == 'analysis':
        pipeline.analysis()
#        pipeline.plugin_report()
        
    elif cmd == 'upload':
        pipeline.upload()

    elif cmd == 'mail':
        pipeline.mail_result()

    elif cmd == 'plot1':
        pipeline.plot1()
#        pipeline.plugin_report()

    elif cmd == 'plot2':
        pipeline.plot2()
#        pipeline.plugin_report()

    elif cmd == 'report':
        pipeline.qc_report()

    else:
        usage()
        sys.exit()
