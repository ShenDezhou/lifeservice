#!/bin/bash
#coding=gb2312
# creater: liubing@sogou-inc.com
# date: 2015-12-17
# �ַ���ץȡ��URL��Spider Client Host��ȥ

. /search/zhangk/Fuwu/Tool/SSH/bin/HostConfig.sh
. ./bin/Tool.sh

# ���ַ���url�ļ���url����Ŀ¼��url�ļ�������ʽ
if [ $# -lt 2 ]; then
	echo "Usage: sh $0 urlFile|urlDir|urlFileRegex destDir [-public]"
	exit -1
fi
URLFile="$1";  DestDir="$2";


# ���ַ��Ļ����б�
HostArray=${NatHostList[*]}
if [ $# -ge 3 ];  then
	HostOpt="$3"
fi

if [ "$HostOpt" = "-public" ]; then
	HostArray=${PublicHostList[*]}
fi
HostArraySize=$(echo $HostArray | awk '{print NF}')


# ����һ��Ŀ¼�µ�URL�ļ�������Spider Client
function dispatch_urls_dir() {
	fileNum=0;
	for file in $(ls -S $URLFile); do
		fileNum=$((fileNum + 1));  hostIdx=$((fileNum % $HostArraySize))
		
		host=$(echo $HostArray | awk -v IDX=$hostIdx '{print $(IDX+1)}')
		srcFile="${URLFile}/${file}";  destPath="$DestDir/${file}"

		./expect/scp_file.exp "$srcFile" "$host:$destPath" $PASSWD
		LOG "scp $srcFile to $host:$destPath done"
	done
}


# ����һ���ļ�/�����ʾ���ļ�������Spider Client
function dispatch_urls_file() {
	fileNum=0;  srcPath=$(dirname $URLFile)
	for file in $(ls -S $URLFile); do
		fileNum=$((fileNum + 1));  hostIdx=$((fileNum % $HostArraySize))
		host=$(echo $HostArray | awk -v IDX=$hostIdx '{print $(IDX+1)}')
		srcFile="${file}";  destPath="$DestDir/$(basename $file)"

		./expect/scp_file.exp "$srcFile" "$host:$destPath" $PASSWD
		LOG "scp $srcFile to $host:$destPath done"
	done
}



if [ -d $URLFile ]; then
	dispatch_urls_dir
else
	dispatch_urls_file
fi

