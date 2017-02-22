#!/bin/bash
#coding=gb2312
#/*******************************************************************************
# * Author	 : liubing@sogou-inc.com
# * Last modified : 2016-04-25 18:58
# * Filename	 : KVFileTool.sh
# * Description	 : k-v�ļ���صĺ���
# * *****************************************************************************/

# ȥ�أ�������������,�����Ƚ϶��
function uniq_kv_files() {
	input=$1;  output=$2
	awk -F'\t' 'BEGIN {
		url = ""; lastItem = "";
	}{
		if (NF==2 && $1=="url") {
			if (lastItem != "") {
				if (!(url in itemArray) || lastItemLen >= lastItemLenArray[url]) {
					itemArray[url] = lastItem
					lastItemLenArray[url] = lastItemLen
				}
			}
			url = $2; lastItem=$0; lastItemLen=1
		} else {
			lastItem = lastItem "\n" $0
			lastItemLen += 1
		}
	} END {
		if (!(url in itemArray) || lastItemLen >= lastItemLenArray[url]) {
			itemArray[url] = lastItem
			lastItemLenArray[url] = lastItemLen
		}
		for (url in itemArray) {
			print itemArray[url]
		}
	}' $input > $output
	echo "uniq kv file $input to $output done."
}


# ʼ�ձ������µ��Ǹ�
function uniq_kv_files_new() {
	input=$1;  output=$2
	awk -F'\t' 'BEGIN {
		url = ""; lastItem = "";
	}{
		if (NF != 2) {
			next
		}
		if ($1=="url") {
			if (lastItem != "") {
				itemArray[url] = lastItem
			}
			url = $2; lastItem=$0;
		} else {
			lastItem = lastItem "\n" $0
		}
	} END {
		if (lastItem != "") {
			itemArray[url] = lastItem
		}
		for (url in itemArray) {
			print itemArray[url]
		}
	}' $input > $output
	echo "uniq kv file $input to $output done."
}






