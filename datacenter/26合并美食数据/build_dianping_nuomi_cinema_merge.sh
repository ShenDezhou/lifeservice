#!/bin/bash
#coding=gb2312

# �ϲ����ڵ�����ӰԺ��Ŵ���Ź���ӰԺ��Ϣ
# ע�⣡������ ��ͬ�̼Ҷ��ڳ������������ƵĹ�һ����Ҫ����
#			   �����޷�Ӧ�õ��ϲ�������� ������ͬ �����Ҫ����


. ./bin/Tool.sh

VR_CINEMA_DIR="Input"
NUOMI_TUAN_DIR="/search/zhangk/Fuwu/Source/Cooperation/Nuomi/data/"


# ���ڵ���������ʳ��������
function extract_vr_cinema() {
	input=$1; output=$2;
	awk -F'\t' 'BEGIN {
		idRow=-1; titleRow=-1; poiRow=-1;
		addrRow=-1; cityRow=-1; areaRow=-1;
		domain="http://www.vr.com/"
	}{
		if (FNR == 1) {
			for(row=1; row<=NF; row++) {
				if ($row == "id"){ idRow = row;}
				else if ($row == "title") { titleRow = row;}
				else if ($row == "poi") { poiRow = row;}
				else if ($row == "address") { addrRow = row;}
				else if ($row == "city") { cityRow = row;}
				else if ($row == "district") { areaRow = row;}
			}
			next
		}
		if ($cityRow == "" || $areaRow == "") {
			next
		}

		id=$idRow; title=$titleRow; city=$cityRow;
		poi=$poiRow; addr=$addrRow; area=$areaRow; 
		
		# ��һ�� area title  tel addr
		# area:  ������;����
		if (area~/;/) {
			len = split(area, areaArray, ";")
			area = areaArray[1]
		}

		gsub("��", "", title);
		gsub("��", "", title);

		#gsub("-", "", tel);
		#gsub(",", "|", tel);
		
		gsub(area, "", addr)
		gsub(/\([^\)]+\)/, "", addr);
		gsub(/��[^��]+��/, "", addr);

		print id"\t"domain"\t"title"\t"city"\t"area"\t"addr"\t"poi
	}' $input > $output
	LOG "extract cinema info of [$input] done. [$output]"
}



# Ŵ���Ź��漰���ĵ�����Ϣ
function extract_nuomi_cinema() {
	input=$1;  output=$2
	# ֻȡ��ʳ�� && ������Ϊ��
	awk -F'\t' 'BEGIN {
		titleRow=-1; cityRow=-1; areaRow=-1; 
		addrRow=-1; poiRow=-1; categoryRow=-1;
		domain = "http://www.nuomi.com/"
	}{
		if (FNR == 1) {
			for(row=1; row<=NF; row++) {
				if ($row == "name"){ titleRow = row; continue }
				#if ($row == "tel"){ telRow = row; continue }
				if ($row == "city"){ cityRow = row; continue }
				if ($row == "area"){ areaRow = row; continue }
				if ($row == "address"){ addrRow = row; continue }
				if ($row == "poi"){ poiRow = row; continue }
				if ($row == "secondCategory"){ categoryRow = row; continue }
			}
			next
		}
		# ���˷ǲ͹�����Ź�
		if ($categoryRow != "��Ӱ" || $areaRow == "") {
			next
		}

		title=$titleRow; area=$areaRow; 
		addr=$addrRow;  poi=$poiRow; city=$cityRow;
		id = area "@" title "@" poi;

		# ��һ��title addr
		gsub("��", "", title);
		gsub("��", "", title);
		
		# ��һ����ַ, ȥ�� **�� �Լ���������Ķ���
		citySubStr = city"��"
		#gsub(/^[^��]+��/, "", addr)
		gsub(citySubStr, "", addr)
		gsub(area, "", addr)
		gsub(/\([^\)]+\)/, "", addr);
		gsub(/��[^��]+��/, "", addr);

		print id"\t"domain"\t"title"\t"city"\t"area"\t"addr"\t"poi
	}' $input > $output
	LOG "extract nuomi cinema info of [$input] done. [$output]"

}


# id  title  city  area addr  poi
# ������@��ͼ��ӰԺ@39.9489,116.3307  ��ͼ��ӰԺ  ����    ������  �йش��ϴ��33�Ź���ͼ�����    39.9489,116.3307

function merge_cinema() {
	nuomiData=$1;  vrData=$2;  mergeData=$3;

	#uniq nuomi_data
	sort -t$'\t' -k1,1 $nuomiData | uniq > $nuomiData.uniq
	cat $nuomiData.uniq $vrData > $mergeData

	# ������ͬ��������ͬ���绰,��ַ,poi���������
	# ��ӡ��ͷ
	echo -e "id\turl\ttitle\tcity\tarea\taddr\tpoi" > $mergeData.title.sort
	sort -t$'\t' -k4,4 -k5,5 -k3,3  $mergeData >> $mergeData.title.sort

	echo -e "id\turl\ttitle\tcity\tarea\taddr\tpoi" > $mergeData.addr.sort
	sort -t$'\t' -k6,6 -k4,4  $mergeData >> $mergeData.addr.sort

:<<EOF
	# ������ͬ���绰��ͬ  (��������)
	echo -e "id\turl\ttitle\tcity\tarea\taddr\tpoi" > $mergeData.tel.sort
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
EOF
	LOG "merge for [$vrData] and [$nuomiData] done. output=[$mergeData]"
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
	equalFile=$1; nmTuan=$2; nmShop=$3;
	# equalFile <nmID  vrID>
	# nmTuan <id,url,businessTitle,title,value,price,bought,site,image,city,firstCategory,secondCategory,startTime,endTime>
	# nmShop <name, tel, city, area, address, poi, firstCategory, secondCategory, tuanid>

	awk -F'\t' 'BEGIN {
		# ��ʼ���������Ҫ
		cinemaTuanID = 0;
	} ARGIND == 1 {
		# Ŵ����VRӰԺIDӳ��
		nmID=$1;  vrID=$2;
		mergeIDMap[nmID] = vrID
	###### print nmID "\t" vrID
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
		shopID = area "@" title "@" poi;
		if (!(shopID in nmShopTuanIDMap)) {
			nmShopTuanIDMap[shopID] = tuanID
		} else {
			nmShopTuanIDMap[shopID] = nmShopTuanIDMap[shopID] "@@@" tuanID
		}
	} END {
		print "tuanid\tcinemaid\tsite\ttype\turl\ttitle\tphoto\tprice\tvalue\tsell"
		for (nmShopID in nmShopTuanIDMap) {
			if (!(nmShopID in mergeIDMap)) {
				continue
			}
			vrCinemaID = mergeIDMap[nmShopID]

			tuanIDs = nmShopTuanIDMap[nmShopID]
			tuanIDLen = split(tuanIDs, tuanIDArray, "@@@")
			for (i=1; i<=tuanIDLen; i++) {
				tuanID = tuanIDArray[i]
				if (!(tuanID in nmTuanMap)) {
					continue
				}
				nmTuanInfo = nmTuanMap[tuanID]
				print (++cinemaTuanID) "\t" vrCinemaID "\t" nmTuanInfo
			}
		}
	}' $equalFile $nmTuan $nmShop

	#LOG "merge tuan file for cinema done."
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
	for srcFile in $(ls $VR_CINEMA_DIR/movie/*.table); do
		destFile=${srcFile/Input/Output}
		destDir=$(dirname $destFile)
		if [ ! -d $destDir ]; then
			mkdir -p $destDir
		fi
		mv $destFile $destFile.bak
		cp $srcFile $destFile
	done

	LOG "dispatch data for cinema done."
}



function main() {
:<<EOF
EOF
	# ��ȡʱ������ӰԺ��Ϣ
	typeDir="movie"
	vrCinemaFile=$VR_CINEMA_DIR/$typeDir/cinema_detail.table
	vrCinemaExtractData="tmp/vr_cinema_data"

	extract_vr_cinema $vrCinemaFile $vrCinemaExtractData


	# ��ȡŴ���Ź���ӰԺ������
	nuomiShopFile="tmp/nuomi_shop"
	nuomiTuanFile="tmp/nuomi_tuan"

	cat $NUOMI_TUAN_DIR/*_shop > $nuomiShopFile
	cat $NUOMI_TUAN_DIR/*_tuan > $nuomiTuanFile

	nuomiExtractData="tmp/nuomi_cinema"
	extract_nuomi_cinema $nuomiShopFile $nuomiExtractData
	

	mergeData="tmp/cinema_merge_data"
	merge_cinema $nuomiExtractData $vrCinemaExtractData $mergeData


	# ��һ���õ�������ļ������ںϲ�
	addrEqual=$mergeData.addr.equal;  titleEqual=$mergeData.title.equal;
	python bin/ServiceAppCinemaMerger.py -title $mergeData.title.sort > $titleEqual
	python bin/ServiceAppCinemaMerger.py -addr $mergeData.addr.sort > $addrEqual
	#python bin/ServiceAppRestaurantMerger.py -tel $mergeData.tel.sort > $telEqual
	LOG "apply merge strategy done."
	
	mergeEqual="tmp/cinema_equal_merge"
	# �ϲ���ͬ�����µ�equal merge,ȥ��
	cat $titleEqual $addrEqual | awk -F'\t' '{
		if (NF != 3) { next }
		id1=$2; id2=$3;
		if (id1~/@/) {
			mergeItem = id1 "\t" id2
		} else {
			mergeItem = id2 "\t" id1
		}
		if (!(mergeItem in existMergeItems)) {
			existMergeItems[mergeItem] = 1
			print mergeItem
		}
	}' > $mergeEqual
	LOG "merge and uniq equal items done. [$mergeEqual]"

	# �����Ź���Ϣ
	cinemaTuanFile="$VR_CINEMA_DIR/movie/cinema_tuan.table"

	merge_tuan $mergeEqual $nuomiTuanFile $nuomiShopFile > $cinemaTuanFile
	LOG "get tuan info for cinema done. [$cinemaTuanFile]"
	exit -1;
		
	# �ַ���OutputĿ¼��
	dispatch

	LOG "handle nuomi's cinema tuan info done."


}

main
#dispatch
