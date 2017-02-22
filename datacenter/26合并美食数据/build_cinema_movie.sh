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
	}' $CINEMA_INFO > $CINEMA_INFO.merge

	LOG "update cinema done. [$CINEMA_INFO.merge]"
}



# ΪӰԺ��ӱ�����
function add_alias_for_cinema() {
	[ ! -f $CINEMA_INFO.merge ] && return -1
	[ ! -f $CINEMA_INFO ] && return -1

	awk -F'\t' 'ARGIND == 1 {
		if (NF < 3) {
			next
		}
		cinemaid=$1; title=$3;
		if (cinemaid in aliasMap) {
			if (index(aliasMap[cinemaid], title) == 0) {
				aliasMap[cinemaid] = aliasMap[cinemaid] ";" title
			}
		} else {
			aliasMap[cinemaid] = title
		}
	} ARGIND == 2 {
		if (FNR == 1) {
			print $0 "\talias";  next
		}
		innerid=$1;  alias=$2
		if (innerid in aliasMap) {
			alias = aliasMap[innerid]
		}
		print $0 "\t" alias
	}' $CINEMA_INFO $CINEMA_INFO.merge > $CINEMA_INFO.alias
	LOG "add alias for $CINEMA_INFO done. [$CINEMA_INFO.alias]"
}





# �ҳ����ǵ�ǰ��ӳ�ͼ�����ӳ�ĵ�Ӱ
function filte_invalid_movie() {

	# ��onlinestatus��Ϊ�յģ����Ϊ�գ���������Ƭ
	awk -F'\t' 'BEGIN {
		onlineRow=-1; movieidRow=-1; dateRow=-1;
	} ARGIND == 1 {
		movieid = $1
		onlineMovie[movieid]
	} ARGIND == 2 {
		if (FNR == 1) {
			for (row=1; row<=NF; ++row) {
				if ($row=="id") {movieidRow = row; continue}
				if ($row=="onlinestatus") {onlineRow = row; continue}
				if ($row=="date") {dateRow = row; continue}
			}
		} else {
			onlineStatus=$onlineRow;  movieid=$movieidRow;
			if (onlineStatus == "" && movieid in onlineMovie) {
				#$onlineRow = "������ӳ"
				$onlineRow = "������ӳ"
			}
			
			gsub(/[����]/, "-", $dateRow)
			gsub(/��[ \s]*\(/, "(", $dateRow)
		}


		line = $1;
		for (row=2; row<=NF; ++row) {
			line = line "\t" $row
		}
		print line
	}' $MOVIE_CINEMA_INFO $MOVIE_INFO > $MOVIE_INFO.update
	
	# mv $MOVIE_INFO.update $MOVIE_INFO
	LOG "update movie info done. [$MOVIE_INFO.update]"
}


function restore_cinema_source() {
	[ ! -f $CINEMA_MOVIE_INFO ] && return -1
	awk -F'\t' '{
		if (FNR == 1 || NF < 4) {
			print; next
		}
		
		gsub("Maoyan", "è�۵�Ӱ", $4)
		gsub("Dianping", "���ڵ���", $4)
		gsub("Wepiao", "΢�ŵ�ӰƱ", $4)
		gsub("Kou", "�ٵ�Ӱ", $4)
		
		line = $1
		for (idx=2; idx<=NF; ++idx) {
			line = line "\t" $idx
		}
		print line
	}' $CINEMA_MOVIE_INFO > $CINEMA_MOVIE_INFO.upsource

	rm -f $CINEMA_MOVIE_INFO.bak;  mv $CINEMA_MOVIE_INFO $CINEMA_MOVIE_INFO.bak
	cp $CINEMA_MOVIE_INFO.upsource $CINEMA_MOVIE_INFO
	
	LOG "restore cinema source from en to ch"
}


function dispatch() {
	for srcFile in $(ls $INPUT/movie/*.table); do
		destFile=${srcFile/Input/Output}
		destDir=$(dirname $destFile)
		if [ ! -d $destDir ]; then
			mkdir -p $destDir
		fi
		if [ ! -d $destDir/history ]; then
			mkdir -p $destDir/history
		fi
		
		rm -f $destDir/history/$(basename $destFile).$(date "+%Y%m%d")
		mv $destFile $destDir/history/$(basename $destFile).$(date "+%Y%m%d")
		cp $srcFile $destFile
	done

	# dispatch cinema  movie info
	movie_dest_file=${MOVIE_INFO/Input/Output}
	rm -f $movie_dest_file;  cp $MOVIE_INFO.update $movie_dest_file


	cinema_dest_file=${CINEMA_INFO/Input/Output}
	rm -f $cinema_dest_file; 
	if [ -f $CINEMA_INFO.alias ]; then
		cp $CINEMA_INFO.alias $cinema_dest_file
	elif [ -f $CINEMA_INFO.merge ]; then
		cp $CINEMA_INFO.merge $cinema_dest_file
	fi
}


function add_nuomi_movie() {
	NuomiCMRelation=/fuwu/Source/Cooperation/Nuomi/data/nuomi_movie_cm_relation
	MovieIDMap=/fuwu/Source/tmp/movie_id_merge
	CinemaIDMap=/fuwu/Source/conf/cinema_vrid_id_conf

	[ ! -f $NuomiCMRelation -o ! -f $MovieIDMap -o ! -f $CinemaIDMap ] && return -1;
	
	today=$(date +%Y-%m-%d)
	awk -F'\t' -v TODAY=$today 'BEGIN {
		lineNum = 2000000
	} ARGIND==1 {
		# ���ص�ӰID��ӳ��
		if (NF < 3) {
			next
		}
		movieid=$1;  source=$2;  nuomiMovieid=$3;
		if (source~/Ŵ��/ && movieid!~/Ŵ��/) {
			movieidMap[nuomiMovieid] = movieid
		}
	} ARGIND==2 {
		# ����ӰԺIDӳ��
		if (NF < 3) {
			next
		}
		source=$1;  nuomiCinemaid=$2;  cinemaid=$3;
		if (source!~/Ŵ��/ || NF < 5) {
			next
		}
		cinemaidMap[nuomiCinemaid] = cinemaid
	} ARGIND == 3 {
		if (NF < 4) {
			next
		}
		nuomiCinemaid=$1;  nuomiMovieid=$2; date=$4
		if (date < TODAY) {
			next
		}
		if (!(nuomiCinemaid in cinemaidMap) || !(nuomiMovieid in movieidMap)) {
			next
		}
		$1=cinemaidMap[nuomiCinemaid];  $2=movieidMap[nuomiMovieid]
		# �����ظ���
		key = $1 "" $2 "" $4 "" $6 "" $9
		if (key in existKeys) {
			next
		}
		existKeys[key]		

		line=(++lineNum)
		for(idx=1; idx<=NF; ++idx) {
			line = line "\t" $idx
		}
		print line
	}' $MovieIDMap $CinemaIDMap $NuomiCMRelation >> $CINEMA_MOVIE_INFO
	LOG "add nuomi's cinema_movie relation done."
}


# ����ӰԺ�Ĵ���������
function norm_cinema_room() {
	# ȥ��
	awk -F'\t' '{
		if (FNR == 1) {
			for (i=1; i<=NF; ++i) {
				if ($i == "cinemaid") { cidIdx=i }
				if ($i == "movieid") { midIdx=i }
				if ($i == "source") { sourceIdx=i }
				if ($i == "date") { dateIdx=i }
				if ($i == "start") { startIdx=i }
				if ($i == "room") { roomIdx=i }
			}
			print; next
		}
		if (NF < 10) {
			next
		}
		key = $cidIdx "" $midIdx "" $sourceIdx "" $dateIdx "" $startIdx "" $roomIdx
		if (key in existLines) {
			print > "dddd"
			next
		}
		existLines[key]
		print
	}' $CINEMA_MOVIE_INFO > $CINEMA_MOVIE_INFO.uniq
	LOG "uniq $CINEMA_MOVIE_INFO done."
	

	# ���������Ʋ�һ�µ�
	/usr/bin/python bin/cinemaTingMerger.py $CINEMA_MOVIE_INFO.uniq > tmp/ciname_room_conf
	LOG "get ciname_room_conf done."	

	# ӳ��
	awk -F'\t' 'ARGIND==1 {
		# ����ӳ���ļ�
		if (NF != 4) {
			next
		}
		cid=$1; source=$2; sRoom=$3; dRoom=$4
		roomMap[cid "\t" source "\t" sRoom] = dRoom
	} ARGIND==2 {
		# �滻
		if (FNR == 1) {
			for (i=1; i<=NF; ++i) {
				if ($i == "cinemaid") { cidIdx=i }
				if ($i == "source") { sourceIdx=i }
				if ($i == "room") { roomIdx=i }
			}
			print; next
		}
		if (NF < 10) {
			next
		}
		key = $cidIdx "\t" $sourceIdx "\t" $roomIdx
		if (key in roomMap) {
			$roomIdx = roomMap[key]
		}
		line = $1
		for (i=2; i<=NF; ++i) {
			line = line "\t" $i
		}
		print line
	}'  tmp/ciname_room_conf $CINEMA_MOVIE_INFO.uniq > $CINEMA_MOVIE_INFO.map

	rm -f $CINEMA_MOVIE_INFO.bak;  mv $CINEMA_MOVIE_INFO $CINEMA_MOVIE_INFO.bak
	cp $CINEMA_MOVIE_INFO.map $CINEMA_MOVIE_INFO

	LOG "map cinema room done."
}


# ���� city-movielist 
function get_city_movie_list() {
	awk -F'\t' 'BEGIN {
		print "id\tprovince\tcity\tmovieid"
		lineCnt = 0;
	} ARGIND == 1 {
		province=$6; city = $7;  cinemaid = $1;
		if (province != "") {
			cityprovince[city] = province;
		}
		cinemaCity[cinemaid] = city
	} ARGIND==2 {
		movieids[$1]
	} ARGIND == 3 {
		cinemaid = $2;  movieid = $3;
		if (!(cinemaid in cinemaCity) || !(movieid in movieids)) {
			next
		}
		city = cinemaCity[cinemaid];
		item = cityprovince[city] "\t" city "\t" movieid
		if (item in itemArray) {
			next
		}
		itemArray[item]
		print ++lineCnt "\t" item

	}' $CINEMA_INFO $MOVIE_INFO $CINEMA_MOVIE_INFO > $CITY_MOVIE_LIST_INFO
	LOG "get city movie-list done."
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


function main() {
	# �ϲ����ӰԺ����Ϣ
	merge_cinema_info

	# ΪӰԺ��ӱ�����
	add_alias_for_cinema

	#�������Ӱ������
	filte_invalid_movie

	# ��������-��Ӱ�б�
	get_city_movie_list

	# ����Ƭ��Ϣ����Դ�Ļ�����
	restore_cinema_source

	# ���Ŵ����������
	norm_cinema_room
	
	# ��ӵ���ץȡ�Ĳ���ʱ������ӳ�б��еĶ�����Ϣ
	add_merge_failed_movies_info

	# �ַ�����
	dispatch
}

main

