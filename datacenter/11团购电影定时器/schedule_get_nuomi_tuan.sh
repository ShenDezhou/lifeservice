
# ÿ�� 4:00 ��ʼ��


# ���ذٶ�Ŵ�׵��Ź�����
cd /search/zhangk/Fuwu/Source/Cooperation/Nuomi/
	sh bin/build_tuan.sh 1>>log/nuomi_tuan.std 2>>log/nuomi_tuan.err
cd -


# ����ڵ����ĵ��̽��кϲ�
cd /fuwu/Source/Cooperation/Tuan/

	sh bin/build_nuomi_play_tuan.sh 1>logs/nuomi_play_tuan.std 2>&1 &
	sh bin/build_nuomi_restaurant_tuan.sh 1>logs/nuomi_restaurant_tuan.std 2>&1 &

cd -


