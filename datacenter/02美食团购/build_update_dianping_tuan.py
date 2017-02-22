#!/bin/python
#coding=gb2312
#/*******************************************************************************
# * Author	 : liubing@sogou-inc.com
# * Last modified : 2016-04-14 16:09
# * Filename	 : build_dianping_tuan.py
# * Description	 : ���ô��ڵ�������API�����Ź���Ϣ
# * *****************************************************************************/

import hashlib, urllib, urllib2, time, logging
from HttpRequestTool import *
import simplejson as json
from JsonTool import JsonToLine
from DateTimeTool import DateTimeTool
from multiprocessing.dummy import Pool as ThreadPool
import os.path


ENCODE = 'GB2312'
DealCntPerRequest = 40

# ����ֵ��json��
OK = 'OK'
StatusKey = 'status'
DealListKey = 'id_list'
DealDetailKey = 'deals'

# ���ڵ���API��ǩ����Ϣ
AppKey = '343629756'
Secret = 'a54b3d169af14dd688b56fe9c4b9ebcc'

# API
GetDealListAPI = 'http://api.dianping.com/v1/deal/get_all_id_list'
GetDealDetailAPI = 'http://api.dianping.com/v1/deal/get_batch_deals_by_id'
GetDealListFileAPI = 'http://i3.dpfile.com/data/open/deals/id/%s/%s-%s.json'
GetDailyDealListAPI = 'http://api.dianping.com/v1/deal/get_daily_new_id_list'
GetUpdateDealListAPI = 'http://api.dianping.com/v1/deal/get_incremental_id_list'

# �õ��������ļ�
CityConf = 'conf/dianping_city_code_pinyin_conf'
CategoryConf = 'conf/dianping_category'

DealExtractConf = 'conf/dianping_deal_conf'
UpdateIDExtractConf = 'conf/dianping_update_idlist_conf'

# Ĭ�ϻ�ȡһ���ϴ�update��ʱ��
UpdateLastHour = 10



def initLog(logFile = 'log'):
	logging.basicConfig(level=logging.DEBUG,
                format='%(asctime)s %(filename)s[line:%(lineno)d] [%(levelname)s] %(message)s',
                datefmt='%Y-%m-%d %H:%M:%S',
                filename='logs/' + logFile + '.' + DateTimeTool.today() + '.log',
                filemode='a')


# ����ǩ��
def createSign(paramMap):
	codec = AppKey
	for key in sorted(paramMap.iterkeys()):
		codec += key + paramMap[key]
	codec += Secret
	sign = (hashlib.sha1(codec).hexdigest()).upper()
	return sign



# �����ȡ�����Ź�ID��API�ӿ�
def create_get_city_update_deal_list_api(cityChName, lastUpdateTime='', category=''):
	if len(lastUpdateTime) == 0:
		lastUpdateTime = DateTimeTool.nHoursAgoStr(UpdateLastHour)
	if len(category) == 0:
		category = u'��ʳ,��������,�������,����,����'

	paramSet = []
	paramSet.append(("city", cityChName.encode('utf8', 'ignore')))
	paramSet.append(("begin_time", lastUpdateTime))
	paramSet.append(("category", category.encode('utf8', 'ignore')))
	paramMap = dict()
	for pair in paramSet:
		paramMap[pair[0]] = pair[1]

	sign = createSign(paramMap)
	urlTrail = 'appkey=%s&sign=%s' % (AppKey, sign)

	for pair in paramSet:
		urlTrail += ('&%s=%s' % (pair[0], queryUrlEncode(pair[1])))
	requesturl = '%s?%s' % (GetUpdateDealListAPI, urlTrail)
	return requesturl








# �����ȡһ�������Ź��б��URL
def create_get_city_deal_list_api(cityChName):
	paramSet = []
	paramSet.append(("city", cityChName.encode('utf8', 'ignore')))
	paramMap = dict()
	for pair in paramSet:
		paramMap[pair[0]] = pair[1]

	sign = createSign(paramMap)
	urlTrail = 'appkey=%s&sign=%s' % (AppKey, sign)

	for pair in paramSet:
		urlTrail += ('&%s=%s' % (pair[0], queryUrlEncode(pair[1])))
	requesturl = '%s?%s' % (GetDealListAPI, urlTrail)
	return requesturl


# �����ȡһ���Ź�id�б�������Ϣ��URL
def create_get_deal_detail_api(idsStr):
	paramSet = []
	paramSet.append(("deal_ids", idsStr))
	paramMap = dict()
	for pair in paramSet:
		paramMap[pair[0]] = pair[1]

	sign = createSign(paramMap)
	urlTrail = 'appkey=%s&sign=%s' % (AppKey, sign)

	for pair in paramSet:
		urlTrail += ('&%s=%s' % (pair[0], pair[1]))
	requesturl = '%s?%s' % (GetDealDetailAPI, urlTrail)
	return requesturl


# �����ȡÿ�������Ź�id�б���Ϣ��URL
def create_get_city_daily_deal_list_api(cityChName, date=''):
	if len(date) == 0:
		date = DateTimeTool.todayStr()
	paramSet = []
	paramSet.append(("city", cityChName.encode('utf8', 'ignore')))
	paramSet.append(("date", date))
	paramMap = dict()
	for pair in paramSet:
		paramMap[pair[0]] = pair[1]

	sign = createSign(paramMap)
	urlTrail = 'appkey=%s&sign=%s' % (AppKey, sign)

	for pair in paramSet:
		urlTrail += ('&%s=%s' % (pair[0], queryUrlEncode(pair[1])))
	requesturl = '%s?%s' % (GetDailyDealListAPI, urlTrail)
	return requesturl



# ��ȡ�����б�
def get_city_list(cityConf, inEncode='gb2312'):
	logging.info('get city list done.')
	cityList = []
	for line in open(cityConf):
		segs = line.strip('\n').decode(inEncode, 'ignore').split('\t')
		if len(segs) != 3:
			continue
		cityChName, cityCode, cityEnName = segs[0], segs[1], segs[2]
		cityList.append((cityChName, cityCode, cityEnName))
	return cityList


# ��ȡ����б�
def get_category_list(categoryConf, inEncode='gb2312'):
	logging.info('get category list done.')
	categoryList = []
	for line in open(categoryConf):
		line = line.strip('\n').decode(inEncode, 'ignore')
		if line.startswith('#'):
			continue
		categoryList.append(line)
	return categoryList



# ��ȡһ���Ź��б������
def get_deal_detail(dealList, fd, jsonTool):
	if isinstance(dealList, list):
		dealList = ','.join(dealList)

	requestUrl = create_get_deal_detail_api(dealList)
	logging.info('get ' + requestUrl + ' done.')
	#time.sleep(1)
	try:
		response = GetRequest(requestUrl)
		jsonDict = json.loads(response)
		if StatusKey in jsonDict and jsonDict[StatusKey] == OK:
			logging.info('deal count: %s' % str(jsonDict['count']))
			for deal in jsonDict[DealDetailKey]:
				for line in jsonTool.parse(deal):
					fd.write('%s\n' % line)
	except:
		logging.error('%s' % requestUrl)
		return


# �����и��µ��Ź�ID���ļ�·��
def getUpdateIDsFilePath(cityEnName):
	return 'tuandata/update/%s.ids' % cityEnName

# ������µ��Ź���Ϣ�ļ�·��
def getUpdateDealFilePath(cityEnName):
	return 'tuandata/update/%s.data' % cityEnName


def get_update_idlist_imp(cityUrlPair):
	if len(cityUrlPair) != 2:
		return
	cityEnName, requestUrl = cityUrlPair
	logging.info('begin to get %s\'s update tuan idlist' % cityEnName)
	try:
		response = GetRequest(requestUrl)
		jsonDict = json.loads(response)
		if StatusKey not in jsonDict or jsonDict[StatusKey] != OK:
			logging.info('download %s \'s update deal failed' % cityEnName)
			return
		if DealListKey not in jsonDict:
			logging.info('%s \'s return json not contain %s' % (cityEnName, DealListKey))
			return

		jsonTool = JsonToLine(UpdateIDExtractConf, ENCODE)
		updateidsList = jsonTool.parse(jsonDict[DealListKey])
		if len(updateidsList) == 0:
			logging.info('%s \'s update ids is empty' % cityEnName)
			return
		fd = open(getUpdateIDsFilePath(cityEnName), 'w+')
		for line in updateidsList:
			fd.write('%s\n' % line)
		fd.close()
	except:
		pass
		

# ��ȡ������״̬�б仯���Ź�ID�б�
def get_update_idlist(updateUrlList):
	if len(updateUrlList) == 0:
		return
	
	pool = ThreadPool(20)
	pool.map(get_update_idlist_imp, updateUrlList)
	pool.close()
	pool.join()
	logging.info('get all city\'s update deal ids done.')

	


# ��ȡ��Ҫ��������еĸ�������URL�б�
def get_all_update_tuan_urllist(cityList, categoryList, lastUpdateTime=''):
	updateUrlList = []
	for cityChName, cityCode, cityEnName in cityList:
		for category in categoryList:
			requestUrl = create_get_city_update_deal_list_api(cityChName, lastUpdateTime, category)
			updateUrlList.append((cityEnName, requestUrl))
	return updateUrlList


def extract_update_idlist(updateIDFile):
	updateIDList = []
	if not os.path.exists(updateIDFile):
		return updateIDList
	# ��ȡ״ֵ̬Ϊ2,�������仯��id
	idList = []
	for line in open(updateIDFile):
		segs = line.strip('\n').split('\t')
		if len(segs) != 2:
			continue
		id, status = segs
		if status != '2':
			continue
		idList.append(id)
	# ÿ40�����һ��
	requestCnt = len(idList) / DealCntPerRequest + 1
	for requestIdx in xrange(0, requestCnt):
		begin = requestIdx * DealCntPerRequest
		idGroup = ','.join(idList[begin : begin + DealCntPerRequest])
		updateIDList.append(idGroup)
	return updateIDList


def get_update_deals_imp(cityFilePair):
	if len(cityFilePair) != 2:
		return
	cityEnName, updateIDFile = cityFilePair

	updateDealList = extract_update_idlist(updateIDFile)

	if (updateDealList) == 0:
		return

	logging.info('begin to get %s\'s all update deal...' % cityEnName)
	dealFile = getUpdateDealFilePath(cityEnName)
	fd = open(dealFile, 'w+')
	jsonTool = JsonToLine(DealExtractConf, ENCODE)
	for dealListStr in updateDealList:
		get_deal_detail(dealListStr, fd, jsonTool)
	fd.close()
	logging.info('get %s\'s all deal done.' % cityEnName)


# �����и��µ��Ź�ID�б���ȡ�и��µ��Ź�����
def get_update_deals(cityList):
	logging.info('begin to get all city\'s update deals ...')
	cityFileList = []
	for cityChName, cityCode, cityEnName in cityList:
		filePath = getUpdateIDsFilePath(cityEnName)
		cityFileList.append((cityEnName, filePath))
	if len(cityFileList) == 0:
		return
	pool = ThreadPool(20)
	pool.map(get_update_deals_imp, cityFileList)
	pool.close()
	pool.join()
	logging.info('get all city\'s update deals done.')
		


# ��ȡ�������и��±仯���Ź�����
def get_update_city_daily_deal(cityConf, lastUpdateTime='', inEncode='gb2312'):
	# ������
	#0�������ߣ�1�������ߣ�2�����ݱ��
	cityList = get_city_list(cityConf, inEncode)
	categoryList = get_category_list(CategoryConf, inEncode)

	updateUrlList = get_all_update_tuan_urllist(cityList, categoryList, lastUpdateTime)

	get_update_idlist(updateUrlList)

	get_update_deals(cityList)



initLog('update_tuan')
get_update_city_daily_deal(CityConf)




