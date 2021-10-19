#!/usr/bin/python
#-*- coding: UTF-8 -*- 
import requests,datetime,re,json,ast,os,shutil,sys

if len(sys.argv) != 4:
	print "\nUSAGE: python "+sys.argv[0]+" ion_params_00.json index2id.txt wkdir\n"
	sys.exit(1)

sites_id = {
			"SuZhou":'3',
			"GYSY":'4',
			"JiaYin":'5',
			"BJBK":'7',
			"XiangYa":'9',
			"LinYi":'10',
			"ShengJing":'15',
			"JNYY":'22',
			"YanFa":'27',
			"SCSD":'39',
			"SYTH":'42'
			}

# Host = 'https://lims21.bioerp.com/'
Host = 'http://192.168.10.123:8069'
user_name = 'api-user'
user_pwd = 'MjI4JmFjdGlvbj03MCZtb2Rlb20201221'

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

def get_http_code(company_id, barcode):
	urlsearch = Host + '/cnv/sample/search'
	sampleinfo = {'company_id':company_id,'barcode':barcode}
	responsesampleid = requests.request('POST', url=urlsearch, headers={'Cookie': get_cookie()}, data=sampleinfo)
	response = json.loads(responsesampleid.text)
	# response = json.loads((responsesampleid.text).replace("'","\""))
	# http_code = response['http_code']
	return response

index2id = open(sys.argv[2],'w')
outdir = sys.argv[3]
site = outdir.split('/')[5]   ##  站点
company_id = sites_id[site]	##	站点编号
other_path = outdir+"/other_sample"
ycm_path = outdir+"/ZYCM"
if not os.path.exists(other_path):
	os.mkdir(other_path)
if not os.path.exists(ycm_path):
	os.mkdir(ycm_path)

index2id_bak = open(outdir+'/index2id_bak.txt','w')
index2id_ycm = open(ycm_path+'/index2id.txt','w')

##  提取本地样本信息
stats0=json.load(open(sys.argv[1]))
stats1=stats0['experimentAnalysisSettings']['barcodedSamples']
stats = {}
index2ids0 = {}
index2id_ycms0 = {}

##	unicode转化成字典
if isinstance(stats1, dict):
	stats=stats1
else:
	stats=json.loads(stats1)

## 根据本地样本信息，去limis系统里提取数据
for sampleid in stats:
	barcode = stats[sampleid]["barcodeSampleInfo"]
	index = list(barcode.keys())[0]
	index_id = ''.join(re.findall(r'\d+',index))
	first = list(sampleid)[0]
	if first.isalpha()==True:
		sampleid0 = str(company_id)+str(sampleid)
		sample_id = sampleid
	else:
		chr0 = re.findall(r'(\D+)',sampleid)[0]
		chr1 = sampleid.split(chr0)  
		sampleid0 = sampleid
		sample_id = chr0+chr1[1]
	externalid = barcode[index]['externalId']
	if site == 'JiaYin':
		external_id = externalid
	else:
		external_id = sample_id

	##  通过API从limis系统里提取样本信息
	http_code = get_http_code(company_id, sample_id)
	index_y = [index,sampleid0,external_id,'Y']
	index_null = [index,sampleid0,external_id,'null']
	if http_code['http_code'] == 200:
		if sites_id[site] == str(company_id):
			tag = http_code['data'][0]['tags']
			#	佳音/苏州/临沂主目录保留YCM的bed文件
			if site in ['JiaYin']:
				if 'YCM' in tag:
					index_info = index_y
				else:
					index_info = index_null
					index2id_ycms0['\t'.join(index_y)] = int(index_id)
					os.system('mv '+outdir+"/"+index+'_rawlib_CYM.bed '+ycm_path)
			#	本部和临沂不保留含Y的YCM文件
			elif site in ['SuZhou','LinYi']:
				if 'YCM' in tag:
					index_info = index_y
				else:
					index2id_ycms0['\t'.join(index_y)] = int(index_id)
					os.system('mv '+outdir+"/"+index+'_rawlib_CYM.bed '+ycm_path)
					if 'Y' in tag and 'YCM' not in tag:
						index_info = index_y
					else:
						index_info = index_null
				#	其它站点不保留所有的YCM数据
			else:
				index2id_ycms0['\t'.join(index_y)] = int(index_id)
				os.system('mv '+outdir+"/"+index+'_rawlib_CYM.bed '+ycm_path)
				if 'Y' in tag:
					index_info = index_y
				else:
					index_info = index_null			
			index2ids0['\t'.join(index_info)] = int(index_id)
		#	站点编号不对，迁移数据至other文件夹
		else:
			os.system('mv '+outdir+"/"+index+'* '+other_path)
	##	无法获取数据，收集可能样本名错误样本
	else:
		if sites_id[site] == str(company_id):
			if 'R' in sample_id:
				index2ids0['\t'.join(index_y)] = int(index_id)
			else:
				os.system('mv '+outdir+"/"+index+'* '+other_path)
		else:
			os.system('mv '+outdir+"/"+index+'* '+other_path)

##  构建分析用索引文件
index2ids = sorted(index2ids0.items(),key = lambda x:x[1])
for index2id0 in index2ids:
	index2id.write(index2id0[0]+'\n')
	index2id_bak.write(index2id0[0]+'\n')
index2id.close()
index2id_bak.close()

##  构建分析含YCM标签的索引文件
index2id_ycms = sorted(index2id_ycms0.items(),key = lambda x:x[1])
for index2id_ycm0 in index2id_ycms:
	index2id_ycm.write(index2id_ycm0[0]+'\n')
index2id_ycm.close()

##  分析错误样本名以及YCM
plugin0 = sys.argv[0].split('/')
plugin = '/'.join(plugin0[0:6])
##	plugin结果为'/home/jinzhujia582/upload_project/CNV/CHD'

if len(index2id_ycms0)>0:
	os.system("nohup perl "+plugin+"/YCM/get_YCM.pl "+ycm_path+" > "+ycm_path+"/nohup.out 2>&1 &")
	os.system("nohup bash "+plugin+"/YCM/YCM/scripts/batch_YCM.sh "+ycm_path+" "+ycm_path+" > "+ycm_path+"/nohup.out 2>&1 &")
if len(os.listdir(other_path))<2:
	shutil.rmtree(other_path)
