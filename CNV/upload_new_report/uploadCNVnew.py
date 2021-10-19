# -*- coding: utf-8 -*-

import requests
import datetime
import sys
reload(sys)
sys.setdefaultencoding('utf8')
import json
import re
import os
import base64

def get_cookie():
    '''登录获取session_id'''
    response = requests.request("POST", Host + "/ir/get/session_id", data={'login': user_name, 'password': user_pwd})
    if response.text.find('!DOCTYPE HTML PUBLIC') > 0:
        print('网络错误')
        exit()
    res = eval(response.text)
    http_code = res.get('http_code')
    if http_code != 200:
        print('账号或密码错误，错误代码%s' % http_code)
        exit()
    data = res.get('data')
    cookie = 'session_id='+data['session_id']
    return cookie

def upload_attachment(f_path, name='', description='', select='true', private='false', bd_private='false'):
    '''上传附件'''
    url = Host + '/ir/binary/upload_attachment'
    files = [('ufile', open(f_path, 'rb'))]
    response = requests.request('POST', url,headers={'Cookie': cookie}, data={'name': name, 'description': description, 'select':select, 'private':private,'bd_private':bd_private}, files=files)
    if response.text.find('!DOCTYPE HTML PUBLIC') > 0:
        print('session_id错误，请重新登录或者刷新页面')
        exit()
    res = json.loads(response.text)

    http_code = res.get('http_code')
    if http_code != 200:
        print('上传图片错误，错误代码%s' % http_code)
        exit()
    data = res.get('data')
    return data

def get_sampleid(sample_name):
    sample_name_input_split = re.search(r"(\d+)([A|N|R|B].+)",sample_name)
    barcode = sample_name_input_split.group(2)
    company_id = sample_name_input_split.group(1)
    #barcode = sample_name
    #company_id = int(sample_name.split('R')[0])
    #barcode = 'R' + sample_name.split('R')[1]
    urlsearch = Host + '/cnv/sample/search'
    sampleinfo = {'company_id': company_id, 'barcode': barcode}
    responsesampleid = requests.request('POST', url=urlsearch, headers={'Cookie': cookie}, data=sampleinfo)
    jsonsid = json.loads(responsesampleid.text)
    sampleid = jsonsid['data'][0]['id']
    return sampleid,company_id,barcode

def get_result_id(company_id,sampleid,cookie):
    response = requests.request("POST", Host +"/cnv/result/search",headers={'Cookie': cookie},data={'company_id':company_id, 'sample_id':sampleid})

    http_code=json.loads(response.text)['http_code']
    dict_result=dict()
    if http_code == 404:
        print('没有这个结果%s' % http_code)
        return dict_result
    if http_code == 401:
        print('code值不合法%s' % http_code)
        return dict_result
    if http_code == 402:
        print('company_id不能为空%s' % http_code)
        return dict_result
    if http_code == 403:
        print('搜索条件不能为空[id 或 barcode 或 chip_position]%s' % http_code)
        return dict_result
    results=json.loads(response.text)['data']
    result_ids=[]
    for line in results:
        if line['run_number'] in dict_result:
            dict_result[line['run_number']]+="_"+str(line['id'])
        else:
            dict_result[line['run_number']]=str(line['id'])
    for line1 in dict_result:
        dict_result[line1]=dict_result[line1].split("_")
    return dict_result

def unlink_result(company_id, result_id ,cookie, Host):
    response = requests.request("POST", Host +"/cnv/result/unlink",headers={'Cookie': cookie} ,data={'company_id':company_id, 'id':int(result_id)})
    if json.loads(response.text)['http_code']==200:
        print ('成功删除结果id:%s' % result_id)

def create_result(company_id,sampleid,cookie,Host):
    '''获取文件id'''
    cnvpngid = upload_attachment(cnv_png, 'Scatterplot.png', 'Scatterplot.png', 'true', 'false', 'false').get('id')
    cytpngid = upload_attachment(mosaic_png, 'CytoBand.png', 'CytoBand.png', 'true', 'false', 'false', ).get('id')

    '''新增图片'''
    dir_dr=os.path.abspath(cnv_png).rsplit("/",1)[0]
    index_number = "000"
    if len(indexinput) == 1:
        index_number = str("00" + str(indexinput))
    elif len(indexinput) == 2:
        index_number = str("0" + str(indexinput))
    elif len(indexinput) == 3:
        index_number == str(indexinput)

    cnvnewpng = dir_dr + "/IonXpress_" + index_number + "_rawlib_rmdup_MAPQ10_Fbin_GC_All_Merge_Normalized_LogRR_Extract_CNV.new.png"
    mosaicnewpng = dir_dr + "/IonXpress_" + index_number + "_rawlib_rmdup_MAPQ10_Fbin_GC_All_Merge_Normalized_LogRR_CytoBand_Mosaic_new.png"
    copynewpng = dir_dr + "/IonXpress_" + index_number + "_rawlib_rmdup_MAPQ10_Fbin_GC_All_Merge_Normalized_LogRR_Extract_CNV_ConvertValue_newXY.png"
    cnvnewpngid = upload_attachment(cnvnewpng, 'ScatterplotNew.png', 'ScatterplotNew.png', 'false', 'true', 'false').get('id')
    # cnvnewpngid = upload_attachment(cnvnewpng, 'ScatterplotNew.png', 'ScatterplotNew.png', 'true', 'false', 'false').get('id')
    copynewpngid = upload_attachment(copynewpng, 'CopyNum.png', 'CopyNum.png', 'false', 'true', 'false').get('id')
    mosaicnewpngid = upload_attachment(mosaicnewpng, 'CytoBandNew.png', 'CytoBandNew.png', 'false', 'false', 'false').get('id')

    '''新增精确散点图'''
    logrrtxt = dir_dr + "/IonXpress_" + index_number + "_rawlib_rmdup_MAPQ10_Fbin_GC_All_Merge_Normalized_LogRR_cytband.txt"
    html_file = base64.b64encode(open(logrrtxt,'rb').read())

    '''新增注释表格'''
    annotxt = dir_dr + "/IonXpress_" + index_number + "_100Kb_DNAcopy_Info_CNV_RealCNV_LogRR_Effective_Extract_Abnormal_CNV_Merge_100Kb_Cytoband_new_anno.txt"
    #result = os.popen(cmd).read()
    AnnoJsonHead = "['GRCH37', 'GRCH38', '嵌合比例', 'rlen', 'cytband', 'CNVs', 'Refseq蛋白编码基因','HI/TS', 'ACMG功能缺失基因数', 'ClinGen致病性CNV数', 'DECIPHER致病性CNV数', 'DECIPHER综合征数','本地CNV频率']"
    AnnoJsonBody = ""
    AnnoJsonBodytext = ""
    numlines = 0
    if os.path.exists(annotxt):
        AnnoData = open(annotxt, "r")
        AnnoDataLines = AnnoData.readline()
        while AnnoDataLines:
            AnnoDataL = AnnoDataLines.split('\t')
            AnnoJsonBodyLines = ''
            AnnoJsonBodyLinestext = ''
            if AnnoDataL[0] != 'ID':
                numlines = numlines +1
                Chrom   = AnnoDataL[1]
                Start   = AnnoDataL[2]
                End     = AnnoDataL[3]
                GRCH37Location = Chrom + ":" + Start + "-" + End
                GRCH38Location = '-'
                '''坐标转换'''
                GRCH37ToGRCH38bedInput = dir_dr + "/IonXpress_" + index_number + "_GRCH37ToGRCH38bedinput.bed"
                GRCH37ToGRCH38bedOutput = dir_dr + "/IonXpress_" + index_number + "_GRCH37ToGRCH38bedOutput.bed"
                GRCH37ToGRCH38bedOutputnone = dir_dr + "/IonXpress_" + index_number + "_GRCH37ToGRCH38bedOutputnone.bed"
                bedfile = open(GRCH37ToGRCH38bedInput,"w")
                bedtext = Chrom + '\t' + Start + '\t' + End
                bedfile.write(bedtext)
                bedfile.close()
                turnbedcmd = "/home/bioinfo/local/bin/liftOver "+GRCH37ToGRCH38bedInput+" /home/bioinfo/database/hg19/hg19_ucsc/hg19ToHg38.over.chain.gz "+GRCH37ToGRCH38bedOutput + " " +GRCH37ToGRCH38bedOutputnone
                print turnbedcmd
                os.system(turnbedcmd)
                bedsize = os.path.getsize(GRCH37ToGRCH38bedOutput)
                if bedsize != 0:
                    bedfile = open(GRCH37ToGRCH38bedOutput,"r")
                    bedfileLines = bedfile.readline()
                    while bedfileLines:
                        bedfileL = bedfileLines.split('\t')
                        GRCH38Location = bedfileL[0] + ":" + bedfileL[1] + "-" + bedfileL[2].strip()
                        print GRCH38Location
                        bedfileLines = bedfile.readline()
                    bedfile.close()
                ''' 计算嵌合比例'''
                mosaiccmd = "mosaic " + AnnoDataL[4]
                mosaic = os.popen(mosaiccmd).read().split(" ")[3].split("\n")[0]
                if float(mosaic.split('%')[0]) >= 80:mosaic = '100%(' + mosaic + ')'
                rlen    = str(int(AnnoDataL[5])/1000) + "Kb"
                cytband = AnnoDataL[6]
                cnvres  = AnnoDataL[7].replace(")X", ")×"); # 转换乘号
                containcodegene = AnnoDataL[8].split('_') # 包含的蛋白编码基因
                CCGeneNum = containcodegene[0] # 包含的蛋白编码基因数量
                CCGeneName = '-'
                if len(containcodegene) > 1:
                    CCGeneNameS = containcodegene[1].split('|') # 包含的蛋白编码基因
                    if len(CCGeneNameS) == 1:
                        CCGeneName = CCGeneNameS[0]
                    elif len(CCGeneNameS) == 2:
                        CCGeneName = CCGeneNameS[0] + "," + CCGeneNameS[1]
                    elif len(CCGeneNameS) >= 3:
                        CCGeneName = CCGeneNameS[0] + "," + CCGeneNameS[1] + "," + CCGeneNameS[2]
                CCGeneNum = CCGeneNum + ":" + CCGeneName

                HapTrigene = '0_' # 包含单倍/三倍基因
                HapTrigeneS = '0_' # 补充涉及单倍/三倍基因
                if float(AnnoDataL[4]) < 0:
                    HapTrigene = AnnoDataL[14].split('_') # 包含单倍剂量不足基因
                    HapTrigeneS = AnnoDataL[15].split('_') # 涉及单倍剂量不足基因
                elif float(AnnoDataL[4]) >= 0:
                    HapTrigene = AnnoDataL[16].split('_') # 包含三倍剂量敏感基因
                    HapTrigeneS = AnnoDataL[17].split('_') # 涉及三倍剂量敏感基因
                HTGeneNum = str(int(HapTrigene[0]) + int(HapTrigeneS[0])) # 涉及三倍/单倍基因数量
                HTGeneName = '-'
                if len(HapTrigeneS) > 1:
                    HTGeneNameS = HapTrigeneS[1].split('|') # 涉及的三倍/单倍基因
                    if len(HTGeneNameS) >= 1:
                        HTGeneName = HTGeneNameS[0]
                if len(HapTrigene) > 1:
                    HTGeneNameS = HapTrigene[1].split('|') # 包含的三倍/单倍基因
                    if len(HTGeneNameS) >= 1:
                        HTGeneName = HTGeneNameS[0]
                HTGeneNum = HTGeneNum + ":" + HTGeneName

                ACMGLOFGeneNum = str(int(AnnoDataL[19].split('_')[0]) + int(AnnoDataL[18].split('_')[0])) # 涉及的ACMG功能缺失基因数量
                DGVGeneNum = AnnoDataL[21].split('_')[0] # 涉及的DGV freq>1%的CNV数_CNV
                ClinGeneNum = AnnoDataL[22].split('_')[0] # 涉及的ClinGen致病性CNV数
                DeciGeneNum = AnnoDataL[23].split('_')[0] # 涉及的DECIPHER致病性CNV总数
                DeciGeneNumS = AnnoDataL[29].split('_')[0] # 涉及的DECIPHER综合征数
                DeciGeneNumP = AnnoDataL[30].split("|")[0].rsplit("_",1)[0] # 涉及的DECIPHER综合征位置_名称_表型
                Frequency = str(AnnoDataL[-1].strip())
                if len(str(AnnoDataL[7]))>16 and 'mosaic' not in str(AnnoDataL[7]) and len(Frequency)<20:
                    LimisFrequency = Frequency  # 本地CNV数据库的频率
                else:
                    LimisFrequency = '-'

                if 'chr' in DeciGeneNumP.lower():
                    DeciGeneNumS = DeciGeneNumS + ":" + DeciGeneNumP
                AnnoJsonBodyLinestext = "'" + GRCH37Location + "', '" + GRCH38Location + "', '" + mosaic + "', '" + rlen + "', '" + cytband + "', '" + cnvres + "', '" + CCGeneNum + "', '" + HTGeneNum + "', '" + ACMGLOFGeneNum + "', '" + ClinGeneNum + "', '" + DeciGeneNum + "', '" + DeciGeneNumS + "', '" + LimisFrequency + "'"
                AnnoJsonBodyLines = "[%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s]"
                if AnnoJsonBody == "":
                    AnnoJsonBody = AnnoJsonBodyLines
                    AnnoJsonBodytext = "[" + AnnoJsonBodyLinestext + "]"
                else:
                    AnnoJsonBody = AnnoJsonBody + "," + AnnoJsonBodyLines
                    AnnoJsonBodytext = AnnoJsonBodytext + ",[" + AnnoJsonBodyLinestext + "]"
            AnnoDataLines = AnnoData.readline()
        AnnoData.close()
    if (os.path.getsize(annotxt) == 0) or (not os.path.exists(annotxt)) or (numlines == 0):
        AnnoJsonBodyLines = "['%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s']"
        AnnoJsonBodytext = "['-', '-', '-', '-', '-', '-', '-', '-', '-', '-', '-', '-', '-']"
    #AnnoJson = '[' + AnnoJsonHead + "," + AnnoJsonBody + '] %(' + AnnoJsonBodytext + ')'
    AnnoJson = '[' + AnnoJsonHead + "," + AnnoJsonBodytext + ']'
    #print AnnoJson

    '''数据量不足判断'''
    if float(raw_reads)<1900000:
        result_readings = '重测序'
        result_notes = ''
        result_desc00 = ''
        result_note0 = 'reads数不足'
    else:
        result_readings = result_reading
        result_notes = result_note
        result_desc00 = result_desc0
        result_note0 = ''

    '''新增结果说明'''
    results0 = '/home/jinzhujia582/upload_project/CNV/CHD/DatabaseAnn/Results_des.txt'
    if os.path.exists(results0):
        results_des0 = open(results0,'r').readlines()[1:]
        result0 = []
        results_des = {}
        for re0 in results_des0:
            re = re0.strip().split('\t')
            result0.append(re[0])
            results_des[re[0]] = re
        result_reading0 = result_readings.split(';')
        if len(result_reading0)==1 and str(result_reading0[0]) in result0 and str(result_reading0[0]) != '重测序':
            result = result_reading0[0]
            result_desc = results_des[result][1]
            manifestation = results_des[result][2]
            advice = results_des[result][3]
        else:
            result,result_desc,manifestation,advice = ['']*4

    result_reading0 = ';'.join(result_reading0)
    url = Host + '/cnv/result/create'
    payload = {'sample_id': sampleid,'company_id': company_id,'run_number':run_number,'index':indexinput,'raw_reads':raw_reads,'unique_reads':unique_reads,
               'coverage_reads':coverage,'variant_name':result_reading0,'fragment_size':result_notes,'variant_type':result_desc00,'note_text':result_note0,
               'result':result,'result_desc':result_desc,'manifestation':manifestation,'advice':advice,'run_info':run_table,'barcode':barcode,'csv_file1':html_file,
               'select':'true','is_buc':'false','attachment_ids': str([(4, cnvpngid), (4, cytpngid), (4, mosaicnewpngid), (4, cnvnewpngid), (4, copynewpngid)]),'data5':AnnoJson}
    # url = Host + '/cnv/result/write'
    # payload = {'company_id': company_id,'id': result_id,'run_number':run_number,'index':indexinput,'raw_reads':raw_reads,'unique_reads':unique_reads,'coverage_reads':coverage,'variant_name':result_reading0,'fragment_size':result_notes,'variant_type':result_desc00,'note_text':result_note0,'result':result,'result_desc':result_desc,'manifestation':manifestation,'advice':advice,'run_info':run_table,'barcode':barcode,'select':'true','is_buc':'false','attachment_ids': str([(4, cnvpngid), (4, cytpngid)]),'data5':AnnoJson}
    response = requests.request('POST', url, headers={'Cookie': cookie}, data=payload)
    if response.text.find('!DOCTYPE HTML PUBLIC') > 0:
        print('session_id错误，请重新登录或者刷新页面')
        exit()
    res = json.loads(response.text)

    http_code = res.get('http_code')
    if http_code != 200:
        print('上传结果错误，错误代码%s' % http_code)
        exit()

    jsontext = json.loads(response.text)
    print jsontext['message']

    '''判断YCM'''
    if chr_Y=="True":
        chr_y_name0=sys.argv[25]
        chr_y_size0=sys.argv[26]
        chr_y_desc0=sys.argv[27]
        chr_y_png=sys.argv[28]
        if float(raw_reads)<1900000:
            chry_name='重测序'
            chr_y_size=''
            chr_y_desc=''
            chr_y_note='reads数不足'
        else:
            chry_name=chr_y_name0
            chr_y_size=chr_y_size0
            chr_y_desc=chr_y_desc0
            chr_y_note=''

        '''新增结果说明'''
        results1 = '/home/jinzhujia582/upload_project/CNV/CHD/DatabaseAnn/Results_YCM.txt'
        if os.path.exists(results1):
            results_des1 = open(results1,'r').readlines()[1:]
            result1 = []
            results_dess = {}
            for re1 in results_des1:
                ree = re1.strip().split('\t')
                result1.append(ree[0])
                results_dess[ree[0]] = ree
            result_reading1 = chry_name.split(';')
            if len(result_reading1)==1 and str(result_reading1[0]) in result1 and chry_name!='重测序':
                result_chry = results_dess[result_reading1[0]]
                chr_y_name,contain_gene,pathogenic,chr_y_result = result_chry[1:5]
                chr_y_desc0,chr_y_manifestation,chr_y_advice,chr_y_refer0 = result_chry[5:9]
                chr_y_refer = '\n'.join(chr_y_refer0.split(';'))
            else:
                chr_y_name = chry_name
                contain_gene,pathogenic,chr_y_result,chr_y_desc0=['']*4
                chr_y_manifestation,chr_y_advice,chr_y_refer=['']*3

        ycmpngid = upload_attachment(chr_y_png, 'YCM.png', 'YCM.png', 'true', 'false', 'false').get('id')

        payload = {'sample_id': sampleid, 'company_id': company_id,'run_number':run_number,'index':indexinput,'raw_reads':raw_reads,'unique_reads':unique_reads,'coverage_reads':coverage,'variant_name':chr_y_name,'fragment_size':chr_y_size,'variant_type':chr_y_desc,'note_text':chr_y_note,'containing_gene':contain_gene,'pathogenic_analysis':pathogenic,'result':chr_y_result,'result_desc':chr_y_desc0,'manifestation':chr_y_manifestation,'advice':chr_y_advice,'references_text':chr_y_refer,'run_info':run_table,'barcode':barcode,'select':'false','is_buc':'true','attachment_ids': str([(4, ycmpngid)])}
        # payload = {'id': result_id, 'company_id': company_id,'run_number':run_number,'index':indexinput,'raw_reads':raw_reads,'unique_reads':unique_reads,'coverage_reads':coverage,'variant_name':chr_y_name,'fragment_size':chr_y_size,'variant_type':chr_y_desc,'note_text':chr_y_note,'containing_gene':contain_gene,'pathogenic_analysis':pathogenic,'result':chr_y_result,'result_desc':chr_y_desc0,'manifestation':chr_y_manifestation,'advice':chr_y_advice,'references_text':chr_y_refer,'run_info':run_table,'barcode':barcode,'select':'false','is_buc':'true','attachment_ids': str([(4, ycmpngid)])}
        response = requests.request('POST', url, headers={'Cookie': cookie}, data=payload)
        if response.text.find('!DOCTYPE HTML PUBLIC') > 0:
            print('session_id错误，请重新登录或者刷新页面')
            exit()
        res = json.loads(response.text)

        http_code = res.get('http_code')
        if http_code != 200:
            print('上传结果错误，错误代码%s' % http_code)
            exit()

        jsontext = json.loads(response.text)
        print jsontext['message']


if __name__=="__main__":

    '''接收结果参数'''
    sample_name = sys.argv[1]
    run_number=sys.argv[14]
    indexinput=str(sys.argv[15])
    raw_reads=sys.argv[16]
    unique_reads=sys.argv[17]
    coverage=sys.argv[18]
    result_reading=sys.argv[19]
    result_note=sys.argv[20]
    result_desc0=sys.argv[21]
    cnv_png=sys.argv[22]
    mosaic_png=sys.argv[23]
    chr_Y=sys.argv[24]
    run_table="[['有效Reads(M)','总数据量(G)','平均读长(bp)','ISP loading','Enrichment','Clonal','Final Library','Empty Wells','No Template','Polyclonal','Low Quality','测序仪编号'],['%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s']]" %(sys.argv[2],sys.argv[3],sys.argv[4],sys.argv[5],sys.argv[6],sys.argv[7],sys.argv[8],sys.argv[9],sys.argv[10],sys.argv[11],sys.argv[12],sys.argv[13])

    Host = 'http://192.168.10.123:8069'
    user_name = 'api-user'
    user_pwd = 'MjI4JmFjdGlvbj03MCZtb2Rlb20201221'
    cookie = get_cookie()

    '''获取公司ID和样本ID'''
    sampleid = int(get_sampleid(sample_name)[0])
    company_id = int(get_sampleid(sample_name)[1])
    barcode = get_sampleid(sample_name)[2]

    '''判断是否已存在结果，存在则先进行删除'''
    result_ids=get_result_id(company_id,sampleid,cookie)
    if len(result_ids) != 0 and run_number in result_ids:
        for each in result_ids[run_number]:
            unlink_result(company_id,each,cookie,Host)
            # result_id = each

    '''创建结果'''
    create_result(company_id,sampleid,cookie,Host)
    # create_result(company_id,result_id,cookie,Host)

