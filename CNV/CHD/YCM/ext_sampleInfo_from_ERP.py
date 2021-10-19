# -*- coding: utf-8 -*-

import xmlrpclib
import sys
reload(sys)
sys.setdefaultencoding('utf8')

name = sys.argv[1]
hospital = sys.argv[2]
run_id = sys.argv[3]

if hospital=="JiaYin" :
    user = 'xml-rpc-xjjy' #用户名
    pwd = '98be9c7fb2c3d0bca'  #密码
    dbname = 'xjjy'  #数据库

    uid = 5
    sock = xmlrpclib.ServerProxy('http://192.168.10.137:8069/xmlrpc/object')

if hospital=="ZhongNanXiangYa" :
    user = 'xml-rpc-zndx' #用户名
    pwd = '9c6b820e72f4e63698e7a852e8b08969'  #密码
    dbname = 'zndx'  #数据库

    uid = 5
    sock = xmlrpclib.ServerProxy('http://192.168.10.137:8069/xmlrpc/object')
#else:
#    print hospital,'connect fail'
#    sys.exit(0)

sample_ids = sock.execute(dbname, uid, pwd, 'chd.sample.line', 'search_read', [('name', '=', name)],['woman_id'])
if sample_ids and sample_ids[0]['woman_id']:
    woman_id = sample_ids[0]['woman_id'][0]
    sample_id = sample_ids[0]['id']
    woman = sock.execute(dbname, uid, pwd, 'chd.sample.line.woman', 'read', [woman_id], ['is_y'])
    is_y = woman[0]['is_y']
    sequencing = sock.execute(dbname, uid, pwd, 'chd.sequencing', 'search', [('name', '=', run_id)])
    if sequencing:
        sequencing_id = sequencing[0]
        seq_line_ids = sock.execute(dbname, uid, pwd, 'chd.sequencing.line', 'search_read', [('line_id', '=', sequencing_id),('name', '=', sample_id)],['index'])
        if seq_line_ids:
            index = seq_line_ids[0]['index']
            print '%s,%s,%s' % (name, index, is_y)
