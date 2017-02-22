#!/bin/bash
#coding=gb2312

# ���ڵ����������ֵ�����

. ./bin/Tool.sh

DIANPING_DIR="Input"


# �ַ����ݵ�Output��
function dispatch() {
	for cityDir in $(ls $DIANPING_DIR/); do
		typeDir="play"
		if [ "$cityDir" == "movie" ]; then
			LOG "movie dir, continue."
			continue
		fi
		
		srcDir="$DIANPING_DIR/$cityDir/$typeDir"
		if [ ! -d $srcDir ]; then
			LOG "$srcDir dir is not exist!"
			continue
		fi

		for srcFile in $(ls $DIANPING_DIR/$cityDir/$typeDir/*.table); do
			destFile=${srcFile/Input/Output}
			destDir=$(dirname $destFile)
			if [ ! -d $destDir ]; then
				mkdir -p $destDir
			fi
			mv $destFile $destFile.bak
			cp $srcFile $destFile
		done

		LOG "dispatch data for $cityDir city done."
	done
}



function main() {
	# �ַ���OutputĿ¼��
	dispatch

}

main
