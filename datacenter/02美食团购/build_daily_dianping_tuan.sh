#!/bin/bash
#coding=gb2312

Log="logs/build_daily_dianping_tuan.log"

. ./bin/Tool.sh
. ./bin/dianping_tuan_tool.sh


# �ϲ��Ź���Ϣ��ȫ��������
function merge_tuan_imp() {
	allFile=$1;  addFile=$2;  output=$3;

	# �ϲ�����ȥ����������
	awk -F'\t' ' ARGIND == 1 {
		# �Ź�ȫ��
		if (FNR == 1) {
			print; next
		}
		tuanid=$1;  resid=$2;  url=$5;  deadline=$NF
		tuanItem = resid "\t" url
		allTuanItem[tuanItem]
		print

	} ARGIND == 2 {
		# �������Ź�
		if (FNR == 1) {
			next
		}
		# �����Ѵ��ڵ��Ź�
		resid=$2;  url=$5;
		tuanItem = resid "\t" url
		if (tuanItem in allTuanItem) {
			next
		}
		print
	}' $allFile $addFile > $output
}


# ��ÿ����Ź���Ϣ����ӵ�ȫ����
function merge_daily_tuan() {
	for allTuanFile in $(ls tuandata/all/*.data.format); do
		dailyTuanFile=${allTuanFile/all/daily}
		if [ ! -f $dailyTuanFile ]; then
			continue
		fi

		# �ϲ�ȫ��������
		merge_tuan_imp $allTuanFile $dailyTuanFile $allTuanFile.adddaily

		# ���ݣ�����
		backFile="tuandata/history/$(basename $allTuanFile).$(todayStr)"
		rm -f $backFile;   mv $allTuanFile $backFile
		cp -f $allTuanFile.adddaily $allTuanFile

		LOG "handle $allTuanFile done." >> $Log
	done
}


# ת��ʽ
function format_daily_tuan() {
	for tuanFile in $(ls tuandata/daily/*.data); do
		format $tuanFile $tuanFile.format
		LOG "format $tuanFile done." >> $Log
	done
}


function main() {
	# ɾ����ʷ����
	find ./tuandata/history/ -ctime +5 | xargs rm -f {}

	# ���ص�����Ź���Ϣ
	/usr/bin/python  bin/build_daily_dianping_tuan.py
	LOG "get daily dianping tuan done." >> $Log

	# ת����ʽ
	format_daily_tuan
	LOG "format all daily dianping tuan done." >> $Log

	# �ϲ���ȫ���Ź���Ϣ��	
	merge_daily_tuan
	LOG "merge daily dianping tuan done." >> $Log
}

main

