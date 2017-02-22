#!/bin/bash
#coding=gb2312

source ~/.bash_profile

INPUT="./Input"

. ./bin/Tool.sh

# ���ڵ�����ӰԺ��Ϣ <source  id  city  area districe  score>
DIANPING_CINEMA_INFO="/search/zhangk/Fuwu/Spider/Dianping/data/cinema_info"
# ӰԺ��IDӳ���ϵ <score  id  innerid>
CINEMA_ID_CONF="/search/zhangk/Fuwu/Source/conf/cinema_vrid_id_conf"
# ����ӰԺ��Ϣ <id  source  title  brand  address  province  city  district  area  poi  tel  businesstime  hasimax score>
CINEMA_INFO=$INPUT/movie/cinema_detail.table
# ��Ӱ-��ӳӰԺӳ����Ϣ
MOVIE_CINEMA_INFO=$INPUT/movie/movie_cinema_rel.table 

# ӰԺ-��ӳ��Ӱӳ����Ϣ
CINEMA_MOVIE_INFO=$INPUT/movie/cinema_movie_rel.table
# ��Ӱ������Ϣ
MOVIE_INFO=$INPUT/movie/movie_detail.table
# ����-��Ӱ�б���Ϣ
CITY_MOVIE_LIST_INFO=$INPUT/movie/city_movie_list.table



# ����ͬӰԺ����Ϣ�ϲ�����
# ����ѡ��è�۵�����
function merge_cinema_info() {
	awk -F'\t' 'BEGIN {
		areaRow = -1; scoreRow = -1;  districtRow = -1; rowNum = -1;
		print "id\ttitle\tbrand\taddress\tprovince\tcity\tdistrict\tarea\tpoi\ttel\tbusinesstime\thasimax\tscore"
	} function normArea(area) {
		split(area, array, ";")
		return array[1]
	} {
		# ����ʹ�ã�������Ϣֱ��ʹ�� è�۱���ģ���Ҫ��һ��
		# �����ֶε���Ϣ�����è��û�У��������У����滻
		# �ϲ����Һ����̼ҵ���Ϣ
		if (FNR == 1) {
			rowNum = NF;
			for(row=1; row<=NF; ++row) {
				if ($row == "score") { scoreRow = row; continue }
				if ($row == "district") {districtRow = row; continue }
				if ($row == "area") {areaRow = row; continue }
			}
		} else {
			id=$1; source=$2;
			cinemaids[id]
			# è�۵� ��Ϊ��Ҫ��������Դ
			if (source ~ /Maoyan/) {
				for (row=3; row<=NF; ++row) {
					key = id "\t" row
					# è�۵�������Ҫ��һ��
					if (areaRow == row) {
						$row = normArea($row)
					}
					maoyanCinemaInfo[key] = $row
				}
			} else {
				for (row=3; row<=NF; ++row) {
					key = id "\t" row
					if (!(key in cinemaInfo) || $row != "") {
						cinemaInfo[key] = $row
					}
				}
			}
		}
	} END {
		# ��������
		for (id in cinemaids) {
			line = id;
			for (row=3; row<=rowNum; ++row) {
				key = id "\t" row;  value=""
				if (key in cinemaInfo && cinemaInfo[key] != "") {
					value = cinemaInfo[key]
				}
				if (key in maoyanCinemaInfo && maoyanCinemaInfo[key] != "") {
					value = maoyanCinemaInfo[key]
				}
				if (row==scoreRow && length(value) > 3) {
					value = substr(value, 0, 3)
				}
				line = line "\t" value
			}
			print line
		}
	}' $CINEMA_INFO > $CINEMA_INFO.merge2

	LOG "update cinema done. [$CINEMA_INFO.merge2]"
}





# ��������Ƭ��Ϣ��û����ʱ������ӳ�б��еģ�ͨ�������ӿ�����
function add_merge_failed_movies_info() {
	extraActorFile=/search/zhangk/Fuwu/Source/Crawler/beijing/movie/mtime_actors.extra
	extraVideoFile=/search/zhangk/Fuwu/Source/Crawler/beijing/movie/mtime_videos.extra
	onlineMovieDetailFile=/fuwu/Merger/Input/movie/movie_detail.table
	onlineMovieActorsFile=/fuwu/Merger/Input/movie/movie_actors.table
	onlineMovieVideosFile=/fuwu/Merger/Input/movie/movie_videos.table

	if [ -f $extraActorFile ]; then
		awk -F'\t' 'ARGIND==1 {
			movieids[$1]
		} ARGIND==2 {
			if ($2 in movieids) {
				print
			}
		}' $onlineMovieDetailFile $extraActorFile >> $onlineMovieActorsFile
	fi

	if [ -f $extraVideoFile ]; then
		awk -F'\t' 'ARGIND==1 {
			movieids[$1]
		} ARGIND==2 {
			if ($2 in movieids) {
				print
			}
		}' $onlineMovieDetailFile $extraVideoFile >> $onlineMovieVideosFile

	fi
	LOG "add merge failed movie's info done."
}

