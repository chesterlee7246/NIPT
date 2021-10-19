#-*-encoding:utf-8-*-
import sys
import json
import re


d=dict()
json_file = file(sys.argv[-1])
json_dict = json.load(json_file)
for x in json_dict['read_groups']:
    for y in json_dict['read_groups'][x]:
        if y == 'sample':
            key = json_dict['read_groups'][x][y]
        elif y == 'index':
            values = ['%03.2i' %(json_dict['read_groups'][x][y])]
        else:
            continue
    d[key]=values
    
for key in d:
    if not(key == 'None') and not (key == 'none'):
        
        for k in d[key]:
            print k
    else:
        continue
    

    
            
        
        
        
        

       
