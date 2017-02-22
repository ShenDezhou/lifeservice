#!/bin/bash
#coding=gb2312

# �ϲ����ڵ�������ʳ������Ŵ���Ź�������
# ע�⣡������ ��ͬ�̼Ҷ��ڳ������������ƵĹ�һ����Ҫ����
#			   �����޷�Ӧ�õ��ϲ�������� ������ͬ �����Ҫ����


. ./bin/Tool.sh

DIANPING_DIR="Input"
NUOMI_TUAN_DIR="/search/zhangk/Fuwu/Source/Cooperation/Nuomi/data/"


# ���ڵ���������ʳ��������
function extract_dianping_restaurant() {
	input=$1; output=$2;
	awk -F'\t' 'BEGIN {
		idRow=-1; urlRow=-1; titleRow=-1; poiRow=-1;
		addrRow=-1; telRow=-1; areaRow=-1;
	}{
		if (FNR == 1) {
			for(row=1; row<=NF; row++) {
				if ($row == "id"){ idRow = row;}
				else if ($row == "url") { urlRow= row;}
				else if ($row == "title") { titleRow = row;}
				else if ($row == "poi") { poiRow = row;}
				else if ($row == "address") { addrRow = row;}
				else if ($row == "tel") { telRow = row;}
				else if ($row == "area") { areaRow = row;}
			}
			next
		}
		if (NF < 10 ) {
			next
		}
		id=$idRow; url=$urlRow; title=$titleRow; 
		poi=$poiRow; addr=$addrRow; tel=$telRow; area=$areaRow; 
		# ��һ�� title  tel addr
		gsub(/\([^\)]+\)/, "", title);
		gsub(/��[^��]+��/, "", title);

		gsub("-", "", tel);
		gsub(",", "|", tel);
		
		# ���area Ϊ��
		if (area == "") {
			addrLen = split(addr, addrList, " ")
			if (addrLen > 0 && addrList[1]~/.*��$/ && length(addrList[1]) <= 5) {
				area = addrList[1]
			}
		}

		gsub(area, "", addr)
		gsub(/\([^\)]+\)/, "", addr);
		gsub(/��[^��]+��/, "", addr);

		print id"\t"url"\t"title"\t"tel"\t"area"\t"addr"\t"poi
	}' $input > $output
	LOG "extract dianping restaurant info of [$input] done. [$output]"
}



# Ŵ���Ź��漰���ĵ�����Ϣ
function extract_nuomi_restaurant() {
	input=$1;  output=$2
	# ֻȡ��ʳ�� && ������Ϊ��
	awk -F'\t' 'BEGIN {
		titleRow=-1; telRow=-1; cityRow=-1; areaRow=-1; 
		addrRow=-1; poiRow=-1; categoryRow=-1; 
	}{
		if (FNR == 1) {
			for(row=1; row<=NF; row++) {
				if ($row == "name"){ titleRow = row; continue }
				if ($row == "tel"){ telRow = row; continue }
				if ($row == "city"){ cityRow = row; continue }
				if ($row == "area"){ areaRow = row; continue }
				if ($row == "address"){ addrRow = row; continue }
				if ($row == "poi"){ poiRow = row; continue }
				if ($row == "firstCategory"){ categoryRow = row; continue }
			}
			next
		}
		# ���˷ǲ͹�����Ź�
		if ($categoryRow != "��ʳ" || $areaRow == "") {
			next
		}

		title=$titleRow;  tel=$telRow; area=$areaRow; 
		addr=$addrRow;  poi=$poiRow;

		id = area "@" title "@" poi;  url = "http://nuomi.com/"id
		# ��һ��title addr
		gsub(/\([^\)]+\)/, "", title);
		gsub(/��[^��]+��/, "", title);
		
		# ��һ����ַ, ȥ�� **�� �Լ���������Ķ���
		gsub(/^[^��]+��/, "", addr)
		gsub(area, "", addr)
		gsub(/\([^\)]+\)/, "", addr);
		gsub(/��[^��]+��/, "", addr);

		print id"\t"url"\t"title"\t"tel"\t"area"\t"addr"\t"poi
	}' $input > $output
	LOG "extract nuomi restaurant info of [$input] done. [$output]"

}


#37592   http://www.dianping.com/shop/22510919   101������   01084031188 ������  ������ �������ǽ����ڶ����101��    39.94111,116.4117

function merge_restaurant() {
	nuomiData=$1;  dianpingData=$2; mergeData=$3;

	#uniq nuomi_data
	sort -t$'\t' -k1,1 $nuomiData | uniq > $nuomiData.uniq
	cat $nuomiData.uniq $dianpingData > $mergeData

	# ������ͬ��������ͬ���绰,��ַ,poi���������
	# ��ӡ��ͷ
	echo -e "id\turl\ttitle\ttel\tarea\taddr\tpoi" > $mergeData.title.sort
	sort -t$'\t' -k5,5 -k3,3  $mergeData >> $mergeData.title.sort

	# ������ͬ���绰��ͬ  (��������)
	echo -e "id\turl\ttitle\ttel\tarea\taddr\tpoi" > $mergeData.tel.sort
	awk -F'\t' '{
		tel = $4;
		len = split(tel, telArr, "|")
		# ���绰�ָ��ÿ������һ��
		for (i=1; i<=len; ++i) {
			$4 = telArr[i]
			line = $1
			for(j=2; j<=NF; j++) {
				line = line "\t" $j
			}
			print line
		}
	}' $mergeData | sort -t$'\t' -k5,5 -k4,4 >> $mergeData.tel.sort
	LOG "merge for [$dianpingData] and [$nuomiData] done. output=[$mergeData]"
}


function filte_invalid_equal() {
	equalFile=$1;
	awk -F'\t' 'ARGIND==1{
		nuomiID=$2;  dianpingID=$3;
		nuomiIDNum[nuomiID]++
	} ARGIND ==2 {
		nuomiID=$2;  dianpingID=$3;
		if (nuomiIDNum[nuomiID] > 1) {
			next
		}
		print nuomiID"\t"dianpingID
	}' $equalFile $equalFile
	LOG "filte invalid equal items for [$equalFile] done."
}


# ��һ�汾���Ȱ����ظ��ĺϲ�ȥ��
# �ڶ��棺 ѡ���������� ���ߵ�ַ��ӽ���
function merge_tuan() {
	equalFile=$1;  dpTuan=$2; nmTuan=$3; nmShop=$4;
	# equalFile <nmID  dpID>
	# dpTuan <tuanid  resid  site  type    url     title   photo   price   value   sell>
	# nmTuan <id,url,businessTitle,title,value,price,bought,site,image,city,firstCategory,secondCategory,startTime,endTime>
	# nmShop <name, tel, area, address, poi, firstCategory, tuanid>

	awk -F'\t' 'BEGIN {
		# ��ʼ���������Ҫ
		dpMaxTuanID = 0;
	} ARGIND == 1 {
		# Ŵ��������� shop id ӳ��
		nmID=$1;  dpID=$2;
		mergeIDMap[nmID] = dpID
	} ARGIND == 2 {
		# Ŵ�������Ź���Ϣ
		type = "��"
		id=$1; url=$2; title=$4; value=$5; price=$6; bought=$7; site=$8; image=$9;
		nmTuanMap[id] = site "\t" type "\t" url "\t" title "\t" image "\t" price "\t" value "\t" bought
	} ARGIND == 3 {
		if (FNR == 1) {
			for(row=1; row<=NF; row++) {
				if ($row == "name") { titleRow = row; continue}
				if ($row == "area") { areaRow = row; continue}
				if ($row == "poi") { poiRow = row; continue}
				if ($row == "tuanid") { tuanidRow = row; continue}
			}
			next
		}

		# Ŵ��shop id��tuan id��ӳ��
		title=$titleRow;  area=$areaRow;  poi=$poiRow;  tuanID=$tuanidRow;
		# Ŵ��shop id�����tuan id��ӳ��
		#title=$1;  area=$3;  poi=$5;  tuanID=$NF;
		shopID = area "@" title "@" poi;
		if (!(shopID in nmShopTuanIDMap)) {
			nmShopTuanIDMap[shopID] = tuanID
		} else {
			nmShopTuanIDMap[shopID] = nmShopTuanIDMap[shopID] "@@@" tuanID
		}
	} ARGIND == 4 {
		if (NF < 5) {
			next
		}
		# ��ȡ��ǰ�Ź���Ϣ�����ID
		tuanID = $1;
		if (tuanID == "tuanid") {
			next
		}
		if (tuanID > dpMaxTuanID) {
			dpMaxTuanID = tuanID;
		}
	} END {
		for (nmShopID in nmShopTuanIDMap) {
			if (!(nmShopID in mergeIDMap)) {
				continue
			}
			dpID = mergeIDMap[nmShopID]

			tuanIDs = nmShopTuanIDMap[nmShopID]
			tuanIDLen = split(tuanIDs, tuanIDArray, "@@@")
			for (i=1; i<=tuanIDLen; i++) {
				tuanID = tuanIDArray[i]
				if (!(tuanID in nmTuanMap)) {
					continue
				}
				nmTuanInfo = nmTuanMap[tuanID]
				print (++dpMaxTuanID) "\t" dpID "\t" nmTuanInfo
			}
		}
	}' $equalFile $nmTuan $nmShop $dpTuan

	LOG "merge tuan file for restaurant done."
}


# ȥ���ظ����Ź���Ϣ
function uniq_tuan() {
	input=$1;
	# title: �ٶ�Ŵ�׵��Ż�ȯ
	# title���ٶ�Ŵ�׵�ԭ�ۣ��ۼۣ����� float->int
	awk -F'\t' 'BEGIN {
		siteRow=-1; titleRow=-1; priceRow=-1; valueRow=-1;
	} {
		if (FNR == 1) {
			for (row=1; row<=NF; ++row) {
				if ($row == "site") { siteRow = row; continue }
				if ($row == "title") { titleRow = row; continue }
				if ($row == "price") { priceRow = row; continue }
				if ($row == "value") { valueRow = row; continue }
			}
			print
		} else {
			if ($siteRow == "�ٶ�Ŵ��") {
				if ($titleRow~/����ȯ/) {
					$titleRow = "����ȯ";
				}
				gsub(/\.0$/, "", $priceRow)
				gsub(/\.0$/, "", $valueRow)
			}
			line = $1;
			for (row=2; row<=NF; ++row) {
				line = line "\t" $row
			}
			print line
		}
	}' $input.merge > $input.uniq
	mv $input $input.bak
	mv $input.uniq $input
	LOG "unique tuan file [$input] done. output is [$input]"

}

# �ַ����ݵ�Output��
function dispatch() {
	for cityDir in $(ls $DIANPING_DIR/); do
		typeDir="restaurant"
		if [ "$cityDir" == "movie" ]; then
			LOG "movie dir, continue."
			continue
		fi

		for srcFile in $(ls $DIANPING_DIR/$cityDir/$typeDir/*.table); do
			destFile=${srcFile/Input/Output}
			destDir=$(dirname $destFile)
			if [ ! -d $destDir ]; then
				mkdir -p $destDir
			fi
			mv $destFile $destFile.bak
			cp $srcFile $destFile
		done

		LOG "dispatch data for $cityDir city done."
	done
}



function main() {
	# ����ֻ������ʳ�Ź��ĺϲ�
	for cityDir in $(ls $DIANPING_DIR/); do
		typeDir="restaurant"
		if [ "$cityDir" = "movie" ]; then
			LOG "movie dir, continue."
			continue
		fi

		dianpingShopFile=$DIANPING_DIR/$cityDir/$typeDir/dianping_detail.baseinfo.table
		dianpingTuanFile=$DIANPING_DIR/$cityDir/$typeDir/dianping_detail.tuan.table
		dianpingExtractData="tmp/${cityDir}_dianping_data"
		extract_dianping_restaurant $dianpingShopFile $dianpingExtractData
		

		nuomiShopFile=$NUOMI_TUAN_DIR/${cityDir}_shop
		nuomiTuanFile=$NUOMI_TUAN_DIR/${cityDir}_tuan
		nuomiExtractData="tmp/${cityDir}_nuomi_data"
		if [ ! -f $nuomiShopFile ]; then
			LOG "$nuomiShopFile not exist, continue."
			continue
		fi
		extract_nuomi_restaurant $nuomiShopFile $nuomiExtractData
		
		mergeData="tmp/${cityDir}_merge_data"
		 merge_restaurant $nuomiExtractData $dianpingExtractData $mergeData

		# �����ܹ�����֮ǰ�ϲ��Ľ����������������������

		# ��һ���õ�������ļ������ںϲ�
		telEqual=$mergeData.tel.equal;  titleEqual=$mergeData.title.equal;
		python bin/ServiceAppRestaurantMerger.py -title $mergeData.title.sort > $titleEqual
		python bin/ServiceAppRestaurantMerger.py -tel $mergeData.tel.sort > $telEqual
		LOG "apply merge strategy done."
		
		mergeEqual="tmp/${cityDir}.equal"
		filte_invalid_equal $telEqual > $mergeEqual
		filte_invalid_equal $titleEqual >> $mergeEqual
		LOG "filte invalid merge equal pairs done. [$mergeEqual]"
		
		# �ϲ��Ź���Ϣ
		cat $dianpingTuanFile > $dianpingTuanFile.merge
		merge_tuan $mergeEqual $dianpingTuanFile $nuomiTuanFile $nuomiShopFile >> $dianpingTuanFile.merge
		
		# ȥ���ظ����Ź���Ϣ
		uniq_tuan $dianpingTuanFile
		

		LOG "handle $cityDir city's tuan merge done."
	done


	# �ַ���OutputĿ¼��
	dispatch
}

#���ﲻ�ٺϲ��Ź�������
#main


# �ַ���OutputĿ¼��
dispatch


