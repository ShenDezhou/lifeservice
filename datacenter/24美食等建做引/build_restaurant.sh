
cd Source/
	# ȫ������ʱ����,��ʱ������Ҫ
	#sh bin/build_dianping_restaurant.sh 1>restaurant.std 2>restaurant.err
	# ����ʱ����
	sh bin/update_dianping_restaurant.sh 1>restaurant.std 2>restaurant.err
cd -

cd Merger/
	# ���ڵ�����ץ��ͼ������ʱ������Ҫ
	#sh bin/build_dianping_photoset.sh restaurant 1>restaurant.photo.std 2>restaurant.photo.err
	# ���ڵ�����ץ�����ۣ���ʱ������Ҫ
	#sh bin/build_dianping_review.sh restaurant 1>restaurant.reiew.std 2>restaurant.review.err

	# ����
	sh bin/dispatch_city_type.sh ./Input/ restaurant
	
	# ��������ߴ����
	sh bin/correct_dianping_restaurant_area.sh restaurant
	
	# �����������Ż�����Ϣ (�����ļ���Ҫ����)
	sh bin/build_update_wai_ding.sh restaurant
cd -



# �������ݵ���������
cd /fuwu/DataCenter/
	sh update_restaurant.sh -baseinfo
cd -
