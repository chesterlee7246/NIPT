# -*- coding: utf-8 -*-

#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
��������demo2����ԣ�Ȼ������ʽ���ݿ�health
��ʽ���û���Ϊ��xml-rpc
����Ϊ��xml-rpc-4428130-cyagen-health100
���������֣�david��ͨ�����ԣ�����������ϵdavid
"""
import xmlrpclib
import sys

user = 'xml-rpc' #�û���
pwd = '7816c2f1d84fe5e3'  #����
#pwd = 'FFE9E85AE409C1D2D969C1EFACD52562'
#dbname = 'demo2'  #���ݿ�
dbname = 'szslyy'

sock = xmlrpclib.ServerProxy('http://58.210.99.235:8069/xmlrpc/common')
uid = sock.login(dbname ,user ,pwd)
sock = xmlrpclib.ServerProxy('http://58.210.99.235:8069/xmlrpc/object')

#******���岿��*д�������Ϣ*******************************************************************************************
#------ͷ---------
sqr_name = sys.argv[1] #���򵥺�
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
              }#Ҫд���ֵ
sqr_ids = sock.execute(dbname, uid, pwd, 'bio.nipt.sequencing.record.sheet', 'search', [('name', '=', sqr_name)])
if sqr_ids:
    results = sock.execute(dbname, uid, pwd, 'bio.nipt.sequencing.record.sheet', 'write', sqr_ids[0], sqr_values)
    if results:
        print 'RUN INFO UPLOAD SUCCESS.'
