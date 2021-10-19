#!/bin/bash
if [ -z $1 ];then
	echo ""
	echo "Usage:"
	echo ""
	echo "   bash $0  YCM_DIR  OUT_DIR"
	echo ""
	exit
fi
#脚本所在目录
scriptdir=`dirname $0`
#输出目录，默认为当前目录
outdir=$2
if [ -z $outdir ];then
	outdir="./"
fi
#参考文件目录
python $scriptdir/check_contorl.py $scriptdir

control="$scriptdir/../data/control/control.txt"
#脚本
cmd="perl $scriptdir/YCM.pl"
if [ ! -e "$1/index2id_YCM.txt" ] ;then
	echo "$1/index2id_YCM.txt does not exist!"
	exit
fi
for i in $(find $1 -name "*_rawlib_CYM.bed" )
do	
	echo "----------------------------"
	args=" "
	args+=" --format bed "
	args+=" --outdir $outdir "
	args+=" --sample $i "
	args+=" --control $control "
	name=`basename $i`
	index=${name//_rawlib_CYM.bed/}
	index=${index//IonXpress_/}
	#使用index从index2id_YCM.txt中提取样本id
	sample=`grep -m1 "IonXpress_$index" $1/index2id_YCM.txt|awk '{print $1}'`
	if [ -z $sample ];then
		echo "Index:$index does not have corresponding sample id!"
		continue
	fi
	#输出日志，图片，pdf文件的前缀
	sample_name="ChrY-$sample-$index"
	args+=" --name $sample_name "
	args+=" --svm_out $sample_name.txt "
	info=`$cmd $args`
	echo $info
	echo "----------------------------"
done
