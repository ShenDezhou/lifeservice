#!/bin/bash
#coding=gb2312
#/*******************************************************************************
# * Author	 : liubing@sogou-inc.com
# * Last modified : 2016-06-14 10:15
# * Filename	 : batch_do_something.sh
# * Description	 : ����������
# * *****************************************************************************/


RestaurantTuanPath=/fuwu/DataCenter/tuan_restaurant
PlayTuanPath=/fuwu/DataCenter/tuan_play

KqRestaurantPath=/fuwu/Source/Cooperation/Tuan/Input/dianping/restaurant_kq
KqPlayPath=/fuwu/Source/Cooperation/Tuan/Input/dianping/play_kq


# �����Ź���Ϣ
function filter_dianping_tuan() {
	# ���˵�������֮�ڵ��ڣ����Ҳ��ڿ���ץȡ�������е�����
	# ����ڿ���ץȡ�У����ǲ������������еĲ���	

	onlineTuan=$1;  kqTuan=$2;

	deadline=$(date -d "6 months" +%Y-%m-%d)

	awk -F'\t' -v DATE=$deadline 'ARGIND==1 {
		if(FNR == 1) { next }
		kqTuanDeals[$1] = $0
	} ARGIND==2 {
		if (FNR == 1) {
			print; next
		}
		source=$3;  dealid=$5;  deadline = $NF
		if (source != "���ڵ���") {
			print; next
		}
		gsub(/(.*\/|\?.*$)/, "", dealid)
		if (dealid in kqTuanDeals) {
			kqTuanDeals[dealid] = ""
			print; next
		}
		if (deadline > DATE) {
			print; next
		}
	} END {
		# ����ڿ���ץȡ�У����ǲ������������еĲ���
		for(dealid in kqTuanDeals) {
			if (kqTuanDeals[dealid] != "") {
				print kqTuanDeals[dealid]
			}
		}
	}' $kqTuan $onlineTuan > $onlineTuan.dianping


	rm -f $onlineTuan.bak;  mv $onlineTuan $onlineTuan.bak
	cp $onlineTuan.dianping $onlineTuan
}

# ������Ч�İٶ�Ŵ���Ź�����
function batch_filter_tuan() {
	onlineTuanPath=$1;  kqTuanPath=$2;

	for city in $(ls $onlineTuanPath/); do
		tuanFile=$onlineTuanPath/$city/dianping_detail.tuan.table
		kqTuanFile=${kqTuanPath}/$city
		
		if [ -f $tuanFile -a -f $kqTuanFile ]; then
			filter_dianping_tuan $tuanFile $kqTuanFile
		fi
		echo "filter $city invalid dianping tuan done."
	done
}

function batch_do_something() {
	batch_filter_tuan
}



Type="restaurant"
if [ $# -gt 0 ]; then
	Type=$1
fi

if [ "$Type" = "play" ]; then
	batch_do_something $PlayTuanPath $KqPlayPath
else
	batch_do_something $RestaurantTuanPath $KqRestaurantPath
fi



