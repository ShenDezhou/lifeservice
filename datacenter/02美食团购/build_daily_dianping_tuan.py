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


# �õ��������ļ�
CityConf = 'conf/dianping_city_code_pinyin_conf'
DealExtractConf = 'conf/dianping_deal_conf'


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



def getDailyTuanFilePath(cityEnName):
	return 'tuandata/daily/%s.data' % cityEnName



# ��ȡһ�����е��Ź���Ϣ����
def get_city_deal_detail(cityEnName, dealList, resultFile):
	logging.info('get ' + cityEnName + '\'s deals.')
	jsonTool = JsonToLine(DealExtractConf, ENCODE)
	logging.info('result of ' + cityEnName + ' is ' + resultFile)
	fd = open(resultFile, 'w+')
	#fd = open(resultFile, 'a')

	requestCnt = len(dealList) / DealCntPerRequest + 1
	for requestIdx in xrange(0, requestCnt):
		begin = requestIdx * DealCntPerRequest
		requestDealList = dealList[begin : begin + DealCntPerRequest]
		get_deal_detail(','.join(requestDealList), fd, jsonTool)
	fd.close()



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


# ====================================================================================================

# ��ȡ������еĵ����������Ź���Ϣ
def get_all_city_daily_deal(cityConf, date='', inEncode='gb2312'):
	cityList = get_city_list(cityConf, inEncode)
	for cityChName, cityCode, cityEnName in cityList:
		get_city_daily_deal(cityChName, cityEnName, date)


# ��ȡһ�����е�ȫ���Ź���Ϣ
def get_city_daily_deal(cityChName, cityEnName, date=''):
	logging.info('get ' + cityEnName + '\'s daily deal.')
	dealList = get_city_daily_deal_list(cityChName, date)
	dealFile = getDailyTuanFilePath(cityEnName)
	get_city_deal_detail(cityEnName, dealList, dealFile)


# ��ȡһ�����е��Ź��б�
def get_city_daily_deal_list(cityChName, date=''):
	requestUrl = create_get_city_daily_deal_list_api(cityChName, date)
	logging.info('get city daily deal list url: ' + requestUrl)
	response = GetRequest(requestUrl)
	jsonDict = json.loads(response)
	
	dealList = []
	if StatusKey in jsonDict and jsonDict[StatusKey] == OK:
		logging.info(('%s: %s' % (cityChName, str(jsonDict['count']))).encode('gb2312', 'ignore'))
		dealList = jsonDict[DealListKey]
	return dealList


initLog('daily_tuan')
date = ''
if len(sys.argv) > 1:
	date = sys.argv[1]
get_all_city_daily_deal(CityConf, date)

