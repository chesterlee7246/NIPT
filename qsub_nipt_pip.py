#!/usr/bin/python
import os
import sys
import time

def nipt_pbs(work_dir,pip_dir,pipeline):
    result_dir = os.path.abspath(work_dir)
    site=os.path.basename(os.path.dirname(work_dir))
    os.system("chmod -R 775 " + result_dir)
    sbatch_file = result_dir + "/" + site + "_nipt_analysis.sh"
    R_time = time.strftime('%H%M%S', time.localtime(time.time()))
    sbatch = open(sbatch_file, 'w')
    sbatch.write("#!/bin/sh\n")
    sbatch.write("#SBATCH -J " + site + "_nipt_" + R_time + "\n")
    sbatch.write("#SBATCH -e " + result_dir + "/nipt_analysis.err" + "\n")
    sbatch.write("#SBATCH -o " + result_dir + "/nipt_analysis.out" + "\n")
    sbatch.write("#SBATCH --partition=cu2\n")
    sbatch.write("#SBATCH  -N 1 \n")
    sbatch.write("#SBATCH   --cpus-per-task 12\n")
    sbatch.write("source /home/bioinfo/software/environment.vne.latest\n")
    sbatch.write("python " + pip_dir + "/NIPT.py -i " + result_dir + " -s " + site + " -p " + pipeline +"\n")
    sbatch.close()

    return sbatch_file

if __name__=="__main__":
    if len(sys.argv) != 3:
        print "\n\033[31m python qsub_nipt_pip.py work_dir pipeline(full|analysis|upload|report)\033[0m\n"
        sys.exit(1)
    pip_dir=os.path.dirname(os.path.abspath(sys.argv[0]))
    work_dir=sys.argv[1]
    print(work_dir)
    pipeline=sys.argv[2]
    nipt_file=nipt_pbs(work_dir,pip_dir,pipeline)
    os.system("sbatch "+nipt_file)
