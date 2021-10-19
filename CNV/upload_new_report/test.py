# -*- coding: utf-8 -*-

import requests
import datetime

Host = "https://lims14.bioerp.com"
user_name = 'lv386'
user_pwd = 'best.123A'


def login(name, pwd):
    """登录获取session_id，并保存"""
    response = requests.request("POST", Host + "/ir/get/session_id", data={'login': name, 'password': pwd})
    if response.text.find('!DOCTYPE HTML PUBLIC') > 0:
        print('网络错误')
        exit()
    res = eval(response.text)

    http_code = res.get('http_code')
    if http_code != 200:
        print('账号或密码错误，错误代码%s' % http_code)
        exit()

    data = res.get('data')
    api_txt = open('api.db', 'w')
    api_txt.write(str(data))
    api_txt.close()
    return 'session_id=' + data.get('session_id')


def get_cookie():
    """
    获取上一次存储的session_id, 
    如果session_id失效，则自动重新请求新的session_id, 
    session_id的默认有效期是90天
    """
    file = open('api.db')
    file_context = file.read()
    file.close()
    if file_context.find('session_id') > 0:
        f_context = eval(file_context)
        session_id = f_context.get('session_id')
        expires = f_context.get('expires')
        now_time = datetime.datetime.now().strftime('%Y-%m-%d')
        if expires < now_time:
            Cookie = login(user_name, user_pwd)
        else:
            Cookie = 'session_id=' + session_id
    else:
        Cookie = login(user_name, user_pwd)
    return Cookie


def upload_attachment(f_path, name='', description=''):
    """上传附件"""
    url = Host + "/ir/binary/upload_attachment"
    files = [('ufile', open(f_path, 'rb'))]
    response = requests.request("POST", url, headers={'Cookie': get_cookie()}, data={'name': name, 'description': description}, files=files)
    if response.text.find('!DOCTYPE HTML PUBLIC') > 0:
        print('session_id错误，请重新登录或者刷新页面')
        exit()
    res = eval(response.text)

    http_code = res.get('http_code')
    if http_code != 200:
        print('上传图片错误，错误代码%s' % http_code)
        exit()
    data = res.get('data')
    return data


"""修改结果"""
url = Host + "/cnv/result/create"
img = upload_attachment("1.jpg", '图片名称', '图片描述，可以省略')
payload = {'sample_id': 75, 'company_id': 3, 'note1': 'aaaaaaa', 'attachment_ids': str([(4, img.get('id'))])}
response = requests.request("POST", url, headers={'Cookie': get_cookie()}, data=payload)
if response.text.find('!DOCTYPE HTML PUBLIC') > 0:
    print('session_id错误，请重新登录或者刷新页面')
    exit()
res = eval(response.text)

http_code = res.get('http_code')
if http_code != 200:
    print('上传结果错误，错误代码%s' % http_code)
    exit()

print(res.get('message'), res.get('data'))
