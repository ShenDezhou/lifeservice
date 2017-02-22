#!/bin/bash
#coding=gb2312

# �����������è�ۣ�΢�����ҵ�ӰԺ����

# ����֮ǰ��merge��Ϣ

# ������ҵ������ӰԺ��ӳ��Ϣ
CooperationPath="/search/zhangk/Fuwu/Source/Cooperation"
MapyanPath="$CooperationPath/Maoyan"
WepiaoPath="$CooperationPath/Wepiao"
DianpingPath="$CooperationPath/Dianping"
KouPath="$CooperationPath/KouMovie"
NuomiPath="$CooperationPath/Nuomi"


# ������ĿӰԺID �� ��������ҵ������ӰԺID ��ӳ���ϵ
CINEMA_ID_CONF="/search/zhangk/Fuwu/Source/conf/cinema_vrid_id_conf"
BackupPath="/search/zhangk/Fuwu/Source/history"


# ʱ������Ӱ������Ϣ; ӰԺ��ϸ����Ϣ
MtimeActors="/search/zhangk/Fuwu/Source/Input/movie_movie_actors.table.id"
MtimeVideos="/search/zhangk/Fuwu/Source/Input/movie_movie_videos.table.id"
MtimeComments="/search/zhangk/Fuwu/Source/Input/movie_movie_comments.table.id"
MtimeMovieDetail="/search/zhangk/Fuwu/Source/Input/movie_movie_detail.table.id"

MtimeBakActors="/fuwu/Merger/history/movie/movie_actors.table"
MtimeBakVideos="/fuwu/Merger/history/movie/movie_videos.table"
MtimeBakComments="/fuwu/Merger/history/movie/movie_comments.table"
MtimeBakMovieDetail="/fuwu/Merger/history/movie/movie_detail.table"


MtimeCinemaInfo="conf/mtime_cinema_info"



# ץȡ�Ĵ��ڵ���ӰԺ��һЩ������Ϣ���Ź���Ϣ
DianpingCinemaInfo="/search/zhangk/Fuwu/Spider/Dianping/data/cinema_info"


# ������ӰƬID �� innerid ��ӳ��
movie_id_merge=tmp/movie_id_merge

# ������ӰԺ/��Ӱ���ݵĺϼ�
CoopMovie=tmp/cooperation_movie
CoopCinema=tmp/cooperation_cinema
CoopMoviePresale=tmp/cooperation_movie_presale
CoopCMRelation=tmp/cooperation_cm_relation
CoopMovieDetail=tmp/cooperation_movie_detail

. ./bin/Tool.sh


# ��ȡʱ������Ӱ������
function extract_mtime_movie_idtitle() {
	input=$1;  output=$2
	if [ ! -f $input ]; then
		LOG "[Error]: extract mtime movie idtitle info, [$input] not exist"
		return -1
	fi
	awk -F'\t' 'BEGIN {
		idRow=-1; titleRow=-1;
	}{
		if (FNR == 1) {
			for(row=1; row<=NF; row++) {
				if ($row == "id") { idRow = row }
				if ($row == "title") { titleRow = row }
			}
		} else {
			print $idRow "\t" $titleRow
		}
	}' $input > $output
	LOG "extract mtime movie id from [$input] done. [$output]"
}




# �ϲ�ʱ�������������Ӱ
function merge_movie_id_imp() {
	mtimeMovieID=$1;  vrMovieID=$2;  output=$3;
	awk -F'\t' ' BEGIN {
		movieid=1;	
	}
	# ��һ����Ӱ������
	function normalTitle(title) {
		gsub(/[��\.��������:,\-]/, "", title)
		gsub(/;.*$/, "", title)
		gsub(/[\s ]/, "", title)
		return tolower(title)
	}
	# ����ʱ�����ĵ�Ӱ����/ID����
	ARGIND ==1 {
		id=$1; title=$2;
		title = normalTitle(title)
		titleid[title] = id
	} ARGIND == 2 {
		site=$1;  id=$2;  title=$3;
		mtimeid = ""
		title = normalTitle(title)
		if (title in titleid) {
			mtimeid = titleid[title]
		} else {
			mtimeid = "need_" ++movieid
			titleid[title] = mtimeid
		}
		print mtimeid "\t" $0
	}' $mtimeMovieID $vrMovieID > $output
	LOG "merge hot movie id done"
}


# �ϲ�ʱ��������ӳ���ϵ�Ӱ��ӳ���ϵ
function merge_old_movie_id_imp() {
	mtimeMovieID=$1;  output=$2;
	awk -F'\t' ' BEGIN {
		movieid=1;	
	}
	# ��һ����Ӱ������
	function normalTitle(title) {
		gsub(/[������:,]/, "", title)
		gsub(/;.*$/, "", title)
		gsub(/[\s ]/, "", title)
		return tolower(title)
	}
	# ����ʱ�����ĵ�Ӱ����/ID����
	ARGIND ==1 {
		id=$1; title=$2;
		title = normalTitle(title)
		titleid[title] = id
	} ARGIND == 2 {
		#need_2  ���ڵ���        577     ������  0       ���ʸ�
		source=$2;  id=$3;  title=$4;
		if ($1 !~ /need_/) {
			print; next
		}
		mtimeid = ""
		title = normalTitle(title)
		if (title in titleid) {
			mtimeid = titleid[title]
		} else {
			mtimeid = source "_" id
			titleid[title] = mtimeid
		}
		# ȥ���ٵ�Ӱ(���������������Ҳ�һ��)
		if (source~/Kou/ || source~/�ٵ�Ӱ/) {
			next
		}

		line = mtimeid
		for (i=2; i<=NF; ++i) {
			line = line "\t" $i
		}
		print line
	}' $mtimeMovieID $output > $output.add

	rm -f $output.bak;  mv $output $output.bak
	cp $output.add $output

	LOG "merge old movie id done"
}





# ����ʱ������Ӱ �� ��������Ӱ ID��ӳ���ϵ
function merge_movie_id() {
	# ��ȡʱ������Ӱ��<id  title>ӳ���ϵ
	mtime_movie_id="tmp/mtime_movie_id"
	extract_mtime_movie_idtitle $MtimeMovieDetail $mtime_movie_id
	# �ϲ���ӳ���µ�Ӱ
	merge_movie_id_imp $mtime_movie_id $CoopMovie $movie_id_merge
	

	# �ϲ�������ӳ���ϵ�Ӱ
	# ��ȡʱ�����ϵ�Ӱ��<id  title>ӳ���ϵ
	mtime_old_movie_id="tmp/mtime_old_movie_id"
	extract_mtime_movie_idtitle $MtimeBakMovieDetail $mtime_old_movie_id
	# �ϲ���ӳ���ϵ�Ӱ
	merge_old_movie_id_imp $mtime_old_movie_id $movie_id_merge

	# �ٵ�Ӱ����ٳ������ǹ��˵���
	awk -F'\t' '{ if($1~/(Kou|�ٵ�Ӱ)/){ next } print}' $movie_id_merge > $movie_id_merge.filter
	rm -f $movie_id_merge;  mv $movie_id_merge.filter $movie_id_merge

	# ����˹������
	cat conf/movie_id_merge_manual >> $movie_id_merge

	LOG "merge movie id done. [$movie_id_merge]"
}


# ����û�кϲ��ɹ��ĵ�Ӱ
function download_merge_failed_movies() {
	sh bin/get_cooperation_nomerged_movies.sh > /fuwu/Spider/Mtime/tmp/movie_titles

	LOG "begin to merge failed movies done......."
	cd /fuwu/Spider/Mtime
		python  bin/getExtraMtimeMovie.py &
	cd -
	LOG "get merge failed movies done."
}


# ��������ӰԺ����ID
# ������Ҫ�����˹���������
function update_cinema_id() {
	cinema_merge_id=$1

	awk -F'\t' 'BEGIN {
		cinemaMaxID = 0;
	} {
		if (NF != 5) { next }
		leftSrc=$2; leftID=$3; rightSrc=$4; rightID=$5;
		leftKey = leftSrc "\t" leftID;  rightKey = rightSrc "\t" rightID;
		
		if (leftKey in cinemaIDMap && rightKey in cinemaIDMap && cinemaIDMap[leftKey] != cinemaIDMap[rightKey]) {
			leftOldValue = cinemaIDMap[leftKey];  rightOldValue = cinemaIDMap[rightKey]
			++cinemaMaxID
			for ( key in cinemaIDMap) {
				if (cinemaIDMap[key] == leftOldValue || cinemaIDMap[key] == rightOldValue) {
					cinemaIDMap[key] = cinemaMaxID
				}
			}
		} else if (!(leftKey in cinemaIDMap) && !(rightKey in cinemaIDMap)) {
			++cinemaMaxID
			cinemaIDMap[leftKey] = cinemaMaxID
			cinemaIDMap[rightKey] = cinemaMaxID
		} else if (leftKey in cinemaIDMap) {
			cinemaIDMap[rightKey] = cinemaIDMap[leftKey]
		} else if (rightKey in cinemaIDMap) {
			cinemaIDMap[leftKey] = cinemaIDMap[rightKey]
		} 
	} END {
		for (key in cinemaIDMap) {
			print key "\t" cinemaIDMap[key]
		}
	}' $cinema_merge_id > $CINEMA_ID_CONF.update

	# ����cinema_id_conf�ļ�
	bakFile=$(basename $CINEMA_ID_CONF)
	mv $CINEMA_ID_CONF $BackupPath/conf/$bakFile.$(date +%Y%m%d%H)
	mv $CINEMA_ID_CONF.update $CINEMA_ID_CONF
	LOG "allocate and update $CINEMA_ID_CONF done."
}


# �ϲ���������ӰԺid
function merge_cinema_id() {
	# cinema <1:id, 2:resource, 3:title, 4:brand, 5:address, 6:province, 7:city, 8:area, 9:district, 10:poi>

	# ��ʱ�������������ӰԺ���ݺϲ�
	# ��Ҫ "id\tresource\ttitle\tbrand\taddress\tprovince\tcity\tarea\tdistrict\tpoi" 	
	awk -F'\t' 'BEGIN {
		brand=""; province=""; area=""; district=""; source="ʱ����"
	} {
		if (FNR == 1) {
			for(row=1; row<=NF; ++row) {
				if ($row == "cinemaid") { idRow = row; continue }
				if ($row == "title") { titleRow = row; continue }
				if ($row == "city") { cityRow = row; continue }
				if ($row == "addr") { addrRow = row; continue }
				if ($row == "poi") { poiRow = row; continue }
			} 
		} else {
			print $idRow"\t"source"\t"$titleRow"\t"brand"\t"$addrRow"\t"province"\t"$cityRow"\t"area"\t"district"\t"$poiRow
		}
	}' $MtimeCinemaInfo > $CoopCinema.combine
	cat $CoopCinema >> $CoopCinema.combine

	# ��һ��title
	awk -F'\t' '
	function normalTitle(title) {
		gsub(/[����\(\)]/, "", title)
		return title
	}
	{
		title = normalTitle($3)
		$3 = title
		line = $1
		for (i=2; i<=NF; i++) {
			line = line "\t" $i
		}
		print line
	}' $CoopCinema.combine > $CoopCinema.norm

	# ���յ�������, poi���������ϲ�
	echo -e "id\tresource\ttitle\tbrand\taddress\tprovince\tcity\tarea\tdistrict\tpoi" > $CoopCinema.title.sort
	echo -e "id\tresource\ttitle\tbrand\taddress\tprovince\tcity\tarea\tdistrict\tpoi" > $CoopCinema.addr.sort
	echo -e "id\tresource\ttitle\tbrand\taddress\tprovince\tcity\tarea\tdistrict\tpoi" > $CoopCinema.poi.sort
	sort -t$'\t' -k7,7 -k3,3 $CoopCinema.norm >> $CoopCinema.title.sort
	sort -t$'\t' -k7,7 -k5,5 $CoopCinema.norm >> $CoopCinema.addr.sort
	sort -t$'\t' -k10,10 $CoopCinema.norm >> $CoopCinema.poi.sort
	
	python bin/ServiceAppCinemaMerge.py -title $CoopCinema.title.sort > tmp/cinema.title.merge
	python bin/ServiceAppCinemaMerge.py -addr $CoopCinema.addr.sort > tmp/cinema.addr.merge
	python bin/ServiceAppCinemaMerge.py -poi $CoopCinema.poi.sort > tmp/cinema.poi.merge
	
	# ר�Ÿ���poi�ľ��� ��ʱ��������ҵ������ӰԺ���кϲ�
	echo -e "id\tresource\ttitle\tbrand\taddress\tprovince\tcity\tarea\tdistrict\tpoi" > $CoopCinema.city.sort
	sort -t$'\t' -k7,7 $CoopCinema.norm >> $CoopCinema.city.sort
	python bin/ServiceAppCinemaMerge.py -distance $CoopCinema.city.sort > tmp/cinema.distance.merge
	

	# ���ϲ���ĵ�����ӰԺID����ͳһ��ID
	cat tmp/cinema.title.merge tmp/cinema.addr.merge tmp/cinema.poi.merge tmp/cinema.distance.merge | awk -F'\t' 'NF==5{print}' > tmp/cinema.id.merge
	# û�кϲ���ӰԺҲ�������棬���ڷ����µ�ID
	awk -F'\t' '{
		id=$1; source=$2
		print "null\t" source "\t" id "\t" source "\t" id
	}' $CoopCinema >> tmp/cinema.id.merge


	# Ϊ��ЩӰԺ���·���ID
	#update_cinema_id tmp/cinema.id.merge


	# ��������ӰԺ�ϲ�ʹ���˹���˵Ľ��
	# ��Cooperation/bin/build_cinema_merge.sh 
	# ʱ������ӰԺ��������
	
	cinema_merge_manual="/fuwu/Source/Cooperation/Merge/cinema_merge.uniq"
	
	cat $cinema_merge_manual > $CINEMA_ID_CONF
	fgrep "ʱ����" tmp/cinema.id.merge > tmp/mtime.cinema.id 	
	awk -F'\t' 'ARGIND==1 {
		gsub("è�۵�Ӱ", "Maoyan", $1)
		gsub("���ڵ���", "Dianping", $1)
		gsub("΢�ŵ�ӰƱ", "Wepiao", $1)
		gsub("�ٵ�Ӱ", "Kou", $1)

		cinemaKey = $1 "\t" $2;  cinemaid = $3;
		cinemaID[cinemaKey] = cinemaid
	} ARGIND == 2 {
		cinemaLeft = $2 "\t" $3;  cinemaRight = $4 "\t" $5
		if ($2 == "ʱ����" && cinemaRight in cinemaID) {
			print cinemaLeft "\t" cinemaID[cinemaRight]
		} else if ($4 == "ʱ����" && cinemaLeft in cinemaID) {
			print cinemaRight "\t" cinemaID[cinemaLeft]
		}
	}' $cinema_merge_manual tmp/mtime.cinema.id >> $CINEMA_ID_CONF

	sed -i 's/è�۵�Ӱ/Maoyan/g' $CINEMA_ID_CONF
	sed -i 's/���ڵ���/Dianping/g' $CINEMA_ID_CONF
	sed -i 's/΢�ŵ�ӰƱ/Wepiao/g' $CINEMA_ID_CONF
	sed -i 's/�ٵ�Ӱ/Kou/g' $CINEMA_ID_CONF

	LOG "merge cooperation cinema id done. [$CINEMA_ID_CONF]"
}




# ����������ӰԺ/��Ӱ���ݵ�����
function copy_ciname_movie_data() {
	# ����֮ǰӦ�����һ����⣬����Ƿ��ǵ�ǰ����������

	
	#cinema <1:id, 2:resource, 3:title, 4:brand, 5:address, 6:province, 7:city, 8:area, 9:district, 10:poi>
	# ������������Ӱ��Ϣ
	cat $MapyanPath/data/*_movie_movie $DianpingPath/data/*_movie_movie $WepiaoPath/data/*_movie_movie $KouPath/data/*_movie_movie $NuomiPath/data/*_movie_movie > $CoopMovie

	# ����������ӰԺ��Ϣ
	cat $CooperationPath/*/data/*_movie_cinema > $CoopCinema

	# ������������Ƭ��Ϣ ���ҹ��� start end Ϊ�յ���, ���˵��Ͼ����ݣ����ڵ�����û�м�ʱ���£�
	today=$(today)
	cat $CooperationPath/*/data/*_movie_cm_relation | awk -F'\t' -v TODAY=$today '$6!="" && $7!="" && $4>=TODAY{print}' > $CoopCMRelation
	

	# ����������ӰԺ��Ԥ����Ϣ
	cat $CooperationPath/*/data/*_movie_presale | awk '$NF!=0{print}' > $CoopMoviePresale


	# ������������Ӱ��������
	cat $CooperationPath/*/data/*_movie_detail > $CoopMovieDetail


	LOG "copy cooperation cinema/movie data done."
}


# ����ӰԺ��Ӱ�Ĺ�ϵ��Ϣ����
function build_cinema_movie_relation() {
	# tmp/movie_id_merge ��ӰID��ӳ���ϵ <0:innerid  1:source  2:id  3:title  4:presale   5:director>
	# $CINEMA_ID_CONF ӰԺID��ӳ���ϵ  <1:source  2:id  3:inner>

	# $CoopMovie <1:source  2:id  3:title  4:presale   5:director>
	# $CoopCinema <1:id, 2:source, 3:title, 4:brand, 5:address, 6:province, 7:city, 8:area, 9:district, 10:poi>
	# $CoopCMRelation <1:cinemaid 2:movieid 3:resource 4:date 5:week 6:start 7:end 8:price 9:room 10:seat>



	# ӰԺ�� <ӰԺID  ӰԺtitle  ʡ�� ���� ��ַ ����Ϣ>
	# ����ʱ�����е�������� tel hasimx businesstime
	cinema_table="Input/movie_cinema_detail.table.id"
	awk -F'\t' 'BEGIN {
		idRow=-1; cityRow=-1; telRow=-1; imaxRow=-1; btimeRow=-1; scoreRow=-1;
		print "id\tsource\ttitle\tbrand\taddress\tprovince\tcity\tdistrict\tarea\tpoi\ttel\tbusinesstime\thasimax\tscore"
	} ARGIND == 1 {
		if (NF < 3) { next }
		source=$1;  id=$2;  innerid=$3
		cinemaIDMap[source "\t" id] = innerid
		print source "\t" id "\t" innerid > "id.map"
	} ARGIND == 2 {
		source = "ʱ����"
		# ʱ����ӰԺ�� <tel  businesstime  hasimax score>
		if (FNR == 1) {
			for(row=1; row<=NF; ++row) {
				if ($row == "cinemaid") { idRow = row; continue }
				if ($row == "city") { cityRow = row; continue }
				if ($row == "tel") { telRow = row; continue }
				if ($row == "hasimax") { imaxRow = row; continue }
				if ($row == "businesstime") { btimeRow = row; continue }
				if ($row == "score") { scoreRow = row; continue }
			} 
		} else {
			id=$idRow; tel=$telRow; hasimax=$imaxRow; businesstime=$btimeRow; score=$scoreRow;
			key = source "\t" id
			if (key in cinemaIDMap) {
				innerid = cinemaIDMap[key]
				mtimeCinemaInfo[innerid] = tel "\t" businesstime "\t" hasimax "\t" score
			}
		}
	} ARGIND == 3 {
		id=$1;  source=$2;
		key = source "\t" id
		if (!(key in cinemaIDMap)) { next }
		innerid = cinemaIDMap[key]
		
		# �������ĳ�������
		line = innerid
		for (row=2; row<=NF; ++row) {
			line = line "\t" $row
		}
		# ʱ�����Ķ�������(�����4���ֶ�)
		extraInfo = "\t\t\t"

		if (innerid in mtimeCinemaInfo) {
			extraInfo = mtimeCinemaInfo[innerid]
		}
		print line "\t" extraInfo
	}' $CINEMA_ID_CONF $MtimeCinemaInfo $CoopCinema > $cinema_table #| sort -t$'\t' -k7,7 -k1,1n > $cinema_table
	LOG "create cinema table done. [$cinema_table]"



	# ��Ƭ�� <ӰԺID ��ӰID ��Դ ���� ���� ��ʼʱ��  ����ʱ�� ���� �۸�>
	# ������� <ӰԺid  ��Ӱid  ����  ��ʼʱ��>����
	cinema_movie_rel_table="Input/movie_cinema_movie_rel.table.id"
	awk -F'\t' 'BEGIN {
		print "id\tcinemaid\tmovieid\tsource\tdate\tweek\tstart\tend\tprice\troom\tlanguage\tdimensional\tseat"
	} ARGIND == 1 {
		# ���ص�����ӰԺ֮��ϲ���ӳ��
		if (NF < 3) { next }
		source=$1;  id=$2;  innerid=$3
		cinemaIDMap[source "\t" id] = innerid
	} ARGIND == 2 {
		# ���ؼ��ҵ�Ӱ�ĺϲ���ӳ��
		if (NF != 6) { next }
		innerid=$1; source=$2;  id=$3
		if (innerid != "") {
			movieIDMap[source "\t" id] = innerid
		}
	} ARGIND == 3 {
		# ���ݵ�������Ƭ��Ϣ���������յ���Ƭ��Ϣ
		cinemaid=$1;  movieid=$2;  source=$3;
		movieKey = source "\t" movieid
		cinemaKey = source "\t" cinemaid
		if (movieKey in movieIDMap && cinemaKey in cinemaIDMap) {
			line = FNR "\t" cinemaIDMap[cinemaKey] "\t" movieIDMap[movieKey]
			for (row =3; row<=NF; ++row) {
				line = line "\t" $row
			}
			print line
		}
	}' $CINEMA_ID_CONF $movie_id_merge $CoopCMRelation | sort -t$'\t' -k1,1n -k2,2n -k3,3 -k5,5 -k7,7 > $cinema_movie_rel_table
	LOG "create cinema-movie relation table done. [$cinema_movie_rel_table]"





	# ��Ӱ-��ӳӰԺ�� <��ӰID  ӰԺID ���� poi>
	movie_cinema_rel_table="Input/movie_movie_cinema_rel.table.id"
	awk -F'\t' 'BEGIN {
		movieidRow=-1; cinemaidRow=-1; cityRow=-1; poiRow=-1; dateRow=-1;
		print "movieid\tcinemaid\tdate\tcity\tpoi"
	} ARGIND == 1 {
		if (FNR == 1) {
			for (row=1; row<=NF; ++row) {
				if ($row == "id") { cinemaidRow=row }
				else if ($row == "city") { cityRow=row }
				else if ($row == "poi") { poiRow=row }
			}
		} else {
			cinemaInfo[$cinemaidRow] = $cityRow "\t" $poiRow
		}
	} ARGIND == 2 {
		if (FNR == 1) {
			for (row=1; row<=NF; ++row) {
				if ($row == "cinemaid") { cinemaidRow=row }
				if ($row == "movieid") { movieidRow=row }
				if ($row == "date") { dateRow=row }
			}
		} else {
			mcItem = $movieidRow "\t" $cinemaidRow "\t" $dateRow
			if (!(mcItem in existItems)) {
				existItems[mcItem] = 1
				if ($cinemaidRow in cinemaInfo) {
					print mcItem "\t" cinemaInfo[$cinemaidRow]
				}
			}
		}
	}' $cinema_table $cinema_movie_rel_table > $movie_cinema_rel_table
	LOG "create movie-cinema relation table done. [$movie_cinema_rel_table]"



	# һ����Ӱ���ڲ�ͬ������Ԥ����Ϣ
	movie_presale_table="Input/movie_movie_presale.table.id"
	awk -F'\t' 'BEGIN {
		print "id\tmovieid\tprovince\tcity"
		tuanid = 0;
	} ARGIND == 1 {
		if (NF != 6) { next }
		innerid=$1; source=$2;  id=$3
		if (innerid != "") {
			movieIDMap[source "\t" id] = innerid
		}
	} ARGIND == 2 {
		if (NF != 5) { next }
		id=$1; source=$2;  key = source "\t" id;
		presale=$3; province=$4; city=$5;
		if (province == "") {
			province = city
		}

		if (!(key in movieIDMap)) {
			next
		}
		innerid = movieIDMap[key]
		# innerid \t province \t city ��һ����Ӱ��ĳ�������Ƿ���Ԥ����Ϣ
		key = innerid "\t" province "\t" city
		if (!(key in presaleInfo) || presaleInfo[key] < presale) {
			presaleInfo[key] = presale
		} 
	} END {
		lineCnt = 0
		for (key in presaleInfo) {
			print (++lineCnt) "\t" key
		}
	}' $movie_id_merge $CoopMoviePresale | sort -t$'\t' -k1,1n -k2,2 -k3,3 > $movie_presale_table 
	LOG "get movie presale table done. [$movie_presale_table]"


	LOG "build cinema-movie relation tables done."
}



# �ٻ�ʱ����������
function recall_mtime_movie_infos() {
	onlineFile=$1;  mtimeFile=$2;

	#rm -f $onlineFile;  mv $onlineFile.bak $onlineFile

	awk -F'\t' 'BEGIN {
		maxid = 0;
	} ARGIND == 1 {
		# ���ص�ӰID��ӳ��
		movieids[$1]
	} ARGIND == 2 {
		print
		id=$1;  movieid=$2;
		existMovies[movieid]
		if (FNR != 1) {
			if (id > maxid) { maxid = id }
		}
	} ARGIND == 3 {
		if (FNR == 1) { next }
		movieid=$2;
		if ((movieid in movieids) && !(movieid in existMovies)) {
			line = ++maxid
			for (i=2; i<=NF; ++i) {
				line = line "\t" $i
			}
			print line
		}
	}' $movie_id_merge $onlineFile $mtimeFile > $onlineFile.recall

	rm -f $onlineFile.bak;  mv $onlineFile $onlineFile.bak
	cp $onlineFile.recall $onlineFile
	LOG "recall for [$onlineFile] done."
}



# �Ӵ洢��ʱ���������ݺ͵�����������������ٻ�һЩ�ϵ�Ӱ
function recall_old_movies() {
	
	#rm -f $MtimeMovieDetail;  mv $MtimeMovieDetail.bak $MtimeMovieDetail

	# �ٻ�һЩ��ӳ���ϵ�Ӱ���Ӵ洢��ʱ�������� + ���������ݣ�
	awk -F'\t' 'ARGIND==1 {
		# ���ص�ӰID��ӳ��
		movieids[$1]
	} ARGIND == 2 {
		# ������ӳ�ĵ�Ӱ�б�
		if (FNR == 1) { print; next }
		if ($1 in movieids) {
			print;  
			existMovie[$1]
		}
	} ARGIND == 3 {
		# �洢��ʱ�����ĵ�Ӱ��ʷ��¼
		if ($1~/_/) { next }
		if (($1 in movieids) && !($1 in existMovie)) {
			#print "mtime old: " $1
			print; existMovie[$1]
		}
	} ARGIND == 4 {
		# ��ӳ���ϵ�Ӱ������û��ʱ�����ļ�¼��
		id=$1;  source=$2; title=$3;
		movieid = source "_" id
		if ((movieid in movieids) && !(movieid in existMovie)) {
			if (source~/Kou/ || source~/�ٵ�Ӱ/) {
				next
			}
			gsub(/;.*$/, "", title)
			$2="";  $3=title;
			line = movieid;
			for (i=2; i<=NF; ++i) {
				line = line "\t" $i
			}
			print line
			existMovie[movieid] 
		}
	}' $movie_id_merge $MtimeMovieDetail $MtimeBakMovieDetail $CoopMovieDetail > $MtimeMovieDetail.recall
	
	rm -f $MtimeMovieDetail.bak;  mv $MtimeMovieDetail $MtimeMovieDetail.bak
	cp $MtimeMovieDetail.recall $MtimeMovieDetail 
	LOG "recall for $MtimeMovieDetail done."

	# �ٻ�ʱ������Ա��
	recall_mtime_movie_infos $MtimeActors $MtimeBakActors

	# �ٻ�ʱ����Ƭ��
	recall_mtime_movie_infos $MtimeVideos $MtimeBakVideos
	
	# �ٻ�ʱ��������
	recall_mtime_movie_infos $MtimeComments $MtimeBakComments
}


# ��������˵����Ҫ���Ź���Ϣ��ɺ󣬲���
function build_cinema_tuan() {
	cinema_tuan_table="Input/movie_cinema_tuan.table.id"
	# ����Ժ��������Ź����ݣ���������ڵ����ϲ�����ʹ��
	cat /fuwu/Source/Cooperation/Dianping/tuan/*.tuan > tmp/dianping.tuan

	awk -F'\t' 'BEGIN {
		print "id\tcinemaid\tsite\ttype\turl\ttitle\tphoto\tprice\tvalue\tsell\tdeadline"
		id = 0
	} ARGIND == 1 {
		if (NF < 3) {
			next
		}
		# ���ڵ�������ӰԺID
		if ($1 ~ /(Dianping|���ڵ���)/) {
			cinemaid = "dianping_" $2
			cinemaids[cinemaid] = $3
		}
	} ARGIND == 2 {
		# �����ӰԺ�����Ź�����
		if ($2 in cinemaids) {
			line = ++id "\t" cinemaids[$2]
			for (i=3; i<=NF; ++i) {
				line = line "\t" $i
			}
			if (!(line in lines)) {
				lines[line]
				print line
			}
		}
	}' $CINEMA_ID_CONF tmp/dianping.tuan > $cinema_tuan_table
	LOG "create cinema tuan table done. [$cinema_tuan_table]"
}




function main() {
	
	# ������������ӰԺ/��Ӱ���ݿ�����tmp/��
	 copy_ciname_movie_data

	# ����ʱ�������������Ӱ��ӳ�� ��tmp/movie_id_merge
	 merge_movie_id

	# ���غϲ�ʧ�ܵĵ�Ӱ����
	download_merge_failed_movies

	# �ϲ���������ӰԺID
	 merge_cinema_id

	# ����ӰԺ����Ƭ��Ӱ�Ĺ�ϵ(ʹ����ID)
	build_cinema_movie_relation

	# ӰԺ���Ź���Ϣ
	 build_cinema_tuan

	# �����������ǰ�ŵ�һЩ�ϵ�Ӱ������, �ӱ��ݵ�ʱ�������ݺ͵������� recall
	recall_old_movies
}

main
