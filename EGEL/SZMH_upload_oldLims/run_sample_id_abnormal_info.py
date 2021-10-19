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
sqr_ids = sock.execute(dbname, uid, pwd, 'bio.nipt.sequencing.record.sheet', 'search', [('name', '=', sqr_name)])
if sqr_ids:
    #------��---------
    tou_obj = sock.execute(dbname, uid, pwd, 'bio.nipt.sequencing.record.sheet', 'read', sqr_ids[0], ['libary_ids','libary_zhi_ids'])
    libary_ids = tou_obj['libary_ids'] if 'libary_ids' in tou_obj else []
    for line_id in libary_ids:
        line_obj = sock.execute(dbname, uid, pwd, 'bio.nipt.sequencing.record.sheet.line', 'read', line_id, ['name', 'index'])
        name_ids = line_obj['name'] if 'name' in line_obj else []
        name = name_ids[1] if name_ids else False #�������
        #index_ids = line_obj['index'] if 'index' in line_obj else []
        #index = index_ids[1] if index_ids else False #index
        index = line_obj['index'] if 'index' in line_obj else []  #index
        #print name,index,'----------------------'
        if name == sys.argv[2] and int(index) == int(sys.argv[3]): # ���ݡ�������š� �� ��index���ж�
            txt = sys.argv[4]
            oo = open(txt, 'rb').read()
            if not oo:
                oo = ' '  	 
            smp_values = {
                      #'result_note': sys.argv[4],
                      'result_note': oo,
                      }#Ҫд���е�ֵ
            results = sock.execute(dbname, uid, pwd, 'bio.nipt.sequencing.record.sheet.line', 'write', line_id, smp_values)
            if results:
                print name,index,'SAMPLE INFO UPLOAD SUCCESS.'
