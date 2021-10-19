#!/bin/bash
plugins=$1
commit=`git log|head -1`
info=`grep commit $plugins/launch.sh`
if [ -z "$info" ];then
	echo "#$commit" >>$plugins/launch.sh
else
	sed -i "s/commit.*$/$commit/g" $plugins/launch.sh
fi
zip -r ${1}.zip $1/* -x "*.orig"
