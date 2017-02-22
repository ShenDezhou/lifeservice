#!/bin/bash
#coding=gb2312

Log="logs/build_update_dianping_tuan.log"

. ./bin/Tool.sh
. ./bin/dianping_tuan_tool.sh


# �ϲ��Ź���Ϣ��ȫ��������
function merge_tuan_imp() {
	allFile=$1;  updateTuanFile=$2; updateStatusFile=$3;  output=$4;

	# �ϲ�����ȥ����������
	awk -F'\t' 'ARGIND == 1 {
		# ״ֵ̬Ϊ0 ���˵�
		if (NF != 2) {
			next
		}
		id=$1; status=$2;
		if (status == "0") {
			deleteids[id]	
		}
	} ARGIND == 2 {
		# ���µ��Ź�����
		deleteids[$1]
		print
	} ARGIND == 3 {
		# �Ź�ȫ��
		tuanid=$1;  resid=$2;  url=$5;  deadline=$NF
		# ���˵��Ѿ����ߵ��Ź�
		if (tuanid in deleteids) {
			next
		}
		tuanItem = resid "\t" url
		allTuanItem[tuanItem]
		print
	}' $updateStatusFile $updateTuanFile $allFile > $output
}


# ��ÿ����Ź���Ϣ����ӵ�ȫ����
function merge_update_tuan() {
	for allTuanFile in $(ls tuandata/all/*.data.format); do
		updateTuanFile=${allTuanFile/all/update}
		updateStatusFile=${updateTuanFile/.data.format/.ids}

		if [ ! -f $updateTuanFile -o ! -f $updateStatusFile ]; then
			continue
		fi

		# �ϲ�ȫ��������
		merge_tuan_imp $allTuanFile $updateTuanFile $updateStatusFile $allTuanFile.addupdate

		# ���ݣ�����
		backFile="tuandata/history/$(basename $allTuanFile).$(todayStr)"
		rm -f $backFile;   mv $allTuanFile $backFile
		cp -f $allTuanFile.addupdate $allTuanFile

		LOG "handle $allTuanFile done." >> $Log
	done
}


# ת��ʽ
function format_update_tuan() {
	for tuanFile in $(ls tuandata/update/*.data); do
		format $tuanFile $tuanFile.format
		LOG "format $tuanFile done." >> $Log
	done
}

# �ŵ�output������ʹ��
function put_to_output() {
	for tuanFile in $(ls tuandata/all/*.data.format); do
		onlinePath=${tuanFile/.data.format/}
		onlinePath=${onlinePath/all/output}
		rm -f $onlinePath.bak;  mv $onlinePath $onlinePath.bak
		cp $tuanFile $onlinePath
	done
}


function back_up_updatelog() {
	backupPath=tuandata/updatelog
	now=$(nowStr)
	for updateFile in $(ls tuandata/update/*.ids); do
		backupFile=$backupPath/$(basename $updateFile)
		echo -e "\n ======= $now =======" >> $backupFile
		cat $updateFile >> $backupFile
		LOG "backup $updateFile done." >> $Log
	done
}

function main() {
	# ɾ����ʷ����
	find ./tuandata/history/ -ctime +5 | xargs rm -f {}

	# ���ص�����Ź���Ϣ
	/usr/bin/python  bin/build_update_dianping_tuan.py
	LOG "get daily update dianping tuan done." >> $Log

	# ת����ʽ
	format_update_tuan
	LOG "format all daily dianping tuan done." >> $Log

	# �ϲ���ȫ���Ź���Ϣ��	
	merge_update_tuan
	LOG "merge all update dianping tuan done." >> $Log

	# �ŵ�����
	put_to_output
	LOG "put all dianping tuan to output path done." >> $Log
}

main
