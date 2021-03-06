#!/bin/bash
#coding=gb2312
# 糯米网团购数据处理

TUAN_URLS="conf/tuan_urls"
TUAN_LOG="log/tuan.log"
TUAN_EXTRACT_CONF="conf/tuan_extract_conf"

. ./bin/Tool.sh


function download_tuan_xml() {
	for url in $(cat $TUAN_URLS); do
		#http://api.nuomi.com/api/dailydeal?version=v1&city=anshan
		output="tmp/"${url##*=}
		wget -O $output $url
		if [ $? -eq 0 ]; then
			INFO "download $url done."
			iconv -futf8 -tgbk -c $output > $output.gbk
		else
			ERROR "download $url failed." >> $TUAN_LOG
		fi
		sleep 1
	done
	LOG "download all tuan xml done."
}


function parse_tuan_xml() {
	for xmlFile in $(ls tmp/*.gbk); do
		python bin/Parser.py -nuomi_tuan $TUAN_EXTRACT_CONF $xmlFile
		INFO "parse [$xmlFile] done."
	done
}

# 将糯米网与大众点评的城市名称不一致进行替换
function change_to_dianpingpinyin() {
	rm -f data/jiangxifuzhou*
	mv data/fuzhou1_shop data/jiangxifuzhou_shop
	mv data/fuzhou1_tuan data/jiangxifuzhou_tuan

	rm -f data/anhuisuzhou*
	mv data/suzhou1_shop data/anhuisuzhou_shop
	mv data/suzhou1_tuan data/anhuisuzhou_tuan

	rm -f data/guangxiyulin*
	mv data/yulin1_shop data/guangxiyulin_shop
	mv data/yulin1_tuan data/guangxiyulin_tuan

	rm -f data/jiangxiyichun*
	mv data/yichun1_shop data/jiangxiyichun_shop
	mv data/yichun1_tuan data/jiangxiyichun_tuan
}


function filte_expired_tuan_result() {
	resultFile=$1
	if [ ! -f $resultFile ]; then
		return
	fi

	today=$(date +%Y-%m-%d)
	awk -F'\t' -v TODAY=$today '{
		if (NF < 3 || $3 < TODAY) { 
			next 
		}
		print
	}' $resultFile > $resultFile.filte
	rm -f $resultFile; mv $resultFile.filte $resultFile;
	LOG "filte expired items for $resultFile done."
}


function get_expired_tuanurls() {
	input=$1;  output=$2

	today=$(date -d "2 months" +%Y-%m-%d)
	awk -F'\t' -v TODAY=$today '{
		tuanUrl=$3; category=$11;  endDate=$NF
		if (!(category~/休闲娱乐/ || category~/美食/)) {
			next
		}
		if (endDate > TODAY) {
			next
		}
		print tuanUrl
	}' $input > $output
	LOG "get expired tuan urls of $input done."
}


# 过滤出过期的团购项，抓取页面测试是否真的过期
function get_expired_tuanitems() {

	for tuanFile in $(ls data/*_tuan); do
		fileName=$(basename $tuanFile)
		city=${fileName/_tuan/}
		expiredUrlFile=expiredtuan/${city}_expired_tuan
		expiredResultFile=${expiredUrlFile}.result

		
		# 计算接入数据中过期的团购URL
		get_expired_tuanurls $tuanFile $expiredUrlFile

:<<EOF
		# 必须抓取页面才知道该团购是否还有效
		# 过滤已经抓取过相关页面的URL,避免重复抓取
		if [ -f $expiredResultFile ]; then
			# 迭代的过程，去除上次抓取页面解析出的已经过期的团购项
			filte_expired_tuan_result $expiredResultFile

			awk -F'\t' 'ARGIND==1 {
				fetchedUrl[$1]	
			} ARGIND==2 {
				if (!($1 in fetchedUrl)) {
					print
				}
			}' $expiredResultFile $expiredUrlFile > $expiredUrlFile.filte
			
			rm -f $expiredUrlFile.bak;  mv $expiredUrlFile $expiredUrlFile.bak;
			mv $expiredUrlFile.filte $expiredUrlFile;
		fi
EOF

		# 如果为空，直接删除
		fileSize=$(ls -l $expiredUrlFile | awk '{print $5}' )
		if [ $fileSize -eq 0 ]; then
			rm -f $expiredUrlFile
		fi
		LOG "get $city's expired tuan items done."
	done
}


# 抓取/解析所谓"过期"的团购项的详情页
function fetch_expired_tuanitems_pages() {
	LOG "fetch & parse nuomi tuan items...."
	
	for expiredFile in $(ls expiredtuan/*_expired_tuan); do
		fileSize=$(ls -l $expiredFile | awk '{print $5}' )
		if [ $fileSize -eq 0 ]; then
			continue
		fi
		output=$expiredFile.result

		/usr/bin/python bin/getTuanExpired.py $expiredFile >> $output
	done

	LOG "fetch & parse all nuomi tuan items done."
}


# 召回实际没有过期的团购items
function recall_noexpired_tuanitems() {
	for tuanFile in $(ls data/*_tuan); do
		fileName=$(basename $tuanFile)
		city=${fileName/_tuan/}
		expiredResultFile=expiredtuan/${city}_expired_tuan.result
		#if [ "$city" != "beijing" ]; then
		#	continue
		#fi

		if [ ! -f $expiredResultFile ]; then
			LOG "$expiredResultFile is not exist, continue"
		fi

		awk -F'\t' 'ARGIND==1 {
			if (NF < 4) { next }
			itemid=$1;  startDate=$2;  endDate=$3; expired=$4;
			gsub(/.*\//, "", itemid)
			if (expired == 1) {
				filterids[itemid] = 1
			} else if (endDate ~ /^[0-9\-]+$/) {
				itemEnd[itemid] = endDate
			}
		} ARGIND==2 {
			if (FNR == 1) {
				for (row=1; row<=NF; row++) {
					if ($row == "id") { idRow = row }
					if ($row == "deadline") { endRow = row }
				}
				print; next
			}
			if ($idRow in filterids) {
				next
			}
			if ($idRow in itemEnd) {
				$endRow = itemEnd[$idRow]
			}
			line = $1
			for (row=2; row<=NF; ++row) {
				line = line "\t" $row
			}
			print line
		}' $expiredResultFile $tuanFile > $tuanFile.recall
		
		rm -f $tuanFile.bak;  mv $tuanFile $tuanFile.bak
		cp $tuanFile.recall $tuanFile
	done
}


function put_2_mergedir() {
	tuanMergePath=/fuwu/Source/Cooperation/Tuan/Input/nuomi

	for tuanFile in $(ls data/*_tuan); do
		rm -f $tuanMergePath/$tuanFile
		cp $tuanFile $tuanMergePath/$(basename $tuanFile)
	done

	for shopFile in $(ls data/*_shop); do
		rm -f $tuanMergePath/$shopFile
		cp $shopFile $tuanMergePath/$(basename $shopFile)
	done
	
	LOG "put tuan/shop files to merge directory done."  >> $TUAN_LOG
}

function main() {
	rm -f tmp/*;  #rm -f data/*
	find ./log/ -ctime +7 | xargs rm -f {}

	# 下载当天的团购信息数据
	download_tuan_xml
	LOG "download all tuan xml done." >> $TUAN_LOG

	# 解析团购shop deal 以及之间的关系
	parse_tuan_xml
	LOG "parse all tuan xml done." >> $TUAN_LOG

	# 处理与大众点评不同的地方
	change_to_dianpingpinyin
	LOG "change to dianping done." >> $TUAN_LOG

	# 计算过期的团购数据
	get_expired_tuanitems
	LOG "get expired tuan items done." >> $TUAN_LOG

	# 抓取所谓过期的团购详情页
	fetch_expired_tuanitems_pages
	LOG "get expired tuan pages done." >> $TUAN_LOG

	# 召回实际没有过期的团购
	recall_noexpired_tuanitems
	LOG "recall expired tuan items done." >> $TUAN_LOG
	
	# 将团购/店铺数据放入Tuan目录下
	put_2_mergedir
}

main
