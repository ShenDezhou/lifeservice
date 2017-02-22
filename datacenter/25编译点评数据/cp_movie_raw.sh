#!/bin/bash
#coding=gb2312

# maoyan_comments  maoyan_shortdesc  mtime_actors  mtime_detail  mtime_photos  mtime_shortdesc  mtime_videos
# task-118: ʱ������Ӱ��������  ��Ӧ  mtime_detail
# task-119: è�۵�Ӱ����  ��Ӧ  maoyan_shortdesc
# task-120: è�۵�Ӱ����  ��Ӧ  maoyan_comments

# task-144: ʱ������Ӱ�б�,������Ϣ ��Ӧ mtime_shortdesc
# task-121: ʱ������Ӱ��Ա��  ��Ӧ mtime_actors
# task-122: ʱ������Ӱ����  ��Ӧ  mtime_photos
# task-123: ʱ������ӰƬ��  ��Ӧ  mtime_videos

. /search/liubing/Tool/Shell/Tool.sh 
#User="movie"
User="system"
ResultPath="/search/liubing/spiderTask/result/$User"


# ȥ�أ�������������,�����Ƚ϶��
function uniq_movie_files_() {
	input=$1;  output=$2
	awk -F'\t' 'BEGIN {
		url = ""; lastItem = "";
	}{
		if (NF==2 && $1=="url") {
			if (lastItem != "") {
				if (!(url in itemArray) || lastItemLen >= lastItemLenArray[url]) {
					itemArray[url] = lastItem
					lastItemLenArray[url] = lastItemLen
				}
			}
			url = $2; lastItem=$0; lastItemLen=1
		} else {
			lastItem = lastItem "\n" $0
			lastItemLen += 1
		}
	} END {
		if (!(url in itemArray) || lastItemLen >= lastItemLenArray[url]) {
			itemArray[url] = lastItem
			lastItemLenArray[url] = lastItemLen
		}
		for (url in itemArray) {
			print itemArray[url]
		}
	}' $input > $output
	LOG "uniq $input to $output done."
}

# ȥ�أ�������������,�����Ƚ϶��
function uniq_movie_files() {
	input=$1;  output=$2
	awk -F'\t' 'BEGIN {
		url = ""; lastItem = "";
	}{
		if (NF==2 && $1=="url") {
			if (lastItem != "") {
				if (!(url in itemArray) || lastItemLen > 5) {
					itemArray[url] = lastItem
				}
			}
			url = $2; lastItem=$0; lastItemLen=1
		} else {
			lastItem = lastItem "\n" $0
			lastItemLen += 1
		}
	} END {
		if (!(url in itemArray) || lastItemLen > 5) {
			itemArray[url] = lastItem
			lastItemLenArray[url] = lastItemLen
		}
		for (url in itemArray) {
			print itemArray[url]
		}
	}' $input > $output
	LOG "uniq $input to $output done."
}

# ȥ��
function uniq_file() {
	input=$1;  output=$2
	awk -F'\t' '{
		if (!($0 in lines)) {
			lines[$0]
			print
		}
	}' $input > $output
	LOG "uniq $input to $output done. "
}





# ��ȡһ��·���µ�������µĽ���ļ�
function get_today_latest_result() {
	inputPath=$1;  output=$2
	today=$(date +%Y-%m-%d)

	latestFileName=$(ls -l $inputPath | tail -n1 | awk '{print $NF}')
	if [ ! -f $inputPath/$latestFileName ]; then
		echo "$inputPath has no file!!!!"
		exit -1
	fi

	latestFileSize=$(ls -l $inputPath/$latestFileName | tail -n1 | awk '{print $5}')
	latestFileDate=$(ls -l --full-time $inputPath/$latestFileName | tail -n1 | awk '{print $6}')

	if [ "$latestFileDate" != "$today" ]; then
		echo "$inputPath/$latestFileName is not created today!!!"
		exit -1
	fi
	
	bakdate=$(date +%Y%m%d)
	mv $output history/$output.$bakdate
	iconv -futf8 -tgbk -c $inputPath/$latestFileName > $output
}


# ��ȡһ��·�����������µĽ���ļ�
function get_today_all_result() {
	inputPath=$1;  output=$2
	today=$(date +%Y-%m-%d)

	files=$(ls -l --full-time $inputPath | fgrep "$today" | awk -v PATH=$inputPath '{
		files = files" "PATH"/"$NF} END { print files}')
	echo $files

	bakdate=$(date +%Y%m%d)
	mv $output history/$output.$bakdate
	cat $files | iconv -futf8 -tgbk -c > $output
}


function backup() {
	rm -f mtime_detail.bak;  mv mtime_detail mtime_detail.bak
	rm -f maoyan_shortdesc.bak; mv maoyan_shortdesc maoyan_shortdesc.bak
	rm -f maoyan_comments.bak; mv maoyan_comments maoyan_comments.bak
	rm -f mtime_actors.bak; mv mtime_actors mtime_actors.bak
	rm -f mtime_photos.bak; mv mtime_photos mtime_photos.bak
	rm -f mtime_videos.bak; mv mtime_videos mtime_videos.bak
	rm -f mtime_shortdesc.bak; mv mtime_shortdesc mtime_shortdesc.bak
}



function copy_movie_files()  {
	get_today_all_result $ResultPath/task-118 mtime_detail.raw
	get_today_all_result $ResultPath/task-119 maoyan_shortdesc.raw
	get_today_all_result $ResultPath/task-120 maoyan_comments.raw

	get_today_all_result $ResultPath/task-121 mtime_actors
	get_today_all_result $ResultPath/task-122 mtime_photos
	get_today_all_result $ResultPath/task-123 mtime_videos
	get_today_all_result $ResultPath/task-144 mtime_shortdesc

	# �Ե�Ӱȥ��
	uniq_movie_files mtime_detail.raw mtime_detail

	awk -F'\t' 'NF>4{ desc[$5] = $0} END{ for(id in desc) print desc[id]}' maoyan_shortdesc.raw > maoyan_shortdesc

	# ֻ������ӳ��Ӱ������
	#uniq_movie_files maoyan_comments.raw maoyan_comments
	awk -F'\t' 'ARGIND==1 {
		if (NF < 5) { next }
		movieurl = $4;   gsub("?_v_=yes", "", movieurl);
		hotMovieUrl[movieurl]
	} ARGIND==2 {
		#"http://m.maoyan.com/movie/238607"
		if(NF==2 && $1=="url") {
			if (lastItem != "" && lasturl in hotMovieUrl) {
				print lastItem
			}
			lastItem=$0;  lasturl=$2
		} else {
			lastItem = lastItem "\n" $0
		}
	} END {
		if (lastItem != "" && lasturl in hotMovieUrl) {
			print lastItem
		}
	}' maoyan_shortdesc maoyan_comments.raw > maoyan_comments.filte

	uniq_movie_files maoyan_comments.filte maoyan_comments
}

copy_movie_files
