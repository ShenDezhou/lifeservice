. ./Tool.sh

LOG "begin to get movie cooperation data..."
# ������������Ӱ�� ������ӰԺ��Ƭ��Ϣ����
cd /search/zhangk/Fuwu/Source/Cooperation/
	sh build_download_cooperation_data.sh 1>>std 2>>err &
cd -


LOG "begin to get movie mtime data..."
# �������� ��Ӱ�� ʱ������Ӱ������Ϣץȡ
cd /fuwu/Spider/Mtime/
	/usr/bin/python bin/getMtimeMovie.py 1>>std 2>>err &
cd -

wait

LOG "get movie datas done"


LOG "begin to index movie info..."
# ����������ץȡ������Ϻ�ִ����������
cd /fuwu/
        sh build_movie.sh 1>>logs/movie.std 2>>logs/movie.err
cd -
LOG "index movie info done."


