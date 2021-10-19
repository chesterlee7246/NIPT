#!/bin/bash
if [ $# != 2 ]
then
	echo -n "\n******************** This program is used for CHD ****************************\n"
	echo -n "          Usage:  bash $0 <bin_dir> <result_dir(abs_path)>\n"
	echo -n "   exmaple: bash $0 /home/bioadmin/YingyingXia/bin/CHD ./xxx/xxx/***\n"
	echo -n "******************************************************************************\n\n"
	exit 1
fi

bin_dir=$1
result_dir=$2
run_id=`basename $result_dir`
site=`dirname $result_dir`
site=`basename $site`

echo $run_id
echo $site

cd $result_dir

#perl $bin_dir/scr/unzip_file.pl $result_dir
perl $bin_dir/parallel_logRR.pl $result_dir $bin_dir/LOGRR
perl get_YCM_JiaYin.pl $result_dir $bin_dir $site $run_id

if [ -f $result_dir/index2id_YCM.txt ]
then
	bash $bin_dir/YCM/YCM/scripts/batch_YCM.sh $result_dir $result_dir
	perl $bin_dir/YCM/mail_YCMresult.pl $result_dir
fi

perl $bin_dir/Auto_DNAcopy_BreakPoints.pl $result_dir $bin_dir/BreakPoints $bin_dir/DatabaseAnn
perl $bin_dir/Upload_Scripts/upload_chd_info_SiteCommon.pl $result_dir $bin_dir/Upload_Scripts
python /home/bioadmin/YingyingXia/project/CHD/get_sampleinfo.py $result_dir/index2id.txt $site $run_id $result_dir/sample_info.txt
#perl $bin_dir/scr/create_zip.pl $result_dir
