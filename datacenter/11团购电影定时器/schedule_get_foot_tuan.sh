
# ÿ�� 6:00 ��ʼ��

cd /fuwu/Spider/Huatuojiadao
	# ��٢�ݵ����Ź�����
	sh bin/get_huatuojiadao_tuan.sh 1>logs/huatuojiadao.std 2>&1
	# �������ӵ��Ź�����
	sh bin/get_liangzi_tuan.sh 1>logs/liangzi.std 2>&1
cd -

