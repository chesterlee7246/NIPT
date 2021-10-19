#!/bin/bash
for i in $(ls *rawlib_rmdup_MAPQ60_Nbin.txt);do
(perl /home/bioadmin/sky/New_Analysis/SZMH/NIPT-SizeSelect-PLUS/auto_run_analysis.pl $i /home/bioadmin/sky/New_Analysis/SZMH/NIPT-SizeSelect-PLUS/
)&
done
wait
perl /home/bioadmin/sky/New_Analysis/SZMH/NIPT-SizeSelect-PLUS/run_sample_id_abnormal_info.pl ./ /home/bioadmin/sky/New_Analysis/XuZhou/
perl /home/bioadmin/sky/New_Analysis/SZMH/NIPT-SizeSelect-PLUS/run_sample_id_png_info.pl ./ /home/bioadmin/sky/New_Analysis/XuZhou/
