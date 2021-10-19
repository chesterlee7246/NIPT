#!/bin/bash 
if [ $# != 1 ]
then
	echo ""
	echo "  Usage: sh $0 <pipeline> "
	echo ""
	echo -ne " <pipeline (full|analysis|plot1|plot2|mail|upload|report)> "
        echo ""
	exit 1
fi

work_dir=`pwd`
pip_dir=$(dirname "$0")
pipeline=$1
python $pip_dir/qsub_cnv_pip.py $work_dir $pipeline
