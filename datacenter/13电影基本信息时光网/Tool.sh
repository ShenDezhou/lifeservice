#!/bin/bash
#coding=gb2312

# ��ǰʱ�䣬���ڼ�¼��־��
function now() {
	echo $(date "+%Y-%m-%d %H:%M:%S")
}

# ��ǰʱ�䣬���ڼ�¼��־��
function nowStr() {
	echo $(date "+%Y%m%d%H%M")
}

# ��ӡ��־
function LOG() {
    now=`date +"%Y-%m-%d %H:%M:%S"`
	echo $now" "$1
}

function INFO() {
    now=`date +"%Y-%m-%d %H:%M:%S"`
	echo $now" [INFO] "$1
}

function ERROR() {
    now=`date +"%Y-%m-%d %H:%M:%S"`
	echo $now" [ERROR] "$1
}
