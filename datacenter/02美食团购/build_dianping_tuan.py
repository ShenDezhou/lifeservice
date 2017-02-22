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



# ��ȡ������е��Ź�ȫ��
def download_all_city_deal(cityConf, inEncode='gb2312'):
	dealListFile = 'tuan/city_deal_idlist'
	download_all_city_deal_idlist(cityConf, dealListFile, inEncode)
	download_all_city_deal_detail(dealListFile)


# �������г��е��Ź��б�
def download_all_city_deal_idlist(cityConf, idListFile, inEncode='gb2312'):
	fd = open(idListFile, 'w+')
	cityList = get_city_list(cityConf, inEncode)
	for cityChName, cityCode, cityEnName in cityList:
		download_city_deal_list(cityCode, cityEnName, fd)
	fd.close()
	logging.info('download all city deal id list done.')


# �������г��е��Ź���Ϣȫ��
def download_all_city_deal_detail(dealListFile):
	logging.info('begin to get all city\'s all deal...')
	jsonTool = JsonToLine(DealExtractConf, ENCODE)
	fdMap = dict()
	# ���ظ����е�
	lineIdx = 0
	for line in open(dealListFile):
		lineIdx += 1
		if lineIdx % 10000 == 0:
			logging.info('have handle %d lines' % lineIdx)


		segs = line.strip('\n').split('\t')
		if len(segs) != 2:
			continue
		cityEnName, dealListStr = segs[0], segs[1]

		dealFile = 'tuan/%s.all' % cityEnName
		if cityEnName not in fdMap:
			fd = open(dealFile, 'a')
			fdMap[cityEnName] = fd
		get_deal_detail(dealListStr, fdMap[cityEnName], jsonTool)
	# �رմ򿪵��ļ����
	for cityEnName in fdMap:
		fdMap[cityEnName].close()



# ����ĳһ�����е��Ź��б�
def download_city_deal_list(cityCode, cityEnName, fd):
	print cityEnName
	requestUrl = (GetDealListFileAPI % (DateTimeTool.todayStr(), cityCode, cityEnName))
	print requestUrl
	logging.info('download city deal list url: %s' % requestUrl)

	response = GetRequest(requestUrl)
	jsonDict = json.loads(response)
	if StatusKey in jsonDict and jsonDict[StatusKey] == OK:
		logging.info('download %s \'s deal succ, count: %s' % (cityEnName, str(jsonDict['count'])))	
		if DealListKey not in jsonDict:
			logging.info('%s \'s return json not contain %s' % (cityEnName, DealListKey))
			return
	dealList = jsonDict[DealListKey]
	requestCnt = len(dealList) / DealCntPerRequest + 1
	for requestIdx in xrange(0, requestCnt):
		begin = requestIdx * DealCntPerRequest
		requestDealList = dealList[begin : begin + DealCntPerRequest]
		dealListStr = ','.join(requestDealList)
		fd.write('%s\t%s\n' % (cityEnName, dealListStr))




# ��ȡһ�����е�ȫ���Ź���Ϣ
def get_city_deal(cityChName, cityEnName):
	logging.info('get ' + cityEnName + '\'s all deal.')
	dealList = get_city_deal_list(cityChName)
	dealFile = 'tuan/%s.all' % cityEnName
	get_city_deal_detail(cityEnName, dealList, dealFile)



# ��ȡһ�����е��Ź��б�
def get_city_deal_list(cityChName):
	requestUrl = create_get_city_deal_list_api(cityChName)
	logging.info('get city deal list url: ' + requestUrl)
	response = GetRequest(requestUrl)
	jsonDict = json.loads(response)
	
	dealList = []
	if StatusKey in jsonDict and jsonDict[StatusKey] == OK:
		logging.info(('%s: %s' % (cityChName, str(jsonDict['count']))).encode('gb2312', 'ignore'))
		dealList = jsonDict[DealListKey]
	return dealList


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
	dealFile = 'tuan/%s.daily' % cityEnName
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




if len(sys.argv) < 2:
	print '[Usage]: python %s -[all|daily]' % sys.argv[0]
	sys.exit(-1)
opt = sys.argv[1]


# ���ظ����е��Ź�ȫ��
if opt == '-all':
	initLog('all_tuan')
	download_all_city_deal(CityConf)
elif opt == '-daily':
	initLog('daily_tuan')
	# ���ظ�����ÿ����µ��Ź���Ϣ
	date = ''
	if len(sys.argv) > 2:
		date = sys.argv[2]
	get_all_city_daily_deal(CityConf, date)
