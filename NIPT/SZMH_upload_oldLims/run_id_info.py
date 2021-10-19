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
sqr_values = {'run_reads': sys.argv[2],
              'run_total': sys.argv[3],
              'run_average': sys.argv[4],
              'run_loading': sys.argv[5],
              'run_enri': sys.argv[6],
              'run_clonal': sys.argv[7],
              'run_final_lib': sys.argv[8],
              'run_empty_wells': sys.argv[9],
              'run_no_temp': sys.argv[10],
              'run_polyclonal': sys.argv[11],
              'run_low_qua': sys.argv[12],
              'x_barcode': sys.argv[13],
              'run_q20': sys.argv[14],
              }#要写入的值
sqr_ids = sock.execute(dbname, uid, pwd, 'bio.nipt.sequencing.record.sheet', 'search', [('name', '=', sqr_name)])
if sqr_ids:
    results = sock.execute(dbname, uid, pwd, 'bio.nipt.sequencing.record.sheet', 'write', sqr_ids[0], sqr_values)
    if results:
        print 'RUN INFO UPLOAD SUCCESS.'
