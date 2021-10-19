# -*- coding: utf-8 -*-

#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
请先用在demo2里测试，然后用正式数据库health
正式的用户名为：xml-rpc
密码为：xml-rpc-4428130-cyagen-health100
以下三部分，david已通过测试，有问题请联系david
"""
import xmlrpclib
import sys

user = 'xml-rpc' #用户名
pwd = '7816c2f1d84fe5e3'  #密码
#pwd = 'FFE9E85AE409C1D2D969C1EFACD52562'
#dbname = 'demo2'  #数据库
dbname = 'szslyy'

sock = xmlrpclib.ServerProxy('http://58.210.99.235:8069/xmlrpc/common')
uid = sock.login(dbname ,user ,pwd)
sock = xmlrpclib.ServerProxy('http://58.210.99.235:8069/xmlrpc/object')

#******第五部分*写入测序信息*******************************************************************************************
#------头---------
sqr_name = sys.argv[1] #测序单号
sqr_ids = sock.execute(dbname, uid, pwd, 'bio.nipt.sequencing.record.sheet', 'search', [('name', '=', sqr_name)])
if sqr_ids:
    #------行---------
    tou_obj = sock.execute(dbname, uid, pwd, 'bio.nipt.sequencing.record.sheet', 'read', sqr_ids[0], ['libary_ids','libary_zhi_ids'])
    libary_ids = tou_obj['libary_ids'] if 'libary_ids' in tou_obj else []
    for line_id in libary_ids:
        line_obj = sock.execute(dbname, uid, pwd, 'bio.nipt.sequencing.record.sheet.line', 'read', line_id, ['name', 'index'])
        name_ids = line_obj['name'] if 'name' in line_obj else []
        name = name_ids[1] if name_ids else False #样本编号
        #index_ids = line_obj['index'] if 'index' in line_obj else []
        #index = index_ids[1] if index_ids else False #index
        index = line_obj['index'] if 'index' in line_obj else []  #index
        #print name,index,'----------------------'
        if name == sys.argv[2] and int(index) == int(sys.argv[3]): # 根据“样本编号” 和 “index”判断
            smp_values = {'run_unique_reads': sys.argv[4],
                      'run_t1': sys.argv[5],
                      'run_t2': sys.argv[6],
                      'run_t3': sys.argv[7],
                      'run_t4': sys.argv[8],
                      'run_t5': sys.argv[9],
                      'run_t6': sys.argv[10],
                      'run_t7': sys.argv[11],
                      'run_t8': sys.argv[12],
                      'run_t9': sys.argv[13],
                      'run_t10': sys.argv[14],
                      'run_t11': sys.argv[15],
                      'run_t12': sys.argv[16],
                      'run_t13': sys.argv[17],
                      'run_t14': sys.argv[18],
                      'run_t15': sys.argv[19],
                      'run_t16': sys.argv[20],
                      'run_t17': sys.argv[21],
                      'run_t18': sys.argv[22],
                      'run_t19': sys.argv[23],
                      'run_t20': sys.argv[24],
                      'run_t21': sys.argv[25],
                      'run_t22': sys.argv[26],
                      'run_x': sys.argv[27],
                      'run_other': sys.argv[28],
                      'run_fetal': sys.argv[29],
                      'run_fetal2': sys.argv[30],
                      'x_run_gc': sys.argv[31],
                      'x_run_xs': sys.argv[32],
                      }#要写入行的值
            results = sock.execute(dbname, uid, pwd, 'bio.nipt.sequencing.record.sheet.line', 'write', line_id, smp_values)
            if results:
                print name,index,'SAMPLE INFO UPLOAD SUCCESS.'

    libary_zhi_ids = tou_obj['libary_zhi_ids'] if 'libary_zhi_ids' in tou_obj else []
    for line_id in libary_zhi_ids:
        #line_obj = sock.execute(dbname, uid, pwd, 'bio.nipt.sequencing.record.sheet.zhi', 'read', line_id, ['name', 'index'])
        line_obj = sock.execute(dbname, uid, pwd, 'bio.nipt.sequencing.record.sheet.zhi', 'read', line_id, ['barcode', 'index'])
        #name_ids = line_obj['name'] if 'name' in line_obj else []
        #name = name_ids[1] if name_ids else False #样本编号
        name_ids = line_obj['barcode'] if 'barcode' in line_obj else False
        name = name_ids if name_ids else False #样本编号
        #index_ids = line_obj['index'] if 'index' in line_obj else []
        #index = index_ids[1] if index_ids else False #index
        index = line_obj['index'] if 'index' in line_obj else []  #index
        #print name,index,'----------------------'
        if name == sys.argv[2] and int(index) == int(sys.argv[3]): # 根据“样本编号” 和 “index”判断
            smp_values = {'run_unique_reads': sys.argv[4],
                      'run_t1': sys.argv[5],
                      'run_t2': sys.argv[6],
                      'run_t3': sys.argv[7],
                      'run_t4': sys.argv[8],
                      'run_t5': sys.argv[9],
                      'run_t6': sys.argv[10],
                      'run_t7': sys.argv[11],
                      'run_t8': sys.argv[12],
                      'run_t9': sys.argv[13],
                      'run_t10': sys.argv[14],
                      'run_t11': sys.argv[15],
                      'run_t12': sys.argv[16],
                      'run_t13': sys.argv[17],
                      'run_t14': sys.argv[18],
                      'run_t15': sys.argv[19],
                      'run_t16': sys.argv[20],
                      'run_t17': sys.argv[21],
                      'run_t18': sys.argv[22],
                      'run_t19': sys.argv[23],
                      'run_t20': sys.argv[24],
                      'run_t21': sys.argv[25],
                      'run_t22': sys.argv[26],
                      'run_x': sys.argv[27],
                      'run_other': sys.argv[28],
                      'run_fetal': sys.argv[29],
                      'run_fetal2': sys.argv[30],
                      'x_run_gc': sys.argv[31],
                      'x_run_xs': sys.argv[32],
                      }#要写入行的值
            results = sock.execute(dbname, uid, pwd, 'bio.nipt.sequencing.record.sheet.zhi', 'write', line_id, smp_values)
            if results:
                print name,index,'SAMPLE INFO UPLOAD SUCCESS.'


