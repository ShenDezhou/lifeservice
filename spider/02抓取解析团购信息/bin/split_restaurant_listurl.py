#!/bin/python
#coding=gb2312
import re, sys

# �����ڵ�����ʳlist�б�Ҳץȡ��url,�ַ��Գ���Ϊ��λ���ļ���


# ���س��е�code��ƴ����ӳ��
def load_city_conf(input):
	cityCodeNameMap = dict()
	for line in open(input):
		segs = line.strip('\n').split('\t')
		if len(segs) != 3:
			continue
		code, enName = segs[1], segs[2]
		cityCodeNameMap[code] = enName
	return cityCodeNameMap



# ����ÿ�����е�restaurant url���ļ���
def create_restaurant_url_path(city):
	return 'data/restaurant/url/%s_urls' % city


def split_restaurant_urls(cityConf, input, inEncode, outEncode='gb2312'):
	cityCodeNameMap = load_city_conf(cityConf)
	#print cityCodeNameMap
	cityfdMap = dict()
	curCityCode, curPage = '', ''
	for line in open(input):
		segs = line.strip('\n').decode(inEncode, 'ignore').split('\t')
		if len(segs) == 2 and segs[0] == 'url':
			#http://www.dianping.com/search/category/416/10/r28263p1
			url = segs[1].replace('http://www.dianping.com/search/category/', '')
			url = re.sub('\?.*$', '', url)
			curPage = re.sub('.*p', '', url)
			curCityCode = re.sub('/.*$', '', url)
		elif len(segs) > 4:
			if curCityCode not in cityCodeNameMap:
				print curCityCode
				continue
			# ��restaurant��urlд���Ӧ���е�url�ļ���
			url, title, city = segs[0], segs[1], cityCodeNameMap[curCityCode]
			line = '%s\t%s\t%s\t%s' % (url, title, city, curPage)
			if city not in cityfdMap:
				urlPath = create_restaurant_url_path(city)
				fd = open(urlPath, 'w+')
				cityfdMap[city] = fd
			cityfdMap[city].write(('%s\n' % line).encode(outEncode, 'ignore'))
	# �ر��ļ�������
	for city in cityfdMap:
		cityfdMap[city].close()




cityConf = sys.argv[1]
input = sys.argv[2]
split_restaurant_urls(cityConf, input, 'utf8')
