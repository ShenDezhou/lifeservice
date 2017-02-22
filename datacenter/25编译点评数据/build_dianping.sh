#!/bin/bash
#coding=gb2312

. ./bin/Tool.sh

# ���ڵ�������ʳ(�͹�)���ݴ���
function build_dianping_restaurant() {
:<<EOF
EOF
	rm -f Input/*restaurant_dianping_detail*

	# �ϲ� ����/���/�µ��ļ�
	for cityDir in $(ls Crawler/); do
		for typeDir in $(ls Crawler/$cityDir/); do
			mergeFile=Input/${cityDir}_${typeDir}_dianping_detail
			#echo $mergeFile
			rm -f $mergeFile
			cat Crawler/$cityDir/$typeDir/*dianping_detail* > $mergeFile
			LOG "merge $mergeFile done."
		done
	done

	# ȥ��
	for file in $(ls Input/*restaurant_dianping_detail); do
		uniqRestaurant $file
		LOG "partition for [$file] done."
	done

	# �ָ�ԭʼ����
	for file in $(ls Input/*restaurant_dianping_detail); do
		python bin/ServiceAppPartition.py -partition $file
		LOG "partition for [$file] done."
	done

	# ��һ������
	normConf='conf/dianping_restaurant_norm_conf'
	for file in $(ls Input/*restaurant_dianping_detail.*); do
		python bin/ServiceAppPartition.py -normal $file $normConf
		LOG "normalize for [$file] done."
	done

	# ת���б����ʽ֮ǰ��Ҫ���⴦��(���ۺ��Ƽ���)
	# һ��url��Ӧ��ʵ�������
	for file in $(ls Input/*restaurant_dianping_detail.recomfood.norm); do
		preHandle $file
	done
	for file in $(ls Input/*restaurant_dianping_detail.comment.norm); do
		preHandle $file
	done

	# ת�ɱ��ʽ
	for file in $(ls Input/*restaurant_dianping_detail.*.norm); do
		python bin/ServiceAppPartition.py -table $file
		LOG "transfer to table format for [$file] done."
	done
	
}


# Ԥ�������������� 1.vs.������
function preHandle() {
	input=$1; 
	awk -F'\t' '{
		key=$1;  val=$2;
		if (key == "url") { url = val; }
		if (key == "title") { title = val; }
		if (key == "userName" || key == "recommFood") {
			print "url\t"url;
			print "title\t"title;
		}
		print
	}' $input > $input.add
	rm -f $input.bak; 
	mv -f $input $input.bak
	mv $input.add $input
	LOG "add url/title info for [$input] done."
}


# ȥ��
function uniqRestaurant() {
	input=$1; output=$1.uniq
	awk -F'\t' 'BEGIN {
		filteFlag = 0;
		lastItemLines = "";
	}
	function printLastItem(lines){
		if (lines != "") {
			print lines
		}
	}
	{
		key=$1;  val=$2;
		if (key == "url") {
			url = val;
			# �Ƿ���Ҫ����
			if (filteFlag == 0) {
				printLastItem(lastItemLines)
				lastItemLines = "";
			}
			filteFlag = 0;
			# ����ǰurl�Ѿ�����
			if (url in existUrl) {
				filteFlag = 1;
			}
			existUrl[url] = 1
			lastItemLines = $0
		} else {
			lastItemLines = lastItemLines "\n" $0
		}
	} END {
		if (filteFlag == 0) {
			printLastItem(lastItemLines)
		}
	}' $input > $output
	rm -f ${input}_raw;
	mv $input ${input}_raw
	mv $output $input

	LOG "uniq [$input] done."
}


# Ϊ��ʳ��ʵ�����ID
# ��Ҫ��ÿ�����е���ʳ��� baseinfo; recomfood; comment; tuan �ĸ��ļ����ID
# �˺�����Ҫ�������
function updateRestaurantID() {
	URL_ID_CONF="conf/restaurant_url_id_conf"
	URL_ID_CONF_UPDATE="conf/restaurant_url_id_conf.update"
	filePrefix=$1

	# Ϊ������Ϣ�����ID���Ѵ���ID��URL��ȡ����URL��ӦID����Сֵ
	baseinfoFile=${filePrefix}.baseinfo.table
	awk -F'\t' 'BEGIN {
		MAXID = 1; URLROW = -1; 
	} ARGIND == 1 {
		url=$1; id=$2
		urlIDMap[url] = id
		MAXID = (id > MAXID) ? id : MAXID
	} ARGIND == 2 {
		# ���ID�ֶΣ��ҵ�URL������
		if (FNR == 1) {
			print "id\t" $0
			for (row=1; row<=NF; ++row) {
				if ($row == "url") {
					URLROW = row; break;
				}
			}
		} else {
			# ���URL�Ƿ��Ѿ��ж�ӦID
			if ($URLROW == "") {
				next
			}

			curUrlID = MAXID + 1;
			urlLen = split($URLROW, urlArray, "@@@")
			for (idx=1; idx<=urlLen; idx++) {
				tmpUrl = urlArray[idx]
				if (tmpUrl in urlIDMap && urlIDMap[tmpUrl] < curUrlID) {
					curUrlID = urlIDMap[tmpUrl]
				}
			}
			
			# ����URL��������ӳ��ID
			if (curUrlID == MAXID + 1) {
				MAXID += 1
			}
			print curUrlID "\t" $0

			# ����URL��Ӧ��ID
			for (idx=1; idx<=urlLen; idx++) {
				tmpUrl = urlArray[idx]
				urlIDMap[tmpUrl] = curUrlID
			}
		}
	} END {
		# ����url-id�����ļ�
		for (url in urlIDMap) {
			print url "\t" urlIDMap[url] > "'$URL_ID_CONF_UPDATE'"
		}
	}' $URL_ID_CONF $baseinfoFile > $baseinfoFile.id
	LOG "add id for [$baseinfoFile] done. output is [$baseinfoFile.id] "
	

	# Ϊ�Ƽ������ID��������ֶ�
	recomfoodFile=${filePrefix}.recomfood.table
	awk -F'\t' 'BEGIN {
		recomfoodID = 0; urlRow = -1;
	} ARGIND == 1 {
		url = $1;  id = $2;
		urlIDMap[url] = id;	
	} ARGIND == 2 {
		if (FNR == 1) {
			# ���id�ֶΣ�����Ƽ����ֶγɶ�����ֶ�
			print "recomfoodid\tresid\tresUrl\tresName\trecommUrl\trecommName\trecommCount\trecommPhoto\trecommPrice"
			for (row=1; row<=NF; ++row) {
				if ($row == "url") {
					urlRow = row; break;
				}
			}
		} else {
			resUrl = $urlRow
			if (!(resUrl in urlIDMap)) {
				next
			}
			gsub("@@@", "\t", $0)
			print (++recomfoodID) "\t" urlIDMap[resUrl] "\t" $0
		}
	}' $URL_ID_CONF_UPDATE $recomfoodFile > $recomfoodFile.id
	LOG "update tuanid for [$recomfoodFile] to [$recomfoodFile.id] done."


	# Ϊ���ۣ��Ƽ��ˣ��Ź���Ϣ���ID
	commentFile=${filePrefix}.comment.table
	awk -F'\t' 'BEGIN {
		commentID = 0; urlRow = -1;
	} ARGIND == 1 {
		url = $1;  id = $2;
		urlIDMap[url] = id;	
	} ARGIND == 2 {
		if (FNR == 1) {
			print "commentid\tresid\t" $0
			for (row=1; row<=NF; ++row) {
				if ($row == "url") {
					urlRow = row; break;
				}
			}
		} else {
			resUrl = $urlRow
			if (!(resUrl in urlIDMap)) {
				next
			}
			print (++commentID) "\t" urlIDMap[resUrl] "\t" $0
		}
	}' $URL_ID_CONF_UPDATE $commentFile > $commentFile.id
	LOG "update tuanid for [$commentFile] to [$commentFile.id] done."


	# Ϊ�Ź���Ϣ���ID
	tuanFile=${filePrefix}.tuan.table
	awk -F'\t' 'BEGIN {
		tuanID = 0; urlRow = -1; tuanRow = -1;
	} ARGIND == 1 {
		url = $1;  id = $2;
		urlIDMap[url] = id;	
	} ARGIND == 2 {
		if (FNR == 1) {
			print "tuanid\tresid\tsite\ttype\turl\ttitle\tphoto\tprice\tvalue\tsell"
			for (row=1; row<=NF; ++row) {
				if ($row == "url") {
					urlRow = row;
				} else if ($row == "tuanInfo") {
					tuanRow = row;
				}
			}
		} else {
			resUrl = $urlRow; tuanInfo = $tuanRow;
			if (!(resUrl in urlIDMap) || tuanInfo=="") {
				next
			}
			tuanLen = split(tuanInfo, tuanInfoArr, "###")
			for (i=1; i<=tuanLen; i++) {
				info = tuanInfoArr[i]
				gsub("@@@", "\t", info)
				if(info~/^��\t/) {
					continue
				}
				print (++tuanID) "\t" urlIDMap[resUrl] "\t���ڵ���\t" info
			}
		}
	}' $URL_ID_CONF_UPDATE $tuanFile > $tuanFile.id
	LOG "update tuanid for [$tuanFile] to [$tuanFile.id] done."

	# Ϊͼ�����ID
	photosetFile=${filePrefix}.photoset.table
	awk -F'\t' 'BEGIN {
		photosetID = 0; urlRow=-1; psetRow=-1;  cPsetRow=-1;
	} ARGIND == 1 {
		url = $1;  id = $2;
		urlIDMap[url] = id;	
	} ARGIND == 2 {
		if (FNR == 1) {
			print "psetid\tresid\tresurl\tphotoset"
			for (row=1; row<=NF; ++row) {
				if ($row == "url") {
					urlRow = row;
				} else if ($row == "photoSet") {
					psetRow = row;
				} else if ($row == "conditionPhotoSet") {
					cPsetRow = row;
				}
			}
		} else {
			resUrl = $urlRow; photoset = $psetRow; cphotoset = $cPsetRow;
			if (!(resUrl in urlIDMap) || (photoset=="" && cphotoset=="")) {
				next
			}
			# ȥ���������˵��
			len = split(cphotoset, cphotosetArray, ",")
			cphotoset = "";
			for (i=1; i<=len; i++) {
				sublen = split(cphotosetArray[i], array, "@@@")
				if (sublen < 2) { continue; }
				if (cphotoset == "") {
					cphotoset = array[2]
				} else {
					cphotoset = cphotoset "," array[2]
				}
			}

			# �ϲ�ͼ���뻷��ͼ������
			if (photoset == "") {
				photoset = cphotoset
			} else {
				photoset = photoset "," cphotoset
			}
			print (++photosetID) "\t" urlIDMap[resUrl] "\t" photoset
		}
	}' $URL_ID_CONF_UPDATE $photosetFile > $photosetFile.id
	LOG "update photosetid for [$photosetFile] to [$photosetFile.id] done."



	# ����url-id�����ļ�
	oldConfModifyTime=$(ls -l $URL_ID_CONF | awk '{time=$6""$7; gsub(/[\-\.:]/, "", time); print time;}')
	newConfModifyTime=$(ls -l $URL_ID_CONF_UPDATE | awk '{time=$6""$7; gsub(/[\-\.:]/, "", time); print time;}')
	oldConfSize=$(ls -l $URL_ID_CONF | awk '{size=$5; print size;}')
	newConfSize=$(ls -l $URL_ID_CONF_UPDATE | awk '{size=$5; print size;}')
	# ʱ���и��£��ļ���С����
	if [ $newConfModifyTime -gt $oldConfModifyTime -a $newConfSize -ge $oldConfSize ]; then
		destFile=$(basename $URL_ID_CONF).$(nowStr)
		#echo $destFile
		mv -f $URL_ID_CONF history/conf/$destFile
		mv -f $URL_ID_CONF_UPDATE $URL_ID_CONF
		LOG "update [$URL_ID_CONF] file done."
	fi
}


function updateAllRestaurantID() {
	# �ϲ� ����/���/�µ��ļ�
	for cityDir in $(ls Crawler/); do
		restaurantFile="Input/${cityDir}_restaurant_dianping_detail"
		updateRestaurantID $restaurantFile
	done

	#updateRestaurantID "Input/beijing_restaurant_dianping_detail"
	#updateRestaurantID "Input/shanghai_restaurant_dianping_detail"

}



# ������õ�table��ʽ�ļ��ַ�����ͬĿ¼��
# ��Ҫ��֤�����ļ��ĸ�ʽΪ  city_type_filename  ���ϸ�ĸ�ʽ
function dispatch() {
	for srcFile in $(ls Input/*.table.id); do
		basename=$(basename $srcFile)
		destFile=$(echo $basename | awk '{gsub(".id", "", $1); sub("_", "/", $1); sub("_", "/", $1); print "Output/"$1}')
		destPath=$(dirname $destFile)
		if [ ! -d $destPath ]; then
			LOG "[Info]: $destPath is not exist, make it"
			mkdir -p $destPath
		fi
		rm -f $destFile;  cp -f $srcFile $destFile;

		LOG "copy [$srcFile] to [$destFile] done."
	done
	LOG "dispatch done."
}







function main() {
	# ���ڵ�����ʳ���ݴ���
	# build_dianping_restaurant

	# �ϲ�����

	# �����˹���Ӫ�Ĳ���

	# ����ʵ��ID
	 updateAllRestaurantID

	# �ַ���ָ��Ŀ¼�£����ڽ�����
	 dispatch

	# ��mysql���ݿ�
	
}

main

function testF() {
	awk -F'\t' 'BEGIN {
		photosetID = 0; urlRow=-1; psetRow=-1;  cPsetRow=-1;
	} ARGIND == 1 {
		url = $1;  id = $2;
		urlIDMap[url] = id;	
	} ARGIND == 2 {
		if (FNR == 1) {
			print "psetid\tresid\tresurl\tphotoset"
			for (row=1; row<=NF; ++row) {
				if ($row == "url") {
					urlRow = row;
				} else if ($row == "photoSet") {
					psetRow = row;
				} else if ($row == "conditionPhotoSet") {
					cPsetRow = row;
				}
			}
		} else {
			resUrl = $urlRow; photoset = $psetRow; cphotoset = $cPsetRow;
			if (!(resUrl in urlIDMap) || (photoset=="" && cphotoset=="")) {
				next
			}
			# ȥ���������˵��
			len = split(cphotoset, cphotosetArray, ",")
			#print len
			cphotoset = "";
			for (i=1; i<=len; i++) {
				subLen = split(cphotosetArray[i], array, "@@@")
				if (subLen < 2) { continue; }
				if (cphotoset == "") {
					cphotoset = array[2]
				} else {
					cphotoset = cphotoset "," array[2]
				}
			}
			#print cphotoset

			#print photoset
			# �ϲ�ͼ���뻷��ͼ������
			if (photoset == "") {
				photoset = cphotoset
			} else {
				photoset = photoset "," cphotoset
			}

			print (++photosetID) "\t" urlIDMap[resUrl] "\t" photoset
		}
	}' conf/restaurant_url_id_conf Input/xian_restaurant_dianping_detail.photoset.table > zz

}

