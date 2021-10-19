# -*- coding: utf-8 -*-

#!/usr/bin/python
# -*- coding: utf-8 -*-

# test_client.py
import poster
from poster.encode import multipart_encode
from poster.streaminghttp import register_openers
import urllib2
import sys

# 在 urllib2 上注册 http 流处理句柄
register_openers()

# 开始对文件 "test.zip" 的 multiart/form-data 编码
# "file" 是参数的名字

# headers 包含必须的 Content-Type 和 Content-Length
# datagen 是一个生成器对象，返回编码过后的参数
datagen, headers = multipart_encode({"file": open(sys.argv[1], "rb")})

# 创建请求对象
request = urllib2.Request("http://api.basecare.cn/api/UploadFile", datagen, headers)
# 实际执行请求并取得返回
print urllib2.urlopen(request).read()
#成功：{"status":1,"data":null,"info":"success"}
#失败：{"status":0,"data":null,"info":"failure"}