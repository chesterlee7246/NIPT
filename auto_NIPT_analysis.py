#!/bin/python
import os
import sys
import re
import time
import json

def logger(msg, loglevel='INFO'):
    Date=time.strftime('%Y_%m_%d %H:%M',time.localtime(time.time()))
    print("[{}]{}: {}".format(loglevel, Date, msg))

def origin_data(data_dir):
    origin_data_d=dict()
    data_file=data_dir+"/files.txt"
    dataf=open(data_file,'r')
    for line in dataf:
        line=line.strip()
        arr=line.split("\t")
        if arr[1]=='0':
            origin_data_d[arr[0]]=1
    return origin_data_d

def find_data(data_dir,data_d):
    for line in os.listdir(data_dir):
        if re.search("tn",line):
            continue
        else:
            if line in data_d:
                continue
            else:
                return line
    return "No new data" 

def read_conf(config_file):
    site_dict=json.load(open(config_file,'r'))
    return site_dict["site_dict"]

def rec_site(data,config_file):
    if data=="No new data":
        return "No new data"
    else:
        site_d=read_conf(config_file)
        for each in site_d:
            if re.search(each,data):
                return [site_d[each],data]
    return "No new data"

def analysis(analysis_dir,data,data_dir,pip_dir,config_file):
    if rec_site(data,config_file) == "No new data":
        return "No new data"
    else:
        [site,data_zip]=rec_site(data,config_file)
        site_dir=analysis_dir+"/"+site
        if os.path.isfile(site_dir+"/"+data_zip):
            return "Has analyzed!"
        else:
            os.system('cp '+data_dir+"/"+data_zip+" "+site_dir)
            result_dir=site_dir+"/"+data_zip.replace(".zip","")
            os.system("unzip "+ data_dir+"/"+data_zip +" -d "+ result_dir)
            os.system("chmod -R 775 " + result_dir)
            sbatch_file=result_dir+"/"+site+"_nipt_analysis.sh"
            R_time=time.strftime('%H%M%S',time.localtime(time.time()))
            sbatch = open(sbatch_file, 'w')
            sbatch.write("#!/bin/sh\n")
            sbatch.write("#SBATCH -J " + site + "_nipt_" + R_time + "\n")
            sbatch.write("#SBATCH -e " + result_dir + "/nipt_analysis.err" + "\n")
            sbatch.write("#SBATCH -o " + result_dir + "/nipt_analysis.out" + "\n")
            sbatch.write("#SBATCH --partition=cu2\n")
            sbatch.write("#SBATCH -N 1 \n")
            sbatch.write("#SBATCH --cpus-per-task 12\n")
            sbatch.write("source /home/bioinfo/software/environment.vne.latest\n")
            sbatch.write("python " + pip_dir + "/NIPT.py -i " + result_dir + " -s " + site + " -p  full" + "\n")
            sbatch.close()
            os.system("sbatch "+sbatch_file)
            return sbatch_file
        
if __name__=='__main__':
    if len(sys.argv) != 5:
        print "\nUsage: python "+sys.argv[0]+" data_dir<'/home/biodata/sites/pluginsData'> pip_dir</home/xxxx/NIPT_dev_pip> analysis_dir<'/home/biodata/analysis/NIPT'> config_file</home/xxxx/NIPT_dev_pip/config/site_dict.json>\n"
        sys.exit("check your input")
    data_dir=sys.argv[1]
    pip_dir=sys.argv[2]
    analysis_dir=sys.argv[3]
    config_file=sys.argv[4]
    data_d=dict()
    data_d=origin_data(data_dir)    
    while True:
        try:
            analysis(analysis_dir,find_data(data_dir,data_d),data_dir,pip_dir,config_file)
        except Exception as e:
            logger(str(e), 'ERROR')
        logger(find_data(data_dir,data_d))
        if find_data(data_dir,data_d) != "No new data":
            data_d[find_data(data_dir,data_d)]=1
        time.sleep(60*4)
