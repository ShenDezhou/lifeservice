#!/bin/bash
#coding=gb2312
#/*******************************************************************************
# * Author	 : liubing@sogou-inc.com
# * Last modified : 2016-04-21 12:02
# * Filename	 : build_nuomi_dianping_merge_hadoop.sh
# * Description	 : ����hadoop������̵ĺϲ�
# * *****************************************************************************/

. ./bin/Tool.sh
Log=logs/huatuojiadao_tuan.log

LOG "begin to merge" >> $Log

# ��ȡ���ڵ�����һ�����е�shop��Ϣ <id  source  title  poi  tel  city  addr>
function extract_dianping_city_shops() {
	input=$1;  #output=$2;
	awk -F'\t' 'BEGIN {
		#idRow=-1; titleRow=-1; poiRow=-1; cityRow=-1; addrRow=-1; telRow=-1;
		source = "Dianping"
	}{
		if (FNR == 1) {
			for(row=1; row<=NF; row++) {
				if ($row == "id"){ idRow = row;}
				else if ($row == "tel") { telRow = row;}
				else if ($row == "poi") { poiRow = row;}
				else if ($row == "city") { cityRow = row;}
				else if ($row == "title") { titleRow = row;}
				else if ($row == "address") { addrRow = row;}
				else if ($row == "subcuisine") { categoryRow = row;}
			}
			next
		}
		if (NF < 10 || $categoryRow!~/(���ư�Ħ|ϴԡ|SPA)/) {
			next
		}

		id=$idRow; title=$titleRow; poi=$poiRow; city=$cityRow; addr=$addrRow; tel=$telRow; 
		#shopInfo = city "\t" source "\t" id "\t" title "\t" poi "\t" tel "\t" addr
		shopInfo = id "\t" source "\t" title "\t" poi "\t" tel "\t" city "\t" addr
		if (!(id in existids)) {
			existids[id]
			print shopInfo
		}
	}' $input
	LOG "extract dianping shop info of [$input] done."
}





# ��ȡ��٢�ݵ�һ�����е�shop��Ϣ <id  source  title  poi  tel  city  addr>
function extract_huatuojiadao_city_shops() {
	input=$1;  city=$2;  #output=$2;
	awk -F'\t' -v CITY=$city '{
		if (NF < 8 || $1 != "Shop") {
			next
		}

		city=$2; source=$3; id=$4; title=$5; poi=$6; tel=$7; addr=$8
		shopInfo = id "\t" source "\t" title "\t" poi "\t" tel "\t" city "\t" addr
		if (city != CITY) {
			next
		}
		gsub(/��$/, "", city)
		shopInfo = id "\t" source "\t" title "\t" poi "\t" tel "\t" city "\t" addr
		if (!(id in existids)) {
			existids[id]
			print shopInfo
		}
	}' $input #> $output
	LOG "extract huatuojiadao shop info of [$input] done."
}



FoodServices=/fuwu/Spider/Huatuojiadao/data/huatuojiadao_all_services
ShopMap=/fuwu/Spider/Huatuojiadao/data/shop_merge_map
#rm -f $ShopMap.bak;  mv $ShopMap $ShopMap.bak

function merge_foot_shops() {
	# ��ȡ�������ĳ����б����ڳ�ȡ���ڵ���ʹ��
	awk -F'\t' 'ARGIND==1 {
		if (NF >= 3) {
			city=$2;  pinyin=$3
			if (city!~/��$/) {
				city = city "��"
			}
			cityEnMap[city] = pinyin
		}
	} ARGIND==2 {
		if ($1=="Shop" && NF >= 2) {
			city = $2
			if (!(city in existCity)) {
				if (city in cityEnMap) {
					print city "\t" cityEnMap[city]
				}
				existCity[city]
			}
		}
	}' /fuwu/Source/conf/dianping_city_pinyin_conf data/huatuojiadao_all_services > data/city_conf


	# ������д���
	cat data/city_conf | while read city cityen; do
		# ��ȡ���ڵ���������
		echo "handle $city"
			
		extract_dianping_city_shops /fuwu/Merger/Output/$cityen/play/dianping_detail.baseinfo.table > tmp/dianping_play_shops.$cityen
		extract_huatuojiadao_city_shops data/huatuojiadao_all_services $city > tmp/other_play_shops.$cityen
		python bin/ShopMerger.py tmp/dianping_play_shops.$cityen tmp/other_play_shops.$cityen data/merge_shops.$cityen

		#fgrep -v None data/merge_shops.$cityen >> $ShopMap
	done
	LOG "merge all foot shop done."
}


ServiceResult=data/huatuojiadao_service.result
function create_foot_service_imp() {
	shopMergeMap=$1;  output=$2;
	rm -f $output.bak;  mv $output $output.bak
	# �������Ʒ��������
	awk -F'\t' 'BEGIN {
		idx = 20000000; site="��٢�ݵ�"; type="Ԥ"
	} ARGIND==1 {
		if (NF < 4 || $4 == "None") {
			next
		}
		source=$1; srcid=$2; destid=$4;
		idMap[source"\t"srcid] = destid
		#print source"\t"srcid  "\t\t" destid

	} ARGIND==2 {
		if ($1 == "Shop") {
			source=$3;  id=$4;  dianpingid="";
			if (source"\t"id in idMap) {
				dianpingid = idMap[source"\t"id]
			}
		} else if($1 == "Service") {
			if (dianpingid == "") {
				next
			}
			title=$2; url=$3; img=$4; value=$5; price=$6; min=$8; mode=$9
			if (img !~ /http/) {
				img = ""
			}
			serviceItem = dianpingid "\t" site "\t" type "\t" url "\t" title "\t" img "\t" price "\t" value "\t" min "\t" mode
			if (!(serviceItem in existServiceItems)) {
				existServiceItems[serviceItem]
				print ++idx "\t" serviceItem
			}
		}
	}' $shopMergeMap $FoodServices > $output

	LOG "create foot service done." >> $Log
}

# ÿ�����е����Ʒ���
function create_foot_service() {
	serviceResultPrefix=data/huatuojiadao_service
	for mergeFile in $(ls data/merge_shops.*); do
		city=${mergeFile/*./}
		output=$serviceResultPrefix.$city
		create_foot_service_imp $mergeFile $output
		echo "create foot service for $city done."
	done
	LOG "create all huatuojiadao services done." >> $Log

}



# ������д���Ź���������
function dispatch() {
	footTuanPath=/fuwu/DataCenter/foot
	footDestPath=/search/zhangk/Fuwu/Source/Cooperation/Tuan/Output/huatuojiadao_foot
	for serviceFile in $(ls data/huatuojiadao_service.*); do
		city=${serviceFile/.bak/}
		if [ "$city" != "$serviceFile" ]; then
			continue
		fi
		# ��������Ź������Ƿ����
		city=${city/*./}

		footDestFile=$footDestPath/$city

		# ��黪٢�ݵ������Ƿ�Ϊ��
		lines=$(cat $serviceFile | wc -l)
		if [ $lines -gt 0 ]; then
			if [ -f $footDestFile ]; then
				rm -f $footDestFile.bak;  mv $footDestFile $footDestFile.bak
			fi
			cp $serviceFile $footDestFile
		fi
	done
	LOG "dispatch done." >> $Log
}



# ���ػ�٢�ӵ�������
function get_huatuojiadao_services() {
	output=data/huatuojiadao_all_services 
	rm -f $output.bak;  mv $output $output.bak
	
	/usr/bin/python bin/get_huatuojiadao.py > $output
	LOG "get huatuojiadao services done." >> $Log
}


function main() {
	# ����٢�ݵ�������
	get_huatuojiadao_services

	# �ϲ�shop
	merge_foot_shops
	
	# ���������Ź�������
	create_foot_service
	
	# put��Tuan��
	dispatch
}

main
