#!/bin/bash
#coding=gb2312
#/*******************************************************************************
# * Author	 : liubing@sogou-inc.com
# * Last modified : 2016-05-18 10:31
# * Filename	 : update_restaurant.sh
# * Description	 : ������ʳ��ص����ݵ���������
# * *****************************************************************************/

InvalidShopConf=/fuwu/DataCenter/conf/invalid_restaurant_shopid


function copy_file() {
	srcPath=$1;  destPath=$2;  fileName=$3;
	
	if [ ! -d $destPath ]; then
		mkdir -p $destPath
	fi
	
	srcFile=$srcPath/$fileName
	destFile=$destPath/$fileName
	
	srcFileLine=$(cat $srcFile | wc -l)
	if [ $srcFileLine -le 1 ]; then
		echo "$srcFileLine is too small"
		return 1
	fi

	if [ -f $destFile ]; then
		rm -f $destFile.bak;  mv $destFile $destFile.bak
	fi
	
	# ֱ�Ӹ���
	#cp $srcFile $destFile

	# ������Чshop ids
	awk -F'\t' 'ARGIND==1 {
		invalidshops[$1]
	} ARGIND==2 {
		if (FNR==1) { 
			print; 
			for (row=1; row<=NF; ++row) {
				if ($row == "id" || $row == "resid") {
					idRow = row
				}
				if ($row == "title") { titleRow = row; }
			}
			next 
		}
		if ($idRow in invalidshops) { next }
		# �����ʳ�࣬����Ҫ����������ص�shop
		if ($titleRow~/����/ && $titleRow~/����/) {
			next
		}
		if ($titleRow~/����������/) {
			next
		}
		print
	}' $InvalidShopConf $srcFile > $destFile

	echo "copy $srcFile to $destFile done."
}


# ������ʳ������Ϣ
function scp_restaurant_baseinfo() {
	for city in $(ls /fuwu/Merger/Output/); do
		if [ "$city" = "movie" -o "$city" = "other" ]; then
			continue
		fi
		srcPath=/fuwu/Merger/Output/$city/restaurant
		destPath=/fuwu/DataCenter/baseinfo_restaurant/$city

		copy_file $srcPath $destPath "dianping_detail.baseinfo.table"
		copy_file $srcPath $destPath "dianping_detail.comment.table"
		copy_file $srcPath $destPath "dianping_detail.recomfood.table"
		#copy_file $srcPath $destPath "dianping_detail.shortreview.table"
	done
}

# ������ʳ�Ź�
function scp_restaurant_tuan() {
	for city in $(ls /fuwu/Merger/Output/); do
		if [ "$city" = "movie" -o "$city" = "other" ]; then
			continue
		fi
		srcPath=/fuwu/Merger/Output/$city/restaurant
		destPath=/fuwu/DataCenter/tuan_restaurant/$city

		copy_file $srcPath $destPath "dianping_detail.tuan.table"
	done
}



if [ $# -lt 1 ]; then
	echo "[Usage]: sh $0 -[baseinfo|tuan]"
	exit -1
fi



if [ "$1" = "-baseinfo" ]; then
	#echo "scp_restaurant_baseinfo"
	scp_restaurant_baseinfo
elif [ "$1" = "-tuan" ]; then
	#echo "scp_restaurant_tuan"
	scp_restaurant_tuan
else
	echo "[Usage]: sh $0 -[baseinfo|tuan]"
	exit -1
fi
