#!/bin/python
import sys
import json
import re
import requests

if len(sys.argv) != 3:
    print "\nUSAGE: python "+sys.argv[0]+" ion_params_00.json index2id.txt\n"
    sys.exit(1)


stat=json.load(open(sys.argv[1]))
dict1_json=stat['experimentAnalysisSettings']['barcodedSamples']
dict2 = {}

if isinstance(dict1_json, dict):
    dict2=dict1_json
else:
    dict2=json.loads(dict1_json)

dict3={}
for each in dict2:
    dict3[str(dict2[each]['barcodeSampleInfo'].keys()[0])]=each

outf=open(sys.argv[2],'w')

for each in sorted(dict3):
    sample_name=dict3[each]
    des=dict2[sample_name]['barcodeSampleInfo'][each]['description']
    externalid=dict2[sample_name]['barcodeSampleInfo'][each]['externalId']
    if externalid=='':
        externalid=sample_name
#    des=dict2[sample_name]['barcodeSampleInfo'][each]['description']
    if des == '':
        des="null"     
    outf.write(each+"\t"+sample_name+"\t"+externalid+"\t"+des+"\n")
outf.close()

