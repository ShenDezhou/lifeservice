#!/bin/bash
#coding=gb2312

. ./bin/Tool.sh

Numbers=10000
ScanUrls=Scan/data/scan_dianping_urls

function scan_get_shopurls() {
	# ��ɨ��õ���URL ���˳�shop urls
	LOG "begin to scan shop urls"
	/usr/bin/python bin/split_dianping_scan_urls.py $ScanUrls > Scan/data/shop_urls
	LOG "scan shop urls done"


	# ���ϵ�����URL
	cat data/*/onlineUrl/* | awk -F'\t' '{
		if (!($1 in urls)) {
			print $1;
			urls[$1]
		}
	}' > Scan/data/online_shop_urls

	# �����Ѿ�ץȡ����Urls
	awk -F'\t' 'ARGIND==1 {
		onlineUrls[$1]
	} ARGIND==2 {
		if (!($1 in onlineUrls)) {
			print $1
		}
	}' Scan/data/online_shop_urls Scan/data/shop_urls > Scan/data/shop_urls.filte
	LOG "filte scan shop urls done"
}


input=Scan/data/shop_urls.filte
lines=$(cat $input | wc -l)
LOG "total $lines shop urls"

# ÿ���$Numbers��һ�δ���
#rm -f Scan/data/urlSplit/*
#split -l$Numbers $input Scan/data/urlSplit/shop_urls_


# �Ƿ������ɨһ������߻�ȡ���ݣ�

# �ڶ���Ͳ�����Ҫ��


# ���߳�ץȡ����










