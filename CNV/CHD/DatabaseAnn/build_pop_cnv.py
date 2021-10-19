#!/home/bioinfo/local/bin/python3
#-*-coding:utf-8-*-

import os,sys

if len(sys.argv) != 5:
    print("\nUSAGE: python3 "+sys.argv[0]+" cytoband_file frequency_file new_anno_file frequency_db\n")
    sys.exit(1)

Cytoband=sys.argv[1]
Frequency=sys.argv[2]
New_anno=sys.argv[3]
F_db=sys.argv[4]

##	提取CNV频率数据库，构建CNV对应频率字典
database = open(F_db,'r').readlines()[1:]
samples = float(database[0].strip().split('\t')[-3])
new_cnv = str(round(float(1/(samples+1))*100,3))+'%;'+'1;'+str(samples+1)
dbs = []
for db in database:
	db0 = db.strip().split('\t')
	freq = str(round(float(db0[10])*100,3))+'%'
	db1 = freq+';'+db0[9]+';'+db0[12]
	if db0[11]=='1':
		dbs.append(db0[1:5]+['dup',db1])
	else:
		dbs.append(db0[1:5]+['del',db1])

def get_file(size,rawdata):
	## 读取匹配到数据库的样本,设置CNV的大小
	raw_db = {}
	new_db = {}
	rawdatas=rawdata[1:]
	for raw0 in rawdatas:
		raw1 = raw0.strip().split('\t')
		statu = raw1[-2].split('(')[0]
		if float(raw1[5])>=0.4854268 or float(raw1[5])<=float(-0.7369656):
			if size<=float(raw1[8])<=10000000:
				for db in dbs:
					if db[0]==raw1[1] and db[4]==statu:
						len0=(float(raw1[3])-float(raw1[2])+1)*1.2	##	扩张20%的长度
						start0=float(raw1[3])-float(len0)+1
						end0=float(raw1[2])+float(len0)-1
						if float(db[1])>=start0 and float(db[2])<=end0:
							reg0=[db[1],db[2],raw1[2],raw1[3]]
							reg=sorted([float(i) for i in reg0])
							rate=float(reg[2]-reg[1]+1)/float(reg[3]-reg[0]+1)
							if rate>=0.8:
								ff=db[-1]+';'+db[0]+':'+db[1]+'-'+db[2]+';'+str(round(float(rate),5)*100)+'%'
								raw_db['\t'.join(raw1+[ff])]=','.join(raw1[1:4])
							else:
								new_db['\t'.join(raw1+[new_cnv])]=','.join(raw1[1:4])
						else:
							new_db['\t'.join(raw1+[new_cnv])]=','.join(raw1[1:4])

	## 将匹配到的CNV进行去重复并构建词典
	values_raw=list(raw_db.values())
	new_dbs = {}
	for new_db0 in new_db:
		if new_db[new_db0] not in values_raw:
			new_dbs[new_db0] = new_db[new_db0]

	dats={}
	for dat in raw_db:
		dat0 = dat.strip().split('\t')
		dats[dat0[-1]]='\t'.join(dat0[0:-1])
	dats_total = list(set(list(dats.values())))

	## 总频率字典
	data1={}
	for dat1 in dats_total:
		freqs=[]
		nums0=[]
		for dat2 in dats:
			if dats[dat2]==dat1:
				dat3=dat2.split(';')
				freqs.append(float(dat3[1]))
				nums0.append(float(dat3[2]))
		total_num=str(int(nums0[0]))
		total_f=str(int(sum(freqs)))
		total_freq=str(round(100*float(sum(freqs))/float(nums0[0]),3))+'%'
		ttotal=total_freq+';'+total_f+';'+total_num
		values0 = dat1.strip().split('\t')[1:4]
		values1 = ','.join(values0)
		data1[dat1+'\t'+ttotal]=values1

	data2 = {**new_dbs,**data1}
	data = list(data2.keys())
	return data

def get_new_anno(data):
	new_anno0 = open(New_anno,'r')
	new_anno1 = new_anno0.readlines()
	new_anno0.close
	data0={}
	for dat0 in data:
		dat=dat0.strip().split('\t')
		data0['\t'.join(dat[0:4])]=dat[-1]
	title0=new_anno1[0].strip().split('\t')
	title1=title0[0:30]+['本地CNV数据库的频率']
	title='\t'.join(title1)
	new_anno3={}
	for new1 in new_anno1[1:]:
		new10=new1.strip().split('\t')
		new_anno3['\t'.join(new10[0:4])]='\t'.join(new10[0:30])
	new_anno4=[]
	for new3 in new_anno3:
		new30 = new_anno3[new3]
		new31 = new30.strip().split('\t')
		if len(str(new31[7]))>16:
			new32 = new31+[data0[new3]]
		else:
			new32 = new31+['-']
		new_anno4.append('\t'.join(new32))
	new_anno=[title]+new_anno4
	return new_anno

##	提取数据分析后的CNV，查找对应频率
rawdata = open(Cytoband,'r').readlines()
if Cytoband.split('_')[-2]=='100Kb':
	data=get_file(100000,rawdata)
	new_anno=get_new_anno(data)
if Cytoband.split('_')[-2]=='1Mb':
	data=get_file(1000000,rawdata)
	new_anno=get_new_anno(data)

## 写入文件
cnv_freq = open(Frequency,'w')
new_annos = open(New_anno,'w')

cnv_freq.write(rawdata[0].strip()+'\t'+'frequecy'+'\t'+'total_freq'+'\n')
for d in data:
	cnv_freq.write(d+'\n')
cnv_freq.close()
for n in new_anno:
	new_annos.write(n+'\n')
new_annos.close()
