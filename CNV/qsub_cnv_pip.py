#!/usr/bin/python
import os
import sys
import time

def cnv_pbs(work_dir,pip_dir,pipeline):
    run_name=os.path.basename(work_dir)
    site=os.path.basename(os.path.dirname(work_dir))
    R_time=time.strftime('%H%M%S',time.localtime(time.time()))
    cnv_file=work_dir+"/cnv_"+site+"_"+run_name+".slurm"
    cnv_f=open(cnv_file,'w')
    cnv_f.write("#!/bin/bash\n")
    cnv_f.write("#SBATCH -J "+site+"cnv"+R_time+"\n")
    cnv_f.write("#SBATCH -e "+work_dir+"/cnv_"+run_name+".err"+"\n")
    cnv_f.write("#SBATCH -o "+work_dir+"/cnv_"+run_name+".out"+"\n")
    cnv_f.write("#SBATCH -p cu2\n")
    cnv_f.write("#SBATCH -N 1\n")
    cnv_f.write("#SBATCH -n 40\n")
    cnv_f.write("source /home/bioinfo/software/environment.vne.latest\n")
    cnv_f.write("python "+pip_dir+"/CNV_pipeline.py -i "+work_dir+" -s "+site+" -p "+pipeline+" -y\n")
    cnv_f.close()
    return cnv_file

if __name__=="__main__":
    if len(sys.argv) != 3:
        print "\n\033[31m python qsub_cnv_pip.py work_dir pipeline(full|analysis|plot1|plot2|mail|upload|report)\033[0m\n"
        sys.exit(1)
    pip_dir=os.path.dirname(os.path.abspath(sys.argv[0]))
    work_dir=sys.argv[1]
    pipeline=sys.argv[2]
    cnv_file=cnv_pbs(work_dir,pip_dir,pipeline)
    os.system("sbatch "+cnv_file)
