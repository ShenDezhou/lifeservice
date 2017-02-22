#!/bin/python
#coding=gb2312
import re, time


# ���ڵ����Ĳ͹�����ߵĹ�һ����
class DPCrumbNormlizer:
	# ������������
	playTypeConf = "conf/dianping_play_type_conf"
	# ����ߵ�һ�к�׺
	crumbSuffixConf = "conf/dianping_crumb_suffix_conf"

	def __init__(self, conf):
		# �����������е� ��Ȧ ��ϵ��Щ����
		self.CITY_KEY = 'city'
		self.AREA_KEY = 'area'
		self.CUISINE_KEY = 'cuisine'
		self.SUB_CUISINE_KEY = 'subcuisine'
		self.DISTRICT_KEY = 'district'
		# ������ص�����ֶ�
		self.TYPE_KEY = 'type'
		self.SUBTYPE_KEY = 'subtype'

		self.crumbSuffixList = []
		self.cityBusinessConf = dict()
		self.playTypeConfDict = dict()
		self.cityBusinessAreaDict = dict()

		self.loadCityBusinessConf(conf)
		self.loadCrumbSuffixConf(self.crumbSuffixConf)
		self.loadPlayTypeConf(self.playTypeConf)


	# ���ش��ڵ�������������еĺ�׺
	def loadCrumbSuffixConf(self, conf):
		for line in open(conf):
			suffix = line.strip('\n')
			if suffix not in self.crumbSuffixList:
				self.crumbSuffixList.append(suffix)


	# ��������������������ļ�
	def loadPlayTypeConf(self, conf):
		for line in open(conf):
			segs = line.strip('\n').split('\t')
			if len(segs) < 2: continue
			type, subType = segs[0], segs[1]
			if subType not in self.playTypeConfDict:
				self.playTypeConfDict[subType] = type


	# ������Ȧ�������ļ�
	def loadCityBusinessConf(self, conf):
		for line in open(conf):
			line = line.strip('\n')
			segs = line.split('\t')
			if len(segs) < 2:
				continue
			if segs[0] == 'business':
				if len(segs) < 6:
					continue
				city, area, district = segs[1], segs[2], segs[5]
				if city not in self.cityBusinessConf:
					cityDict = dict()
					self.cityBusinessConf[city] = cityDict
				# ��� area
				if self.AREA_KEY not in self.cityBusinessConf[city]:
					areaList = []
					self.cityBusinessConf[city][self.AREA_KEY] = areaList
				if area not in self.cityBusinessConf[city][self.AREA_KEY]:
					self.cityBusinessConf[city][self.AREA_KEY].append(area)
				# ��� district
				if self.DISTRICT_KEY not in self.cityBusinessConf[city]:
					districtList = []
					self.cityBusinessConf[city][self.DISTRICT_KEY] = districtList
				if district not in self.cityBusinessConf[city][self.DISTRICT_KEY]:
					self.cityBusinessConf[city][self.DISTRICT_KEY].append(district)
				# [city\tbusiness] = area
				key = '%s\t%s' % (city, district)
				self.cityBusinessAreaDict[key] = area



			elif segs[0] == 'cook':
				if len(segs) < 4:
					continue
				city, cuisine = segs[1].strip(), segs[3].strip()
				if city not in self.cityBusinessConf:
					ciryDict = dict()
					self.cityBusinessConf[city] = cityDict
				if self.CUISINE_KEY not in self.cityBusinessConf[city]:
					cuisineList = []
					self.cityBusinessConf[city][self.CUISINE_KEY] = cuisineList
				# ��� cuisine
				if cuisine not in self.cityBusinessConf[city][self.CUISINE_KEY]:
					self.cityBusinessConf[city][self.CUISINE_KEY].append(cuisine)
		 

		#print ','.join(self.cityBusinessConf[city][self.CUISINE_KEY])


	def getCity(self, crumb):
		crumb = crumb.strip()
		city = crumb
		for suffix in self.crumbSuffixList:
			if crumb.endswith(suffix):
				city = re.sub(suffix, '', crumb)
				break
		return city


	def normlizeRestaurantCrumb(self, crumbKey, crumbVal):
		#print crumbVal
		normKVDict = dict()
		normKVDict[crumbKey] = crumbVal
		valSegs = crumbVal.split('>')
		city = self.getCity(valSegs[0])
		if city not in self.cityBusinessConf:
			return normKVDict
		normKVDict[self.CITY_KEY] = city

		cityConfMap = self.cityBusinessConf[city]		
		# set default value
		normKVDict[self.AREA_KEY] = '����'
		normKVDict[self.CUISINE_KEY] = '����'
		normKVDict[self.DISTRICT_KEY] = '����'
		
		#cuisineIdx = -1
		#for idx in xrange(1, len(valSegs)):
		#	val = valSegs[idx].strip()
		#	if val in cityConfMap[self.AREA_KEY]:
		#		normKVDict[self.AREA_KEY] = val	
		#	elif val in cityConfMap[self.CUISINE_KEY]:
		#		normKVDict[self.CUISINE_KEY] = val	
		#		cuisineIdx = idx
		#	elif val in cityConfMap[self.DISTRICT_KEY]:
		#		normKVDict[self.DISTRICT_KEY] = val	
		# �����ϵ��idx �� ���̵�idx ���2 ˵�����Ӳ�ϵ���м�
		#if cuisineIdx == len(valSegs) -3:
		#	normKVDict[self.SUB_CUISINE_KEY] = valSegs[cuisineIdx + 1].strip()

		# �µĽ�����ʽ
		cuisineIdx = -1
		for idx in xrange(1, len(valSegs)):
			val = valSegs[idx].strip()
			# ��
			if val in cityConfMap[self.AREA_KEY]:
				normKVDict[self.AREA_KEY] = val	
			# ��Ȧ
			elif val in cityConfMap[self.DISTRICT_KEY]:
				normKVDict[self.DISTRICT_KEY] = val	
				key = '%s\t%s' % (city, val)
				if key in self.cityBusinessAreaDict:
					normKVDict[self.AREA_KEY] = self.cityBusinessAreaDict[key]
			# �˵�
			elif val in cityConfMap[self.CUISINE_KEY]:
				normKVDict[self.CUISINE_KEY] = val	
				cuisineIdx = idx
				# �Ӳ˵�
				if cuisineIdx == len(valSegs) -3:
					normKVDict[self.SUB_CUISINE_KEY] = valSegs[cuisineIdx + 1].strip()
					break
	
		
		return normKVDict
		

	def normlizePlayCrumb(self, crumbKey, crumbVal):
		#print crumbVal
		normKVDict = dict()
		normKVDict[crumbKey] = crumbVal
		valSegs = crumbVal.split('>')
		city = self.getCity(valSegs[0])
		if city not in self.cityBusinessConf:
			return normKVDict
		normKVDict[self.CITY_KEY] = city

		cityConfMap = self.cityBusinessConf[city]
		# set default value
		normKVDict[self.AREA_KEY] = '����'
		normKVDict[self.TYPE_KEY] = '����'
		normKVDict[self.SUBTYPE_KEY] = '����'
		normKVDict[self.DISTRICT_KEY] = '����'

		for idx in xrange(1, len(valSegs)):
			val = valSegs[idx].strip()
			if val in cityConfMap[self.AREA_KEY]:
				normKVDict[self.AREA_KEY] = val	
			elif val in self.playTypeConfDict:
				normKVDict[self.SUBTYPE_KEY] = val	
			elif val in cityConfMap[self.DISTRICT_KEY]:
				normKVDict[self.DISTRICT_KEY] = val	
		if normKVDict[self.SUBTYPE_KEY] in self.playTypeConfDict:
			normKVDict[self.TYPE_KEY] = self.playTypeConfDict[normKVDict[self.SUBTYPE_KEY]]
		
		# �����Ȱ�<type subtype>�ֱ�ӳ�䵽<��ϵ���Ӳ�ϵ>��Ŀ������һ��תtableʱ����
		normKVDict[self.CUISINE_KEY] = normKVDict[self.TYPE_KEY]
		normKVDict[self.SUB_CUISINE_KEY] = normKVDict[self.SUBTYPE_KEY]

		#for key in normKVDict:
		#	print key, normKVDict[key]
		#print '=============='
		
		return normKVDict



# ��һ�����ڵ���������ߣ���ȡ���У���������ϵ�ֶ�
# e.g. �������� > ������ > ��ͷ��Ƽ�
# e.g. �������� > ������ > ����� > �Ϲ�԰(��ֱ�ŵ�)
# e.g. �������� > ������ > ������ > �½��� > �½�����ʳ��
# e.g. �������� > ������ > ���⾭ó > ���� > ����/�ҳ��� > �ֵܴ���(Ԫ�󶼵�)
def normDianpingFoodBreadCrumb(key, val):
	normKVDict = dict()
	normKVDict[key] = val
	if len(key) == 0 or len(val) == 0:
		return normKVDict
	valSegs = val.split('>')
	if valSegs[0].find('����') != '':
		city = re.sub('����', '', valSegs[0].strip())
		normKVDict['city'] = city
	if len(valSegs) == 4:
		normKVDict['cuisine'] = valSegs[2].strip()
	if len(valSegs) == 6:
		normKVDict['subcuisine'] = valSegs[4].strip()
	if len(valSegs) >= 4:
		normKVDict['area'] = valSegs[1].strip()
	if len(valSegs) >= 5:
		normKVDict['district'] = valSegs[2].strip()
		normKVDict['cuisine'] = valSegs[3].strip()
	return normKVDict



# ��һ�����ڵ������ĵ绰
# �������ĵ绰����  e.g. http://www.dianping.com/shop/23588151
def normDianpingFoodTel(key, val):
	normKVDict = dict()
	if len(key) == 0 or len(val) == 0:
		return normKVDict
	val = re.sub('-', '', val)
	normalVal = []
	for tel in val.split(','):
		if len(tel) < 7:
			continue
		if tel not in normalVal:
			normalVal.append(tel)
	normKVDict[key] = ','.join(normalVal)
	return normKVDict
	



# ��һ�����ڵ�����tags, commentSummary
# e.g. ��������(8),����ˢ��(8),����Լ��(4),���ͣ��(4),���Ѿ۲�(4),����С�(3),��ͥ�ۻ�(2)
def normTag(key, val):
	normKVDict = dict()
	if len(key) == 0 or len(val) == 0:
		return normKVDict
	val = re.sub('\)', '', val)
	val = re.sub('\(', '@@@', val)
	normKVDict[key] = val
	return normKVDict





# ��һ�����ڵ������Ƽ����ֶ�
# ��һ��Ϊ foodUrl@@@foodName@@@recomCnt@@@foodPhoto@@@price
def normRecommFood(key, val):
	normKVDict = dict()
	if len(key) == 0 or len(val) == 0:
		return normKVDict
	# ����Ʒ����Ҳ����ѡ�����û��ͼƬ������
	valSegs = val.split('@@@')
	if len(valSegs) == 3:
		val = val + '@@@@@@'
	normKVDict[key] = val
	return normKVDict


# ��һ�����۵�����ʱ��
def normCommentDate(key, val):
	normKVDict = dict()
	if len(key) == 0 or len(val) == 0:
		return normKVDict
	if val.find('����') != -1:
		val = re.sub('.*������', '', val)
		val = re.sub(' .*$', '', val.strip())
	# ���ڱ�������ݣ�ȥ�����
	curYear = time.strftime("%Y", time.localtime())
	curShortYear = curYear[-2:]

	if re.match('[0-9]+-[0-9]+-[0-9]+', val):
		if val.startswith(curShortYear):
			val = val.replace(curShortYear + '-', '')
		elif val.startswith(curYear):
			val = val.replace(curYear + '-', '')

	normKVDict[key] = val
	return normKVDict


def normBusinessDate(key, val):
	normKVDict = dict()
	if len(key) == 0 or len(val) == 0:
		return normKVDict
	val = val.decode('gbk', 'ignore')
	val = re.sub(u'[\s]*[����:]+[\s]*', ':', val)
	val = re.sub(u'[\s]*[\��\-��������]+[\s]*', '-', val)
	val = re.sub(u'[\s]*[~��]+[\s]*', '-', val)

	normKVDict[key] = val.encode('gbk', 'ignore')
	return normKVDict


def test_normCommentDate():
	print normCommentDate('dd', '03-09������16-05-13 10:36')
	print normCommentDate('dd', '03-09������17-05-14 10:36')
	print normCommentDate('dd', '03-09������2017-05-15 10:36')
	print normCommentDate('dd', '03-09������2016-05-16 10:36')
	print normCommentDate('dd', '03-09������ 2016-05-17 10:36')


def testNormalFun():
	print normDianpingFoodTel('tel', '15040380068,010-')


def testDPCrumbNormlizer():
	conf = "/search/liubing/spiderTask/result/dianping/task-78/1447142745681.gbk"
	testFile = '/search/zhangk/Fuwu/Source/test.dat'
	
	normlizer = DPCrumbNormlizer(conf)
	for line in open(testFile):
		#print line
		segs = line.strip('\n').split('\t')
		key, value = segs[0], segs[1]
		normlizer.normlize(key, value)


def test_normBusinessDate():
	print normBusinessDate('date', '19:00--3:00')
	print normBusinessDate('date', '9:00��18:00')
	print normBusinessDate('date', '10��00����20��00')
	print normBusinessDate('date', '��һ~����: 10:30-22:00')
	print normBusinessDate('date', '��һ�����գ�Ӫҵʱ�䣺16:00��������1:00')
	print normBusinessDate('date', '19:00-02:00 ��һ������')


#test_normCommentDate()

#test_normBusinessDate()
