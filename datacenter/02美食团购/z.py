#!/bin/python
#coding=gb2312
#/*******************************************************************************
# * Author	 : liubing@sogou-inc.com
# * Last modified : 2016-04-14 16:09
# * Filename	 : build_dianping_tuan.py
# * Description	 : 调用大众点评网的API更新团购信息
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

# 返回值中json键
OK = 'OK'
StatusKey = 'status'
DealListKey = 'id_list'
DealDetailKey = 'deals'

# 大众点评API的签名信息
AppKey = '343629756'
Secret = 'a54b3d169af14dd688b56fe9c4b9ebcc'

# API
GetDealListAPI = 'http://api.dianping.com/v1/deal/get_all_id_list'
GetDealDetailAPI = 'http://api.dianping.com/v1/deal/get_batch_deals_by_id'
GetDealListFileAPI = 'http://i3.dpfile.com/data/open/deals/id/%s/%s-%s.json'
GetDailyDealListAPI = 'http://api.dianping.com/v1/deal/get_daily_new_id_list'


# 用到的配置文件
CityConf = 'conf/dianping_city_code_pinyin_conf'
DealExtractConf = 'conf/dianping_deal_conf'


def initLog(logFile = 'log'):
	logging.basicConfig(level=logging.DEBUG,
                format='%(asctime)s %(filename)s[line:%(lineno)d] [%(levelname)s] %(message)s',
                datefmt='%Y-%m-%d %H:%M:%S',
                filename='logs/' + logFile + '.' + DateTimeTool.today() + '.log',
                filemode='a')


# 计算签名
def createSign(paramMap):
	codec = AppKey
	for key in sorted(paramMap.iterkeys()):
		codec += key + paramMap[key]
	codec += Secret
	sign = (hashlib.sha1(codec).hexdigest()).upper()
	return sign

# 计算获取一个城市团购列表的URL
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


# 计算获取一串团购id列表详情信息的URL
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


# 计算获取每日新增团购id列表信息的URL
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



# 获取城市列表
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


# 创建各城市全量团购数据的URL列表
def create_all_city_deal_urls(cityList, inEncode):
	urlList = []
	for cityChName, cityCode, cityEnName in cityList:
		requestUrl = (GetDealListFileAPI % (DateTimeTool.todayStr(), cityCode, cityEnName))
		urlList.append((cityEnName, requestUrl))
	logging.info('get all city\'s deal urllist done.')
	return urlList



# 获取各大城市的团购全集
def download_all_city_deal(cityConf, inEncode='gb2312'):
	dealListFile = 'tuan/city_deal_idlist'

	cityList = get_city_list(cityConf, inEncode)

	#urlList = create_all_city_deal_urls(cityList, inEncode)

	#download_all_city_deal_idlist(urlList, inEncode)

	download_all_city_deal_detail(cityList)


# 下载所有城市的团购列表
def download_all_city_deal_idlist(urlList, inEncode='gb2312'):
	if len(urlList) == 0:
		logging.info('all city\'s deal urllist is empty')
		return
	
	pool = ThreadPool(20)
	pool.map(download_city_deal_list, urlList)
	pool.close()
	pool.join()
	logging.info('get all city\'s deal idlist done.')
	



def download_all_city_deal_detail(cityList):
	idListFileList = []
	for cityChName, cityCode, cityEnName in cityList:
		idListFile = getIdlistFilePath(cityEnName)
		if os.path.exists(idListFile):
			idListFileList.append(idListFile)
	print len(idListFileList)	


# 下载所有城市的团购信息全集
def download_all_city_deal_detail_imp(dealListFile):
	logging.info('begin to get all city\'s all deal...')
	jsonTool = JsonToLine(DealExtractConf, ENCODE)
	fdMap = dict()
	# 下载各城市的
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
	# 关闭打开的文件句柄
	for cityEnName in fdMap:
		fdMap[cityEnName].close()


def getIdlistFilePath(cityEnName):
	return 'tuandata/all/%s.idlist' % cityEnName


# 下载某一个城市的团购列表
def download_city_deal_list(cityUrlPair):
	if len(cityUrlPair) != 2:
		return
	cityEnName, requestUrl = cityUrlPair

	logging.info('begin to get %s\'s all tuan idlist' % cityEnName)
	response = GetRequest(requestUrl)
	try:
		jsonDict = json.loads(response)
		if StatusKey in jsonDict and jsonDict[StatusKey] == OK:
			logging.info('download %s \'s deal succ, count: %s' % (cityEnName, str(jsonDict['count'])))	
			if DealListKey not in jsonDict:
				logging.info('%s \'s return json not contain %s' % (cityEnName, DealListKey))
				return
		fd = open(getIdlistFilePath(cityEnName), 'w+')
		dealList = jsonDict[DealListKey]
		requestCnt = len(dealList) / DealCntPerRequest + 1
		for requestIdx in xrange(0, requestCnt):
			begin = requestIdx * DealCntPerRequest
			requestDealList = dealList[begin : begin + DealCntPerRequest]
			dealListStr = ','.join(requestDealList)
			fd.write('%s\t%s\n' % (cityEnName, dealListStr))
		fd.close()
	except:
		pass



# 获取一个城市的全部团购信息
def get_city_deal(cityChName, cityEnName):
	logging.info('get ' + cityEnName + '\'s all deal.')
	dealList = get_city_deal_list(cityChName)
	dealFile = 'tuan/%s.all' % cityEnName
	get_city_deal_detail(cityEnName, dealList, dealFile)



# 获取一个城市的团购列表
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


# 获取一个城市的团购信息详情
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



# 获取一串团购列表的详情
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

# 获取各大城市的当天新增的团购信息
def get_all_city_daily_deal(cityConf, date='', inEncode='gb2312'):
	cityList = get_city_list(cityConf, inEncode)
	for cityChName, cityCode, cityEnName in cityList:
		get_city_daily_deal(cityChName, cityEnName, date)


# 获取一个城市的全部团购信息
def get_city_daily_deal(cityChName, cityEnName, date=''):
	logging.info('get ' + cityEnName + '\'s daily deal.')
	dealList = get_city_daily_deal_list(cityChName, date)
	dealFile = 'tuan/%s.daily' % cityEnName
	get_city_deal_detail(cityEnName, dealList, dealFile)


# 获取一个城市的团购列表
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


initLog('zz')
download_all_city_deal(CityConf)


'''
if len(sys.argv) < 2:
	print '[Usage]: python %s -[all|daily]' % sys.argv[0]
	sys.exit(-1)
opt = sys.argv[1]


# 下载各城市的团购全集
if opt == '-all':
	initLog('all_tuan')
	download_all_city_deal(CityConf)
elif opt == '-daily':
	initLog('daily_tuan')
	# 下载各城市每天更新的团购信息
	date = ''
	if len(sys.argv) > 2:
		date = sys.argv[2]
	get_all_city_daily_deal(CityConf, date)
'''
