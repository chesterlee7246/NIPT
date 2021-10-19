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
            txt = sys.argv[4]
            oo = open(txt, 'rb').read()
            if not oo:
                oo = ' '  	 
            smp_values = {
                      #'result_note': sys.argv[4],
                      'result_note': oo,
                      }#要写入行的值
            results = sock.execute(dbname, uid, pwd, 'bio.nipt.sequencing.record.sheet.line', 'write', line_id, smp_values)
            if results:
                print name,index,'SAMPLE INFO UPLOAD SUCCESS.'
