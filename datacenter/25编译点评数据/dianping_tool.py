#!/bin/python
#coding=gb2312
#/*******************************************************************************
# * Author	 : liubing@sogou-inc.com
# * Last modified : 2016-05-04 19:18
# * Filename	 : dianping_tool.py
# * Description	 : ���ڵ�����ص�һЩ���ܺ���
# * *****************************************************************************/
import re, urllib2




# business        ����    2       ������  c434    Ϫ��ׯ��        r65445
# ���س���-������ӳ���
def load_city_conf(cityConf, inEncode='gb2312'):
	cityMap = dict()
	for line in open(cityConf):
		segs = line.strip('\n').decode(inEncode, 'ignore').split('\t')
		if segs[0] != 'business' or len(segs) < 7:
			continue
		cityid, area, areaid, districtid = segs[2], segs[3], segs[4], segs[6]
		# ������ؼ�������ˣ�������ԺͲ�Ʒ����
		if re.search(u'��$', area.strip()):
			continue
		if cityid not in cityMap:
			map = dict()
			cityMap[cityid] = map
		if areaid not in cityMap[cityid]:
			areaList = []
			cityMap[cityid][areaid] = areaList
		if districtid not in cityMap[cityid][areaid]:
			cityMap[cityid][areaid].append(districtid)
	return cityMap


# ���ز�ϵ��С���ӳ��
def load_category_conf(categoryConf, inEncode='gb2312'):
	categoryMap = dict()
	for line in open(categoryConf):
		segs = line.strip('\n').decode(inEncode, 'ignore').split('\t')
		if segs[0] != 'cook' and segs[0] != 'category':
			continue
		category, categoryid = segs[3], segs[4]
		if segs[0] == 'cook':
			category, categoryid = segs[3], segs[4]
		categoryMap[categoryid] = category
	return categoryMap



def get_shop_number(url):
	regex = '<span class="num">\(([0-9]+)\)</span>'
	try:
		response = urllib2.urlopen(url).read()
	except:
		print '[Error]: \t%s' % url
		return -1
	number = 0
	match = re.search(regex, response)
	if match:
		number = match.group(1)
	print "[Info]: \t%s\t%s" % (url, number)
	return int(number)


# areaConf: ����-����ӳ���
# categoryConf : ���ӳ���
# type: ���id  ��ʳ��10  ���У�30  ���ˣ�50
# ��ȡĳһ�����ĳ�������µĵ��̸���
def get_city_type_area_shop_num(cityConf, categoryConf, type, output):
	cityMap = load_city_conf(cityConf)
	categoryMap = load_category_conf(categoryConf)
	
	shopMaxNumber = 750
	# city  type:	http://www.dianping.com/search/category/2/50  ���� ����
        # city  area  type:	http://www.dianping.com/search/category/2/50/r14  ���� ����  ����
	# city district  type:	http://www.dianping.com/search/category/2/50/r2580  ���� ���� ������ ����
	# city district category:	http://www.dianping.com/search/category/2/50/g157r2580  ���� ���� ������ ���� ����
	
	fd = open(output, 'w+')
	for cityid in cityMap:
		cityTypeUrl = 'http://www.dianping.com/search/category/%s/%s' % (cityid, type)
		cityTypeShopNum = get_shop_number(cityTypeUrl)
		if cityTypeShopNum == -1:
			continue
		if cityTypeShopNum < shopMaxNumber:
			fd.write('%sp1\t%d\n' % (cityTypeUrl, cityTypeShopNum))
			continue
		for areaid in cityMap[cityid]:
			areaTypeUrl = 'http://www.dianping.com/search/category/%s/%s/%s' % (cityid, type, areaid)
			areaTypeShopNum = get_shop_number(areaTypeUrl)
			if areaTypeShopNum == -1:
				continue
			if areaTypeShopNum < shopMaxNumber:
				fd.write('%sp1\t%d\n' % (areaTypeUrl, areaTypeShopNum))
				continue
			for districtid in cityMap[cityid][areaid]:
				districtTypeUrl = 'http://www.dianping.com/search/category/%s/%s/%s' % (cityid, type, districtid)
				districtTypeShopNum = get_shop_number(districtTypeUrl)
				if districtTypeShopNum == -1:
					continue
				if districtTypeShopNum < shopMaxNumber:
					print '%sp1' % districtTypeUrl
					fd.write('%sp1\t%d\n' % (districtTypeUrl, districtTypeShopNum))
					continue
				for categoryid in categoryMap:
					fd.write('http://www.dianping.com/search/category/%s/%s/%s%sp1\n' % (cityid, type, categoryid, districtid))
				
			
	fd.close()



def get_city_play_shop_number():
	cityConf = 'conf/dianping_city_area_district_conf'
	catrgoryConf = 'conf/dianping_play_category_conf'
	playType = '30'
	output = 'conf/dianping_city_play_shop_num_conf'
	get_city_type_area_shop_num(cityConf, catrgoryConf, playType, output)



get_city_play_shop_number()
