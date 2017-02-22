#!/bin/bash
#coding=gb2312
# ɨ�⣬���´��ڵ���������


# 1. ɨ�⣬�õ����ڵ������б�url  http://web_sac.sogou-inc.com/scan/tasksubmit.html   (scan from index)
# 2. getmerge ɨ����������  Scan/data/dianping_scan_list


. ./bin/Tool.sh

if [ $# -lt 3 ]; then
	echo "Usage: sh $0 urlFile resultFile failUrlFile" && exit -1
fi

# ���Ǿ���·��
urlFile=$1;  resultFile=$2;  failUrlFile=$3; threadIdx="";

# �̺߳�
if [ $# -gt 3 ]; then
	threadIdx=$4
fi

#urlFile=/search/fangzi/ServiceApp/Dianping/test_dianping_urls 
#resultFile=/search/fangzi/ServiceApp/Dianping/test/result
#failUrlFile=/search/fangzi/ServiceApp/Dianping/test/failUrl


#get_parse_restaurant_page $urlFile $resultFile $failUrlFile


Log=logs/get_parse_page_thread${threadIdx}.log



# ɨ���ȡurl�б��ҳ��
# �������Ǿ���·��
function get_page_from_db() {
	local urlFile=$1;  local pageFile=$2;  local failedUrl=$3

	LOG "begin to get page of $urlFile ..." >> $Log
	cd /search/fangzi/workspace/Getpage/
		cat $urlFile | ./bin/dbnetget -df cp -i url -o dd -d csum -l conf/offsum576 -pf $pageFile 1>get${threadIdx}.std 2>get${threadIdx}.err
		awk '$1=="N"{print $2}' get${threadIdx}.err >> $failedUrl
	cd -
	LOG "get page of $urlFile done." >> $Log
}


# ��ѹxpageҳ��
# ������Ҫ�ṩ����·��
function decode_page() {
	local pageFile=$1;  local decodeFile=$2
	local pageFilePrefix=${pageFile/page0/page}
	
	LOG "begin to decode page $pageFile into $decodeFile ..." >> $Log
	cd /search/fangzi/workspace/ParsePage/
		cat conf/offsum.tailer >> $pageFile
		sed "s#PAGEPATH#$pageFilePrefix#g" ./antispam.struct/conf/parsePage.conf.template > ./antispam.struct/conf/parsePage${threadIdx}.conf
		# ��ѹxpath��ʽҳ�棬��ת����һ�����Ա�Nodejs�����ĸ�ʽ
		./decodePage ./antispam.struct/conf/parsePage${threadIdx}.conf > page${threadIdx}.html
		sh bin/convert_html_to_line.sh page${threadIdx}.html $decodeFile
	cd -
	LOG "decode page $pageFile into $decodeFile done." >> $Log
}

# nodejs ����ҳ��
# �����Ǿ���·��
function parse_page() {
	local htmlFile=$1;  local resultFile=$2;
	LOG "begin to parse page $htmlFile into $resultFile ..." >> $Log
	
	cd /search/fangzi/workspace/Fuwu
		node parse-cheerio.js $htmlFile | iconv -futf8 -tgbk -c >> $resultFile
	cd -
	LOG "parse page $htmlFile into $resultFile done." >> $Log
}


function get_parse_restaurant_page() {
	local urlFile=$1;  local resultFile=$2;  local failedUrl=$3
	LOG "begin get & parse restaurant page, $urlFile" >> $Log
	
	# ɨ��õ�xpageҳ��
	pageFile=${urlFile}_page0
	get_page_from_db $urlFile $pageFile $failedUrl	
	
	# ��ѹҳ�� 
	decodePageFile=$urlFile.html
	decode_page $pageFile $decodePageFile
	
	# ����ҳ��
	parse_page $decodePageFile $resultFile
}


#get_parse_restaurant_page $urlFile $resultFile $failUrlFile




