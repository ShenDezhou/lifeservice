#!/bin/bash
#coding=gb2312
# ���´��ڵ����������������

. ./bin/Tool.sh
. ./bin/Host.sh

Log=logs/update.play.log
Python=/usr/bin/python

Play_list_urls=conf/dianping_play_list_urls


# ��ȡץȡ����ץȡ��URL�б�
function get_play_urls() {
	backupFile="history/$(basename $Play_list_urls).$(todayStr)"
	if [ ! -f $backupFile ]; then
		mv -f $Play_list_urls $backupFile
	fi
	LOG "backup play list url $Play_list_urls into $backupFile" >> $Log

	rm -f tmp/scp/play/*
	scp 10.134.14.117:/search/liubing/spiderTask/result/system/task-4/* tmp/scp/play/
	cat tmp/scp/play/* > $Play_list_urls

	LOG "get play list url $Play_list_urls from remote host 10.134.14.117 done." >> $Log
}



# �����ڵ����б�ҳ������shop url list������split
function split_play_urls() {
	city_code_name_conf=conf/dianping_city_code_pinyin_conf
	$Python bin/split_dianping_listurl.py $city_code_name_conf $Play_list_urls "play"
	LOG "split $Play_list_urls into data/play/url/" >> $Log
}



# ɨ���ȡurl�б��ҳ��
function get_page_from_db() {
	local urlFile=$1;  local pageFile=$2;  local failedUrl=$3

	LOG "begin to get page of $urlFile ..." >> $Log
	cd /search/fangzi/workspace/Getpage/
		#awk -F'\t' '{if(!($1 in urls)){ urls[$1]; print $1 }}' $urlFile > urls
		#cat urls | ./bin/dbnetget -df cp -i url -o dd -d csum -l conf/offsum576 -pf $pageFile 1>get.std 2>get.err
		cat $urlFile | ./bin/dbnetget -df cp -i url -o dd -d csum -l conf/offsum576 -pf $pageFile 1>get.std 2>get.err

		awk '$1=="N"{print $2}' get.err >> $failedUrl
	cd -
	LOG "get page of $urlFile done." >> $Log
}


# ��ѹxpageҳ��
function decode_page() {
	local pageFile=$1;  local decodeFile=$2
	local pageFilePrefix=${pageFile/page0/page}
	
	LOG "begin to decode page $pageFile into $decodeFile ..." >> $Log
	cd /search/fangzi/workspace/ParsePage/
		cat conf/offsum.tailer >> $pageFile
		sed "s#PAGEPATH#$pageFilePrefix#g" ./antispam.struct/conf/parsePage.conf.template > ./antispam.struct/conf/parsePage.conf
		# ��ѹxpath��ʽҳ�棬��ת����һ�����Ա�Nodejs�����ĸ�ʽ
		./decodePage ./antispam.struct/conf/parsePage.conf > page.html
		sh bin/convert_html_to_line.sh page.html $decodeFile
	cd -
	LOG "decode page $pageFile into $decodeFile done." >> $Log
}

# nodejs ����ҳ��
function parse_page() {
	local htmlFile=$1;  local resultFile=$2;
	LOG "begin to parse page $htmlFile into $resultFile ..." >> $Log
	
	cd /search/fangzi/workspace/Fuwu
		node parse-cheerio.js $htmlFile | iconv -futf8 -tgbk -c >> $resultFile
	cd -
	LOG "parse page $htmlFile into $resultFile done." >> $Log
}


function get_parse_play_page() {
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





# �ڱ���ִ���ȹز���
function get_parse_play_page_from_db() {
	play_url_path=data/play/url
	play_failurl_path=data/play/failurl
	play_result_path=data/play/result

	split_url_path=tmp/url/play
	count_per_file=10000

	cur_path=$(pwd)

	# ��ÿ�����е�url�ļ��зֳɸ�С���ļ����������
	for cityUrlFile in $(ls $play_url_path); do
		# �ó��е�ɨ��ʧ�ܵ�url
		failUrlFile=$play_failurl_path/${cityUrlFile%_*}_failurl
		rm -f $failUrlFile
		# �ó��еĽ������
		resultFile=$play_result_path/${cityUrlFile%_*}_result
		rm -f $resultFile

		# �зֳ�С�ļ�
		rm -f $split_url_path/*
		awk -F'\t' '{if(!($1 in urls)){ urls[$1]; print $1 }}' $play_url_path/$cityUrlFile > $play_url_path/$cityUrlFile.uniq
		split -l$count_per_file $play_url_path/$cityUrlFile.uniq $split_url_path/$cityUrlFile
		for urlFile in $(ls $split_url_path); do
			splitUrlFile=$split_url_path/$urlFile
			get_parse_play_page "$cur_path/$splitUrlFile" "$cur_path/$resultFile" "$cur_path/$failUrlFile"
		done
	done
}




# ��Զ�̻����ϵõ��Ľ�����ص�����
function scp_host_result_to_local() {
	type=$1
	HostPath=/search/odin/dianping/result/$type
	LocalPath=/search/fangzi/ServiceApp/Dianping/data/$type/result/

	ScpFileExpect=/search/fangzi/ServiceApp/expect/scp_file.exp

	for host in ${NatHostList[@]}; do
		LOG "==========  scp result $host ============"
		$ScpFileExpect $host:$HostPath/*.result $LocalPath "$Passwd"
		LOG "scp result $host done."
		sleep 2
	done
	LOG "clean shop urls on host done."
}


	
# ����Զ�̷ַ������ϵ�urls
function clean_host_shop_urls() {
	cleanPath=$1
	cleanScript=/search/fangzi/ServiceApp/expect/clean_shop_urls.exp
	for host in ${NatHostList[@]}; do
		LOG "==========  clean $host ============"
		$cleanScript $host $Passwd $cleanPath
		LOG "clean $host done."
		sleep 2
	done
	LOG "clean shop urls on host done."
}


# �ַ�����ͬ�Ļ�����
function dispatch_shop_urls() {
	urlFilePath=$1;  type=$2;
	echo "$type"

	HostPath=/search/odin/dianping/url/$type
	ScpFileExpect=/search/fangzi/ServiceApp/expect/scp_file.exp

	fileIdx=0
	hostSize=${#NatHostList[@]}
	for urlFile in $(ls $urlFilePath/*_urls); do
		urlFileName=$(basename $urlFile)

		# ����Ҫ�ַ����Ļ���
		dispatchHost=${NatHostList[$fileIdx]}
		$ScpFileExpect $urlFile $dispatchHost:$HostPath/$urlFileName $Passwd
		
		fileIdx=$(( (fileIdx + 1) % $hostSize ))
		LOG "[dispatch url]: $dispatchHost  $urlFile"
	done
	LOG "dispatch $type urls done."
}


function batch_parse_page_imp() {
	type=$1

	# ���ű�������ȥ��ִ�нű�
	LocalPath=/search/fangzi/ServiceApp/Dianping/bin
	HostPath=/search/odin/dianping/
	Script=batch_update_shops_on_host.sh

	ScpFileExpect=/search/fangzi/ServiceApp/expect/scp_file.exp
	ExecuteScriptExpect=/search/fangzi/ServiceApp/expect/execute_script.exp

	for host in ${NatHostList[@]}; do
		LOG "==========  scp & execute  $host ============"
		$ScpFileExpect $LocalPath/$Script $host:$HostPath "$Passwd"
		cmd="sh $Script $type 1>$type.std 2>$type.err &"
		echo "$cmd"
		$ExecuteScriptExpect $host "$HostPath" "$cmd" "$Passwd"
		#echo "$ExecuteScriptExpect $host $HostPath $cmd $Passwd"
		LOG "scp and execute for $host done."
		sleep 2
	done
	LOG "get and parse page on host done."
}


# �ַ�����̨������ȥ��
function batch_parse_page_from_db() {
	$type="play"
	type=$1
	# ɾ�����ַ��Ļ����ϵ�url�ļ�
	cleanPath=/search/odin/dianping/url/$type/
	clean_host_shop_urls $cleanPath

	# �ַ�shop urls���ֲ�ʽ�Ļ�����
	urlFilePath=/search/fangzi/ServiceApp/Dianping/data/$type/url
	#urlFilePath=/search/fangzi/ServiceApp/Dianping/test
	dispatch_shop_urls $urlFilePath $type

	# ����̨������ִ�д���ű�
	batch_parse_page_imp $type
}




function merge_online_urls_imp() {
	onlineUrlFile=$1; scanUrlFile=$2;
	if [ ! -f $onlineUrlFile -o ! -f $scanUrlFile ]; then
		LOG "$onlineUrlFile or $scanUrlFile is not exist"
	fi
	cat $onlineUrlFile $scanUrlFile | awk -F'\t' '{
		if (!($1 in urls)) {
			urls[$1];  print
		}
	}' > $scanUrlFile.merge
	rm -f $scanUrlFile;  mv $scanUrlFile.merge $scanUrlFile
}



# ������
function merge_online_urls() {
	#type="play"
	type=$1

	onlineUrlPath=/search/fangzi/ServiceApp/Dianping/data/$type/onlineUrl
	scanUrlPath=/search/fangzi/ServiceApp/Dianping/data/$type/url
	cityConf=conf/dianping_city_code_pinyin_conf


	while read cityCh cityCode cityEn; do
		scanUrlFile=$scanUrlPath/${cityEn}_urls
		onlineUrlFile=$onlineUrlPath/dianping_${type}_${cityEn}.urls
		merge_online_urls_imp $onlineUrlFile $scanUrlFile
		LOG "merge $city's $type urls"
	done < $cityConf
	LOG "merge all citys $type urls"
}



# ����ץȡ�ĵ���listҳ�����shop urls�ķ�ʽ����
function update_from_list() {
	rm -f data/play/url/*
	rm -f data/play/result/*
	rm -f data/play/failurl/*


	# -1. ��ȡ����shop URLs


	# 0. ��ȡץȡ����ץȡ��URL�б�
	get_play_urls

	# 1. ���ֳ������е�URL�б�
	split_play_urls

	# 2. ɨ�⣬����ҳ��
	get_parse_play_page_from_db
}



# ��ɨ��ķ�ʽ�����������£�ֱ��ɨshop url�ķ�ʽ
function incre_update_from_scan_shopurls() {
	rm -f data/play/url/*
	rm -f data/play/result/*
	rm -f data/play/failurl/*

	# ��ɨ�����������URL���з���
	scanShopTypeUrls=Scan/data/shop_urls.types
	python bin/split_scan_shop_typeurl.py $scanShopTypeUrls play

	# 2. ɨ�⣬����ҳ��
	get_parse_play_page_from_db
}



# ��ɨ��ķ�ʽ����ȫ�����£�ֱ��ɨshop url�ķ�ʽ
function full_update_from_scan_shopurls() {
	#local type="play"
	local type="restaurant"

	rm -f data/$type/url/*
	rm -f data/$type/result/*
	rm -f data/$type/failurl/*

	# ��ɨ�����������URL���з���
	# �ο� bin/filte_city_type_urls.py 
	scanShopTypeUrls=Scan/data/shop_urls.types
	python bin/split_scan_shop_typeurl.py $scanShopTypeUrls $type

	# �����ϴ��ڵ�URL������� ׷�ӵ�����
	merge_online_urls $type

	# 2. ɨ�⣬����ҳ��
	batch_parse_page_from_db $type
}



#incre_update_from_scan_shopurls
#batch_parse_page_from_db

scp_host_result_to_local restaurant

#full_update_from_scan_shopurls

