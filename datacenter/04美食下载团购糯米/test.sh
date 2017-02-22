#!/bin/bash
#coding=gb2312
# Ŵ�����Ź����ݴ���

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
			INFO "download $url done." >> $TUAN_LOG
			iconv -futf8 -tgbk -c $output > $output.gbk
		else
			ERROR "download $url failed." >> $TUAN_LOG
		fi
		sleep 1
	done
	LOG "download all tuan xml done." >> $TUAN_LOG
}


function parse_tuan_xml() {
	for xmlFile in $(ls tmp/*.gbk); do
		python bin/Parser.py -nuomi_tuan $TUAN_EXTRACT_CONF $xmlFile
		INFO "parse [$xmlFile] done." >> $TUAN_LOG
	done
}

# ��Ŵ��������ڵ����ĳ������Ʋ�һ�½����滻
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

	today=$(date +%Y-%m-%d)
	awk -F'\t' -v TODAY=$today '{
		tuanUrl=$3; category=$11;  endDate=$NF
		if (!(category~/��������/ || category~/��ʳ/)) {
			next
		}
		if (endDate > TODAY) {
			next
		}
		print tuanUrl
	}' $input > $output
	LOG "get expired tuan urls of $input done."
}


# ���˳����ڵ��Ź��ץȡҳ������Ƿ���Ĺ���
function get_expired_tuanitems() {

	for tuanFile in $(ls data/*_tuan); do
		fileName=$(basename $tuanFile)
		city=${fileName/_tuan/}
		expiredUrlFile=expiredtuan/${city}_expired_tuan
		expiredResultFile=${expiredUrlFile}.result

		
		# ������������й��ڵ��Ź�URL
		get_expired_tuanurls $tuanFile $expiredUrlFile
		
		# �����Ѿ�ץȡ�����ҳ���URL,�����ظ�ץȡ
		if [ -f $expiredResultFile ]; then
			# �����Ĺ��̣�ȥ���ϴ�ץȡҳ����������Ѿ����ڵ��Ź���
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


		# ���Ϊ�գ�ֱ��ɾ��
		fileSize=$(ls -l $expiredUrlFile | awk '{print $5}' )
		if [ $fileSize -eq 0 ]; then
			rm -f $expiredUrlFile
		fi
		LOG "get $city's expired tuan items done."
	done
}


# ץȡ/������ν"����"���Ź��������ҳ
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


# �ٻ�ʵ��û�й��ڵ��Ź�items
function recall_noexpired_tuanitems() {
		city="beijing"
		tuanFile=data/beijing_tuan
		expiredResultFile=expiredtuan/${city}_expired_tuan.result

		if [ ! -f $expiredResultFile ]; then
			LOG "$expiredResultFile is not exist, continue"
		fi
		
		awk -F'\t' 'ARGIND==1 {
			if (NF < 3 || $3 !~ /^[0-9\-]+$/) {
				next
			}
			itemid=$1;  startDate=$2;  endDate=$3;
			gsub(/.*\//, "", itemid)
			itemEnd[itemid] = endDate
		} ARGIND==2 {
			if (FNR == 1) {
				for (row=1; row<=NF; row++) {
					if ($row == "id") { idRow = row }
					if ($row == "deadline") { endRow = row }
				}
				print; next
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
		
		#rm -f $tuanFile.bak;  mv $tuanFile $tuanFile.bak
		#cp $tuanFile.recall $tuanFile
}



function main() {
	rm -f tmp/*;  #rm -f data/*
	find ./log/ -ctime +7 | xargs rm -f {}

	# ���ص�����Ź���Ϣ����
	download_tuan_xml
	# �����Ź�shop deal �Լ�֮��Ĺ�ϵ
	parse_tuan_xml
	# ��������ڵ�����ͬ�ĵط�
	change_to_dianpingpinyin
	# ������ڵ��Ź�����
	get_expired_tuanitems
	# ץȡ��ν���ڵ��Ź�����ҳ
	fetch_expired_tuanitems_pages
	# �ٻ�ʵ��û�й��ڵ��Ź�
	recall_noexpired_tuanitems
	
}


#main
recall_noexpired_tuanitems
