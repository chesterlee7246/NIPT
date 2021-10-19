#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import sys
reload(sys)
sys.setdefaultencoding('utf8')
import sys
import requests
import base64
import json
import ConfigParser
import commands
import requests.adapters
#png1 = 'http://gy2.basecare.cn/lims/lab/test/add'
png2 = 'http://192.168.10.195:8069/lims/sample/result/add'
#png2 = 'https://lims.basecare.cn/lims/sample/result/add'
sample_name = sys.argv[1]
run_number=sys.argv[14]
index=sys.argv[15]
raw_reads=sys.argv[16]
unique_reads=sys.argv[17]
coverage=sys.argv[18]
result_reading=sys.argv[19]
result_note=sys.argv[20]
result_desc=sys.argv[21]
#pgs_mit_ratio=sys.argv[22]
#pgs_mapd=sys.argv[10]
#pgs_sd=sys.argv[11]
#pgs_logrr=sys.argv[12]
cnv_png=sys.argv[22]
mosaic_png=sys.argv[23]
chr_Y=sys.argv[24]
appendix=sys.argv[25]
#requests.adapters.DEFAULT_RETRIES = 5
(status,mosaic_png_base64)=commands.getstatusoutput("base64 -w 0 "+cnv_png)
#print status
(status,cnv_png_base64)=commands.getstatusoutput("base64 -w 0 "+mosaic_png)
#print cnv_png_base64

run_table="[['有效Reads(M)','总数据量(G)','平均读长(bp)','ISP loading','Enrichment','Clonal','Final Library','Empty Wells','No Template','Polyclonal','Low Quality','测序仪编号'],['%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s']]" %(sys.argv[2],sys.argv[3],sys.argv[4],sys.argv[5],sys.argv[6],sys.argv[7],sys.argv[8],sys.argv[9],sys.argv[10],sys.argv[11],sys.argv[12],sys.argv[13])

url="http://192.168.10.195:8069/lims/sample/"+sample_name+"/get/result"
a=requests.get(url).text
info_d=json.loads(a)
run_list=info_d["data"]["run_number_list"]

if len(run_list) == 0 or (len(run_list) == 1 and run_number in run_list):
    if chr_Y=="True":
        chr_y_name=sys.argv[25]
        chr_y_size=sys.argv[26]
        chr_y_desc=sys.argv[27]
        chr_y_png=sys.argv[28]
        (status,chr_y_png_base64)=commands.getstatusoutput("base64 -w 0 "+chr_y_png)
        pushdata={"is_new":1,"is_delete_old":1,"attr_line_is_delete_old":1,"upload_project":"cnv","select":True,"is_buc": False,"run_number":run_number,"index":index,"raw_reads":raw_reads,"unique_reads":unique_reads,"coverage_reads":coverage,"cnv_variant_name":result_reading,"cnv_fragment_size":result_note,"cnv_variant_type":result_desc,"run_info":run_table,"attr_line":str([ (0, 0, {'select':True,'datas_fname':'CytoBand.png','datas':mosaic_png_base64,'type':'binary','name':'CytoBand.png','description':'CytoBand.png'}),(0,0,{'select':True,'name':'Scatterplot.png','datas_fname':'Scatterplot.png','datas':cnv_png_base64,'type':'binary','description':'Scatterplot.png'})]),"barcode":sample_name,"cnv_appendix_text":appendix}
        pushout = requests.post(url = png2, data = pushdata)
        pushdata={"is_new":1,"is_delete_old":0,"attr_line_is_delete_old":0,"upload_project":"ycm","select":False,"is_buc": True,"run_number":run_number,"index":index,"raw_reads":raw_reads,"unique_reads":unique_reads,"coverage_reads":coverage,"cnv_variant_name":chr_y_name,"cnv_fragment_size":chr_y_size,"cnv_variant_type":chr_y_desc,"run_info":run_table,"attr_line":str([ (0, 0, {'select':True,'datas_fname':'YCM.png','datas':chr_y_png_base64,'type':'binary','name':'YCM.png','description':'YCM.png'})]),"barcode":sample_name}
        pushout = requests.post(url = png2, data = pushdata)
    else:
        pushdata={"is_new":1,"is_delete_old":1,"attr_line_is_delete_old":1,"upload_project":"cnv","select":True,"is_buc": False,"run_number":run_number,"index":index,"raw_reads":raw_reads,"unique_reads":unique_reads,"coverage_reads":coverage,"cnv_variant_name":result_reading,"cnv_fragment_size":result_note,"cnv_variant_type":result_desc,"run_info":run_table,"attr_line":str([ (0, 0, {'select':True,'datas_fname':'CytoBand.png','datas':mosaic_png_base64,'type':'binary','name':'CytoBand.png','description':'CytoBand.png'}),(0,0,{'select':True,'name':'Scatterplot.png','datas_fname':'Scatterplot.png','datas':cnv_png_base64,'type':'binary','description':'Scatterplot.png'})]),"barcode":sample_name,"cnv_appendix_text":appendix}
        pushout = requests.post(url = png2, data = pushdata)

#print pushout.text
    json1 = json.loads(pushout.text)
#print json1['http_code']
    print json1['message']
else:
    if chr_Y=="True":
        chr_y_name=sys.argv[25]
        chr_y_size=sys.argv[26]
        chr_y_desc=sys.argv[27]
        chr_y_png=sys.argv[28]
        (status,chr_y_png_base64)=commands.getstatusoutput("base64 -w 0 "+chr_y_png)
        pushdata={"is_new":1,"is_delete_old":0,"attr_line_is_delete_old":0,"upload_project":"cnv","select":True,"is_buc": False,"run_number":run_number,"index":index,"raw_reads":raw_reads,"unique_reads":unique_reads,"coverage_reads":coverage,"cnv_variant_name":result_reading,"cnv_fragment_size":result_note,"cnv_variant_type":result_desc,"run_info":run_table,"attr_line":str([ (0, 0, {'select':True,'datas_fname':'CytoBand.png','datas':mosaic_png_base64,'type':'binary','name':'CytoBand.png','description':'CytoBand.png'}),(0,0,{'select':True,'name':'Scatterplot.png','datas_fname':'Scatterplot.png','datas':cnv_png_base64,'type':'binary','description':'Scatterplot.png'})]),"barcode":sample_name}
        pushout = requests.post(url = png2, data = pushdata)
        pushdata={"is_new":1,"is_delete_old":0,"attr_line_is_delete_old":0,"upload_project":"ycm","select":False,"is_buc": True,"run_number":run_number,"index":index,"raw_reads":raw_reads,"unique_reads":unique_reads,"coverage_reads":coverage,"cnv_variant_name":chr_y_name,"cnv_fragment_size":chr_y_size,"cnv_variant_type":chr_y_desc,"run_info":run_table,"attr_line":str([ (0, 0, {'select':True,'datas_fname':'YCM.png','datas':chr_y_png_base64,'type':'binary','name':'YCM.png','description':'YCM.png'})]),"barcode":sample_name}
        pushout = requests.post(url = png2, data = pushdata)
    else:
        pushdata={"is_new":1,"is_delete_old":0,"attr_line_is_delete_old":0,"upload_project":"cnv","select":True,"is_buc": False,"run_number":run_number,"index":index,"raw_reads":raw_reads,"unique_reads":unique_reads,"coverage_reads":coverage,"cnv_variant_name":result_reading,"cnv_fragment_size":result_note,"cnv_variant_type":result_desc,"run_info":run_table,"attr_line":str([ (0, 0, {'select':True,'datas_fname':'CytoBand.png','datas':mosaic_png_base64,'type':'binary','name':'CytoBand.png','description':'CytoBand.png'}),(0,0,{'select':True,'name':'Scatterplot.png','datas_fname':'Scatterplot.png','datas':cnv_png_base64,'type':'binary','description':'Scatterplot.png'})]),"barcode":sample_name}
        pushout = requests.post(url = png2, data = pushdata)
    json1 = json.loads(pushout.text)
    print json1['message']
#"attr_line":[(0,0{'select':Ture,'datas_fname':'test.png','datas':'','type':'binary','name':'test_png','description':'xxxx'})],
