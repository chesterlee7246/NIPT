#!/usr/bin/python
import sys
import os

def chek_control(script_dir):
    control_dir=os.path.dirname(script_dir)+"/data/control"
    control_file=control_dir+"/control.txt"
    conf=open(control_file,"w")
    file_list=os.listdir(control_dir)
    for line in file_list:
        if line.endswith(".bam"):
            conf.write(control_dir+"/"+line+"\n")
    conf.close()
    return("OK")
  
if __name__=="__main__":
    script_dir=sys.argv[1]
    chek_control(script_dir)            
