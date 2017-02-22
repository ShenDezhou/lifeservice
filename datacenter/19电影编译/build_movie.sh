#!/bin/bash

. ./Tool/Shell/Tool.sh

# ÿ�����һ���Ӱ������(chrome���ץȡ���Լ�ʱ����������)
cd /search/zhangk/Fuwu/Source/Crawler/beijing/movie/
	sh cp.sh
cd -

# ����Ӱԭʼ�����Ƿ�Ϊ��
detailLine=$(cat /search/zhangk/Fuwu/Source/Crawler/beijing/movie/mtime_detail | wc -l)
actorsLine=$(cat /search/zhangk/Fuwu/Source/Crawler/beijing/movie/mtime_actors | wc -l)
photosLine=$(cat /search/zhangk/Fuwu/Source/Crawler/beijing/movie/mtime_photos | wc -l)

if [ $detailLine -lt 20 -o $actorsLine -lt 20 -o $photosLine -lt 20 ]; then
	LOG "movie base data error!"
	sendReportMail "ServiceAppSpideErrorReport" "[Error]: Update Movie Error, Check 10.134.14.117:/fuwu/build_movie.sh"
	exit -1
fi

# ץƱ����Ϣ
cd /search/zhangk/Fuwu/Spider/Cbooo
	sh get_cbo_allbox.sh 
cd -


# ӰԺ/��Ӱ������Ϣ
cd Source
	sh bin/build_mtime_movie.sh 1>movie.std 2>movie.err
cd -


# ���⴦��
cd Merger
	# �ϲ�ӰԺ�Ļ�����Ϣ
	sh bin/build_cinema_movie.sh 1>cinema.std 2>cinema.err

	# ����Ʊ������
	sh bin/build_movie_allbox.sh 1>movie_allbox.std 2>movie_allbox.err
cd -


# ���ʼ�֪ͨ���½��
movieResultDir="/fuwu/Merger/Output/movie/"
movieResultInfo=$(getFileInfoOfDirectory $movieResultDir)
sendReportMail "ServiceAppSpideErrorReport" "[Info]: Update Movie Success! <br> $movieResultInfo"


# ���һ���ļ�����
cmRelLine=$(cat /fuwu/Merger/Output/movie/cinema_movie_rel.table | wc -l)
movieLine=$(cat /fuwu/Merger/Output/movie/movie_detail.table | wc -l)

[ $cmRelLine -lt 10000 ] && echo "cinema-movie-relation file is too small" && exit -1
[ $movieLine -lt 80 ] && echo "movie file is too small" && exit -1

LOG "movie base data is done. begin to index it"

ssh 10.134.96.110 "cd /search/kangq/fuwu; nohup sh -x bin/build_movie.sh 1>std 2>err &"
