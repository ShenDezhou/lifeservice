
echo $(date "+%Y-%m-%d %H:%M:%S")" begin"


cd Dianping
	sh build.sh 1>>std 2>err &
cd -

cd Maoyan
	sh build.sh 1>>std 2>err &
cd -

cd Wepiao
	sh build.sh 1>>std 2>err &
cd -

cd KouMovie
	sh build.sh 1>>std 2>err &
cd -

# Ŵ������Ҫ������Сʱ����ץȡ���
#cd /fuwu/Spider/Nuomi/
#	sh bin/get_nuomi_cinema_movie.sh 1>movie.std 2>movie.err &
#cd 

wait

echo $(date "+%Y-%m-%d %H:%M:%S")" all done!"
