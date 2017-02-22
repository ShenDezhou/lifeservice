. ./Tool.sh



LOG "begin to download nuomi tuan info..."
# ��������  �Ź���  Ŵ�����Ź����ݽ���
cd /search/zhangk/Fuwu/Source/Cooperation/Nuomi/
	sh bin/build_tuan.sh 1>>log/nuomi_tuan.std 2>>log/nuomi_tuan.err &
cd -

LOG "begin to get dianping tuan info..."
# ��������  �Ź���  ���ڵ����Ź����ݽ���
cd /fuwu/Source/Cooperation/Dianping/
	sh bin/build_dianping_tuan.sh 1>>tuan.std 2>>tuan.err &
cd -

wait

LOG "get dianping/nuomi tuan info done."


# �ϲ�Ŵ���Ź����ݵ�����
cd /search/zhangk/Fuwu/Source/Cooperation
	# ���Ŵ�׵���ʳ���Ź�
	LOG "begin to merge dianping/nuomi restaurant info..."
	sh bin/build_nuomi_dianping_merge.sh 1>merge_tuan.std 2>merge_tuan.err
	LOG "merge dianping/nuomi tuan restaurant info done."

	# ���Ŵ�׵��������Ź�����������
	LOG "begin to merge dianping/nuomi foot info..."
	sh bin/build_nuomi_dianping_foot_merge.sh 1>footmerge_tuan.std 2>footmerge_tuan.err
	LOG "merge dianping/nuomi foot info done."
cd -

LOG "begin to get huatuojiaddao foot service info ..."
# ��٢�ݵ�����������
cd /fuwu/Spider/Huatuojiadao/
	sh bin/merge_huatuojiadao.sh 1>>logs/huatuo.std 2>>logs/huatuo.err
	sh bin/merge_liangzi.sh 1>>logs/liangzi.std 2>>logs/liangzi.err
cd -
LOG "get huatuojiaddao foot service info done."





# ������ʳ���Ź����ݵ���������
cd /fuwu/DataCenter/
        sh update_restaurant.sh -tuan
cd -

