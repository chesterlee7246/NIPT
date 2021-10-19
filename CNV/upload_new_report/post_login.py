#!/usr/bin/python
# -*- coding: utf-8 -*-

import requests
import json
urlt = 'https://lims14.bioerp.com/ir/get/session_id'

pushdata={"login":"lv386","password":"best.123A"}
pushout = requests.post(url = urlt, data = pushdata)
json1 = json.loads(pushout.text)
print json1
# 7f40a3d31403c72c25dc28d81196f37bfcb93a3e
