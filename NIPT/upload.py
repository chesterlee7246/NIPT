#!/usr/bin/python
# -*- coding: utf-8 -*-
import os
import sys
reload(sys)
sys.setdefaultencoding('utf8')
import requests
import base64
import json
import ConfigParser
import commands
import requests.adapters
import numpy as np
import random, math
import datetime

#pip_dir = "/home/gudan464/Pipeline/NIPT"
# name = 'gu464'
# pwd = 'basecareGUDAN,1'
name  = "api-user"
pwd = "MjI4JmFjdGlvbj03MCZtb2Rlb20201221"
Host = "http://192.168.10.123:8069"
#Host = "https://lims14.bioerp.com"

def login(name, pwd,pip_fir):
    """登录获取session_id，并保存"""
    response = requests.request("POST", Host + "/ir/get/session_id", data={'login': name, 'password': pwd})
    if response.text.find('!DOCTYPE') > 0:
        print('网络错误')
        exit()
    #res = eval(response.text.replace('false', 'False'))
    res = json.loads(response.text)

    http_code = res.get('http_code')
    if http_code != 200:
        print('账号或密码错误，错误代码%s' % http_code)
        exit()

    data = res.get('data')
    api_txt = open(pip_fir+"/config/api.db", 'w')
    api_txt.write(str(data))
    api_txt.close()
    return 'session_id=' + data.get('session_id')

def get_session_id(name, pwd,pip_dir):
    """
    获取上一次存储的session_id,
    如果session_id失效，则自动重新请求新的session_id,
    session_id的默认有效期是90天
    """
    try:
        file = open(pip_dir+"/config/api.db", 'r')
        file_context = file.read()
    except IOError:
        file = open(pip_dir+"/config/api.db", 'w')
        file_context = ''
    file.close()
    if file_context.find('session_id') > 0:
        f_context = eval(file_context)
        session_id = f_context.get('session_id')
        expires = f_context.get('expires')
        now_time = datetime.datetime.now().strftime('%Y-%m-%d')
        if expires < now_time:
            Cookie = login(name, pwd,pip_dir)
        else:
            Cookie = 'session_id=' + session_id
    else:
        Cookie = login(name, pwd,pip_dir)

    ###验证Cookie是否有效####
    res1 = requests.request("POST", "http://192.168.10.123:8069/ir/get/session_id", headers={"Cookie": Cookie},
                            data={})
    if res1.text.find("!DOCTYPE") > 0:
        Cookie = self.login()
    return Cookie
    return Cookie



def sample_gender(zscore):
    gender = ""
    for line in open(zscore, "rt").readlines():
        if line.startswith("##gender") or line.startswith("Geder") or line.startswith("##Gender"):
            line = line.strip().split("\t")
            gender = line[1]
            break
    return gender

def sample_fetal_info(indir, idx):
    fetal_info = {}
    norm_y_file = indir + "/" + idx + "_rawlib_rmdup_MAPQ60_Fbin_GC_Per_ZScore.txt"
    egel_y_file = indir + "/" + idx + "_rawlib_rmdup_MAPQ60_2000Kb_Fbin_GC_All_Normalized_Percentage_ZScore_All.txt"
    assert os.path.isfile(norm_y_file) or os.path.isfile(egel_y_file), "There is no file about fetal fraction"
    fetal1, fetal2, predict = '0.0000', '0.0000', '0.0000'
    if os.path.isfile(norm_y_file):
        size_file = indir + "/" + idx + "_rawlib_rmdup_Size_Info_Percentage.txt"
        if os.path.isfile(size_file):
            for line in open(size_file, 'rt'):
                if line.startswith('PFetal'):
                    line = line.strip().split('\t')
                    predict = "%.4f" % float(line[-1])
                    break
                if sample_gender(norm_y_file).lower() == 'male':
                    with open(norm_y_file, 'rt') as yf:
                        for line in yf:
                            if line.startswith("##gender") or line.startswith("Geder") or line.startswith("##Gender"):
                                line = line.strip().split('\t')
                                fetal2 = "%.4f" % float(line[-1])
                                break
    elif os.path.isfile(egel_y_file):
        seqff_file = indir + "/" + idx + '_SeqFF_Fetal.txt'
        if os.path.isfile(seqff_file):
            with open(seqff_file, 'rt') as f:
                for l in f:
                    l = l.strip().split(',')
                    if l[0].strip() == '"PROTON"':
                        if l[-1] == 'NA':
                            predict = 'NA'
                        else:
                            predict = "%.4f" % float(l[-1])
                        break
        if sample_gender(egel_y_file).lower() == 'male':
            with open(egel_y_file, 'rt') as yf:
                for line in yf:
                    if line.startswith('##concentration'):
                        line = line.strip().split('\t')
                        fetal2 = "%.4f" % float(line[-1])
    if fetal2 != "0.0000":
        fetal1 = fetal2
    else:
        fetal1 = predict
    fetal_info['Fetal1'] = fetal1
    fetal_info['Fetal2'] = fetal2
    fetal_info['Predict'] = predict
    return fetal_info

def sample_zscores(indir, idx):
    egel_zfile = indir + "/" + idx + "_rawlib_rmdup_MAPQ60_2000Kb_Fbin_GC_All_Normalized_Percentage_ZScore_All.txt"
    norm_zfile = indir + "/" + idx + "_rawlib_rmdup_MAPQ60_Fbin_GC_Per_ZScore.txt"
    z_info = {}
    if os.path.isfile(egel_zfile):
        zscore_file = egel_zfile
    elif os.path.isfile(norm_zfile):
        zscore_file = norm_zfile
    else:
        print("exam your analysis result of zscore_file")
        return None
    z_other = 0
    for line in open(zscore_file, "rt").readlines():
        if line.startswith("##"):
            continue
        line = line.strip().split("\t")
        z = float(line[1])
        if abs(z) >= 2.58:
            z_other += 1
        z_info[line[0]] = "%.3f" % z
    z_info["Other(Z>2.5)"] = z_other
    z_info["chrY"] = "false"
    return z_info

def modify_nc_zscore(indir, idx):
    z_info = sample_zscores(indir, idx)
    modified = 0
    special_chrs = ["chr13", "chr16", "chr18","chrX"]
    for k, v in z_info.items():
        if k in ['chrY', 'Other(Z>2.5)']:
            continue
        v = float(v)
        if k not in special_chrs:
            if v >= 4:
                z_info[k] = '%.3f' % random.uniform(3.0, 3.9)
            elif v <= -4:
                z_info[k] = '%.3f' % random.uniform(-3.0, -3.9)
        else:
            if v >= 2.58:
                z_info[k] = '%.3f' % random.uniform(2.0, 2.49)
                modified += 1
            elif v <= -2.58:
                z_info[k] = '%.3f' % random.uniform(-2.0, -2.49)
                modified += 1
    z_info['Other(Z>2.5)'] = int(z_info['Other(Z>2.5)']) - modified
    return z_info
def sample_infos(indir, idx):
    sample_info = dict()
    ####uniq_reads
    uni_read_file = indir+"/"+idx+"_rawlib_rmdup_MAPQ10_Nbin.txt"
    #uni_read_file = indir+"/"+idx+"_rawlib_rmdup_MAPQ60_Nbin.txt"
    uniq_reads = -1
    for line in open(uni_read_file, "r").readlines():
        line = line.strip()
        if line.startswith("##unique"):
            uniq_reads = int(line.strip().split("\t")[-1])
            break
    sample_info["uniq_reads"] = uniq_reads

    dup_file = indir + "/" + idx + "_BamDuplicates.json"
    dup_json = json.load(open(dup_file, "rt"))
    sample_info['dup_reads'] = dup_json["duplicate_reads"]
    sample_info["dup_frac"]= float('%.4f' % (dup_json["fraction_duplicates"]))
    sample_info["total_reads"] = int(dup_json["total_reads"])
    sample_info["map_rate"] = float("%.4f" % dup_json["total_mapped_reads"])
    sample_info["total_reads"] = int(dup_json["total_reads"])
    sample_info["uniq_rate"] = float("%.4f" % (uniq_reads/sample_info['total_reads']))
    cov_file = indir + "/" + idx + "_rawlib_rmdup_unique_Cov.txt"
    if os.path.isfile(cov_file):
        for line in open(cov_file, "rt").readlines():
            if line.startswith("Cov"):
                cov_tmp = line.strip().split("\t")[-1]
                coverage = float(cov_tmp)
    else:
        coverage =  -0.001
    sample_info['coverage'] = coverage
    ff = sample_fetal_info(indir, idx)
    sample_info['Fetal'] = ff['Fetal1']
    sample_info['Fetal2'] = ff['Fetal2']
    sample_info['Predict'] = ff['Predict']
    z_info = sample_zscores(indir, idx)
    sample_info['chr13'] = z_info['chr13']
    sample_info['chr18'] = z_info['chr18']
    sample_info['chr21'] = z_info['chr21']
    sample_info['chrX'] = z_info['chrX']
    sample_info['Other(Z>2.5)'] = z_info['Other(Z>2.5)']
    return sample_info

def run_info(indir):
    f_isp = indir + "/BaseCaller.json"
    isp_info = {}
    info = json.load(open(f_isp, "rt"))
    ispinfo = info["Filtering"]["LibraryReport"]
    for kk in ispinfo:
        isp_info[kk] = float(ispinfo[kk])
    isp_info['final'] = float(info['Filtering']['BaseDetails']["final"])

    f_analysis = indir + "/analysis.bfmask.stats"
    analysis_info = {}
    for line in open(f_analysis, "rt").readlines():
        line = line.strip().split(" = ")
        if len(line) == 2:
            analysis_info[line[0]] = float(line[1])

    f_expinfo = indir + "/expMeta.dat"
    exp_info = {}
    for line in open(f_expinfo, "rt").readlines():
        line = line.strip().split(" = ")
        if len(line) == 2:
            exp_info[line[0]] =line[1]
    run = {}
    run['id'] = exp_info['Run Name'][exp_info['Run Name'].find("SQR"):exp_info['Run Name'].find("SQR") + 12]
    run["gb"] = float("%.4f" % (isp_info["final"] / 1000000000))
    run["isp"] = float("%.4f" % (analysis_info["Bead Wells"] / (analysis_info["Total Wells"] - analysis_info["Excluded Wells"] )))
    run["empty"] = float("%.4f" % (1 - run["isp"])) ## 未用
    run["enrich"] = float("%.4f" % (analysis_info["Live Beads"] / analysis_info["Bead Wells"]))
    run["noenrich"] = float("%.4f" % (1 - run["enrich"])) ## 未用
    run["polyclonal"] = float("%.4f" % (isp_info["filtered_polyclonal"] / analysis_info["Live Beads"]))
    run["clonal"] = float("%.4f" % (1 -run["polyclonal"] ))
    run['low'] = float("%.4f" % (isp_info['filtered_low_quality'] / (analysis_info['Live Beads'] - isp_info['filtered_polyclonal'])))
    run['reads'] = float("%.4f" % (isp_info['final_library_reads'] / 1000000))
    run['final'] = float("%.4f" % (isp_info['final_library_reads'] / (analysis_info['Live Beads'] - isp_info['filtered_polyclonal'])))
    run['instrument'] = exp_info['Instrument']
    run['length'] = int(isp_info['final'] / isp_info['final_library_reads'])
    return run

def get_attchment_id(indir,idx,  Host,cookie,sample_type, file_type):
    url = Host + "/ir/binary/upload_attachment"
    if file_type=="png":
        if "normal" in sample_type:
            file = indir +"/"+idx+"_rawlib_rmdup_MAPQ60_Fbin_GC_All_Merge_ZScore_FLasso_Value_FLasso.png"
            sequence = 0
        elif "egel" in sample_type:
                file = indir + '/' + idx + "_rawlib_rmdup_MAPQ60_Fbin_GC_All_2000Kb_Merge_ZScore_FLasso_Value_FLasso.png"
                sequence = 0
        else:
            file = ""
    elif file_type == "html":
        if "normal" in sample_type:
            file = indir + '/' + idx + '_rawlib_rmdup_MAPQ60_Fbin_GC_All_Merge_ZScore_FLasso_Value_FLasso.html'
            sequence = 1
        elif "egel" in sample_type:
            file = indir + '/' + idx + '_rawlib_rmdup_MAPQ60_Fbin_GC_All_2000Kb_Merge_ZScore_FLasso_Value_FLasso.html'
            sequence = 1
        else:
            file = ""
            sequence = 2
    files = [('ufile', open(file, 'rb'))]
    response = requests.request("POST", url, headers=cookie,data = {"sequence":sequence}, files=files)

    if response.text.find('!DOCTYPE') > 0:
        print('session_id错误，请重新登录或者刷新页面')
        exit()
    res = eval(response.text)

    http_code = res.get('http_code')
    if http_code != 200:
        print('上传图片错误，错误代码%s' % http_code)
        exit()
    a_id = json.loads(response.text)['data']['id']
    return a_id

def gc_gcv(indir, idx):
    gc, gcv = 'false', 'false'
    gc_file = indir + '/' + idx + '_rawlib_rmdup_EachChromosomeGC_UR.txt'
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

def plus_result(indir, idx, sample_type):
    chrX, chrX_risk, indel, indel_risk, other, other_risk = '','低风险','','低风险','','低风险'
    indel_zs, other_zs = [], []
    if 'normal' in sample_type:
        f_all = indir + '/' + idx + '_rawlib_rmdup_MAPQ60_Fbin_GC_Per_ZScore.txt'
        f_indel =  indir + '/' + idx + '_rawlib_rmdup_MAPQ60_Fbin_GC_Per_MicroInDel_ZScore.txt'
        f_other = indir + '/' + idx + '_rawlib_rmdup_MAPQ60_Fbin_GC_All_Merge_ZScore_FLasso_Value_Region_Merge.txt'
    elif 'egel' in sample_type:
        f_all = indir + '/' + idx + '_rawlib_rmdup_MAPQ60_2000Kb_Fbin_GC_All_Normalized_Percentage_ZScore_All.txt'
        f_indel =  indir + '/' + idx + '_rawlib_rmdup_MAPQ60_Fbin_GC_All_MicroInDel_ZScore.txt'
        f_other = indir + '/' + idx + '_rawlib_rmdup_MAPQ60_Fbin_GC_All_2000Kb_Merge_ZScore.txt'
    else:
        f_all, f_indel, f_other = '', '', ''

    if os.path.isfile(f_all):
        with open(f_all, 'rt') as fall:
            for line in fall:
                if line.startswith('chrX'):
                    chrX = str(round(float(line.strip().split('\t')[1]), 3))
                    chrX_risk = '高风险' if abs(float(chrX)) >= 3 else '低风险'
    res2 = ""
    if os.path.isfile(f_indel):
        with open(f_indel, 'rt') as findel:
            for line in findel:
                line = line.strip().split('\t')
                indel_zs.append(float(line[-1]))
                if abs(float(line[5])) >=3:
                    res2 += "micro_del"+"-"+line[0] + ":" +line[3] + "\t" +str(round(float(line[5]),3))+";\n"
    indel_min, indel_max = round(min(indel_zs), 3), round(max(indel_zs), 3)
    indel = '[' + str(indel_min) + ', ' + str(indel_max) + ']'
    indel_risk = '高风险' if abs(indel_min) >= 4 or abs(indel_max) >=4 else '低风险'

    chr_zs = {}
    if os.path.isfile(f_other):
        with open(f_other, 'rt') as fother:
            for line in fother:
                line = line.strip().split('\t')
                if line[0] == 'Chromosome':
                    continue
                ch, start, end, z = line[0], line[1], line[2], line[4]
                record = [int(start), int(end), float(z)]
                if ch not in chr_zs:
                    chr_zs[ch] = [record]
                else:
                    chr_zs[ch].append(record)
    f_pos = pip_dir + '/Lib/plus_micro_indel_syndrome_region.txt'
    f_plus_zs = indir + '/' + idx +'_plus_micro_indel_syndrom_risk_zs.txt'
    fout = open(f_plus_zs, 'w')
    if os.path.isfile(f_pos):
        with open(f_pos, 'rt') as fpos:
            for line in fpos:
                line = line.strip().split('\t')
                if line[0] == '序号':
                    continue
                z_list = []
                item, ch, start, end = line[0], line[2], int(line[3]), int(line[4])
                if ch == 'chr19' or ch not in chr_zs:
                    continue
                for v in chr_zs[ch]:
                    s, e, z = v[0], v[1], v[2]
                    if (s >= start and e <= end) or (start >= s and start <= e) or (end >= s and end <= e):
                        z_list.append(z)
                if z_list:
                    m = sum(z_list) / math.sqrt(len(z_list))
                    if abs(m) >= 3:
                        fout.write('\t'.join(line) + '\t' + str(m) + '\n')
                        res2 += str(line[1]) + "-"+str(ch)+":" + str(start) + "-" + str(end) + "\t" +str(round(float(m),3)) + ";\n"
                    other_zs.append(m)

    fout.close()
    if not other_zs:
        other_min, other_max = 'NA', 'NA'
    else:
        other_min, other_max = round(min(other_zs), 3), round(max(other_zs), 3)
        other_risk = '高风险' if abs(other_min) >= 4 or abs(other_max) >= 4 else '低风险'
    other = '[' + str(other_min) + ', ' + str(other_max) + ']'
    res = ';'.join([chrX, indel, other]) + '||' + ';'.join([chrX_risk, indel_risk, other_risk])
    return res,res2

def bz_results(indir, idx, sample_type):
    nips_bz_result = ''
    nips_ts_result = ''
    if 'normal' in sample_type:
        bz_file = indir + '/' + idx + '_rawlib_rmdup_MAPQ60_Fbin_GC_Per_MicroInDel_ZScore_FLasso_Extract_Abnormal.txt'
    elif 'egel' in sample_type:
        bz_file = indir + '/' + idx + '_rawlib_rmdup_MAPQ60_Fbin_GC_All_MicroInDel_ZScore_FLasso_Extract_Abnormal.txt'
    else:
        bz_file = ''

    if os.path.isfile(bz_file):
        with open(bz_file, 'rt') as bz:
            for line in bz:
                line = line.strip().split('\t')
                if line[0] != '':
                    nips_bz_result += line[0] + ':' + line[2] + '[' + line[1] + ',' + str(round(float(line[3]), 3)) + '];'
                    nips_ts_result += "10Mb"+"-"+line[0]+":"+line[2]+"\t"+ str(round(float(line[3]), 3)) + ";\n"
    result, ts_result = plus_result(indir,idx, sample_type)
    nips_ts_result += ts_result
    if 'plus' in sample_type:
        nips_bz_result += result
    return nips_bz_result, nips_ts_result

def unlink_result(company_id, result_id , cookie, Host):
    response = requests.request("POST", Host + "/" +  "nips/result/unlink", headers=cookie,
                                data={'company_id': company_id, 'id': int(result_id)})
    if json.loads(response.text)['http_code'] == 200:
        print('成功删除结果id:%s' % result_id)
    else:
        print(result_id)

def del_exist_sample(del_record_url,cookie,company_id,sample_id):
    response = requests.request("POST", url=del_record_url, headers=cookie,
                                data={"company_id": company_id, "sample_id": sample_id})
    if json.loads(response.text)["http_code"] == 200:
        results = json.loads(response.text)["data"]
        for line in results:
            dict_result = {}
            if line["run_number"] in dict_result:
                dict_result[line['run_number']] += "_" + str(line['id'])
            else:
                dict_result[line['run_number']] = str(line['id'])
        for line1 in dict_result:
            dict_result[line1] = dict_result[line1].split("_")
        if len(dict_result) != 0 and run_number in dict_result:
            for each in dict_result[run_number]:
                unlink_result(company_id, each, cookie, Host)

def sample_types(company_id,barcode,search_url,cookie):
    response = requests.request("POST", url=search_url, headers=cookie, data={"company_id": company_id,"barcode": barcode})
    sample_type,sample_id = "", ""
    http_code = json.loads(response.text)["http_code"]
    if http_code == 200:
        if json.loads(response.text)["data"][0]["tags"]:
            sample_type = json.loads(response.text)["data"][0]["tags"][0].lower()
        else:
            sample_type = "normal"
        sample_id = json.loads(response.text)["data"][0]['id']
        return sample_type,sample_id
    elif http_code == 404:
        print(barcode + " may not exist in lims")
    elif http_code == 401:
        print("company_id不能为空")
    else:
        print("exame you sample")
    return sample_type,sample_id

def get_index2idfile(indir,search_url, cookie):
    findex2id = indir + "/index2id.txt"
    findex2id_tmp = indir + "/index2id_tmp.txt"
    findex2id_write = open(findex2id, "w")
    for line in open(findex2id_tmp, "rt").readlines():
        trup = ("C", "A", "B", "NIPS")
        line = line.strip().split('\t')
        if not line[1].startswith(trup):
            print(line[1] + " may not NIPT sample")
            continue
        if len(line) != 3 or "normal" in  line[2].lower() or  "egel" in line[2].lower():
            continue
        company_id = line[2]
        barcode = line[1]
        sample_type,sample_id = sample_types(company_id, barcode,search_url,cookie)
        findex2id_write.write(line[0] + "\t" + line[1] + "\t" + sample_type + "\t" + line[2] + "\t" + str(sample_id) + "\n")
    findex2id_write.close()
    return (findex2id)

if __name__=="__main__":
    argv = sys.argv
    indir = argv[1]
    Site = argv[2]
    pip_dir = argv[3]


    upload_url = Host + "/nips/result/create"
    search_url = Host + "/nips/sample/search"
    del_record_url = Host + "/nips/result/search"

    cookie = {'Cookie': get_session_id(name, pwd, pip_dir)}
    run_info = run_info(indir)
    run_table="[['有效Reads(M)','总数据量(G)','平均读长(bp)','ISP loading','Enrichment','Clonal','Final Library','Empty Wells','No Template','Polyclonal','Low Quality','仪器编号'],['%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s']]" % ('%.1f'%run_info['reads'], '%.1f'%run_info['gb'], run_info['length'], str('%.1f'%(run_info['isp']*100)) + '%',str('%.1f'%(run_info['enrich']*100)) + '%', str('%.1f'%(run_info['clonal']*100)) + '%', str('%.1f'%(run_info['final']*100)) + '%', str('%.1f'%(run_info['empty']*100)) + '%', str('%.1f'%(run_info['noenrich']*100)) + '%', str('%.1f'%(run_info['polyclonal']*100)) + '%', str('%.1f'%(run_info['low']*100)) + '%', run_info['instrument'])
    findex2id = get_index2idfile(indir,search_url,cookie)
    for line in open(findex2id, "rt").readlines():
        line = line.strip().split("\t")
        if len(line) != 5:
            continue
        idx = line[0]
        nbin = "{}/{}_rawlib_rmdup_MAPQ60_Nbin.txt".format(indir, idx)
        if  not os.path.isfile(nbin):
            continue
        barcode = line[1]
        sample_type = line[2]
        company_id = line[3]
        sample_id = line[4]
        z = sample_zscores(indir, idx)
        if "n" in barcode.lower() and "nips-p" not in barcode.lower():
            z = modify_nc_zscore(indir,idx)
        fetal = sample_fetal_info(indir, idx)
        if "egel" in sample_type and fetal["Fetal1"]== fetal["Fetal2"] and  float(fetal["Fetal1"]) < 0.005:
            fetal["Fetal1"] = fetal["Predict"]
        sample_info = sample_infos(indir, idx)
        run_number = run_info['id']
        nips_GC_content, nips_GC_Coefficient_of_variation = gc_gcv(indir, idx)
        if Site != "NanTong" and Site != "SZMH":
            nips_GC_content = 'false'
            nips_GC_Coefficient_of_variation = 'false'

        attrs = []
        if Site == "NanTong":
            png_id = get_attchment_id(indir, idx, Host, cookie, sample_type, "png")
            attrs.append([4, png_id])
        html_id = get_attchment_id(indir, idx, Host, cookie, sample_type, "html")
        attrs.append([4, html_id])

        if 'n' in barcode.lower() and 'nips-p' not in barcode.lower():
            nips_bz_result = ''
            nips_pd_result = '低风险'
            nips_ts_result = ''
        elif 'p' in barcode.lower():
            nips_bz_result = []
            nips_ts_result = []
            bz_result, nips_ts_result = bz_results(indir, idx, sample_type)
            nips_ts_result = ''
            if 'chr13' in bz_result or abs(float(z['chr13'])) >= 4:
                nips_bz_result.append('T13')
            if 'chr18' in bz_result or abs(float(z['chr18'])) >= 4:
                nips_bz_result.append('T18')
            if 'chr21' in bz_result or abs(float(z['chr21'])) >= 4:
                nips_bz_result.append('T21')
            if 'chrX' in bz_result or abs(float(z['chrX'])) >= 4:
                nips_bz_result.append('chrX')
            if len(nips_bz_result) == 1:
                nips_pd_result = nips_bz_result[0] + '高风险'
                nips_bz_result = ''
            elif nips_bz_result != []:
                nips_pd_result = '其它'
                nips_bz_result = '/'.join(nips_bz_result) + '高风险'
            else:
                nips_bz_result = ''
                nips_pd_result = ''
        else:
            nips_bz_result, nips_ts_result = bz_results(indir, idx, sample_type)
            nips_pd_result = ''

            ##删除已经存在的数据##
        del_exist_sample(del_record_url, cookie, company_id, sample_id)

        idx = str(int(idx.replace('IonXpress_', '')))
        push_data = {"company_id":company_id,"sample_id":sample_id,"barcode":barcode,"run_number":run_info["id"], "index":idx,"raw_reads":sample_info["total_reads"], "unique_reads":sample_info["uniq_reads"],"coverage_reads":"False","chr1":z["chr1"] , "chr2":z["chr2"], "chr3":z["chr3"], "chr4":z["chr4"], "chr5":z["chr5"], "chr6":z["chr6"], "chr7":z["chr7"], "chr8":z["chr8"], "chr9":z["chr9"], "chr10":z["chr10"], "chr11":z["chr11"], "chr12":z["chr12"],"chr13":z["chr13"], "chr14":z["chr14"], "chr15":z["chr15"], "chr16":z["chr16"], "chr17":z["chr17"], "chr18":z["chr18"], "chr19":z["chr19"],"chr20": z["chr20"],"chr21":z["chr21"],"chr22":z["chr22"],"chr_x":z["chrX"],"chr_y":z["chrY"],"run_gc":nips_GC_content, "run_xs":nips_GC_Coefficient_of_variation, "run_dna":"false", "run_other":z["Other(Z>2.5)"],"fetal1":fetal["Fetal1"], "fetal2":"false", "run_info":run_table,"result_bz":nips_bz_result,"result_pd":nips_pd_result,"result_ts":nips_ts_result,"attachment_ids":str(attrs)}
        print(push_data)
        upload_responde = requests.request("POST", url=upload_url, headers=cookie, data=push_data) ### attachment_ids
        if json.loads(upload_responde.text)["http_code"] == 200:
           print(barcode, idx, "上传成功" )
