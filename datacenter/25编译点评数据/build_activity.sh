#!/bin/bash
#coding=gb2312

. ./bin/Tool.sh

# ��������������Ļ������
BaseDir="/search/zhangk/Fuwu/Spider"

# ������ʲô��վ�Ļ����
JtwsmActivityData="${BaseDir}/Jtwsm/data/jtwsm_activity"

# ��ĩȥ�Ķ���վ�Ļ����
WanzhoumoActivityData="${BaseDir}/Wanzhoumo/data/wanzhoumo_activity"




function mergeActivityData() {
	mergeActivityData="Input/activity_data"
	cat $JtwsmActivityData $WanzhoumoActivityData > $mergeActivityData

	LOG "merge activity data done.[$mergeActivityData]"
}



function main() {
	# �ϲ�
	mergeActivityData



}

main

