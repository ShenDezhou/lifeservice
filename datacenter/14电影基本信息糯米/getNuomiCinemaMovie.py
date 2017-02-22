#!/bin/python
#coding=gb2312

import sys, logging, time, re
from DateTimeTool import DateTimeTool as dateTool
import simplejson as json
import urllib
from JsonTool import *

today = dateTool.today()
logging.basicConfig(level=logging.DEBUG,
		format='%(asctime)s %(filename)s[line:%(lineno)d] [%(levelname)s] %(message)s',
		datefmt='%Y-%m-%d %H:%M:%S',
		filename='logs/nuomi_cinema_movie' + today + '.log',
		filemode='a')


Coding = 'GB2312'

CityConf = 'conf/nuomi_city_id_conf'
MovieExtractConf = 'conf/nuomi_movie_extract_conf'

CinemaList = 'data/nuomi_cinema_list'
MoviePlayinfo = 'tmp/playinfo_raw'
CinemaMovieRelation = 'data/nuomi_movie_cm_relation'
MovieInfo = 'data/nuomi_movie_movie'

NuomiBaseUrl = 'https://mdianying.baidu.com'
GetCityCinemaUrl = 'https://mdianying.baidu.com/api/portal/loadMoreCinema?sfrom=wise_life_service_card_wap&sub_channel=&c=%s&cc=&from=webapp&source=&pageSize=10&pageNum=%s'

CinemaListRegex = '<a href="(.*?)".*?cinema-name.*?>.*?>(.*?)<.*?cinema-address">(.*?)<'
PlayinfoJsonRegex = 'MOVIE.data = (.*?)require\(\['


CinemaNumPerPage = 10
Source = u'Ŵ�׵�Ӱ'
StatusKey, DataKey, TotalNumKey, HtmlKey = 'status', 'data', 'totalNum', 'html'



def GetRequest(url):
	time.sleep(1)
	logging.info("get url: %s" % url)
	response = ''
	try:
		response = urllib.urlopen(url).read()
	except:
		logging.error('get %s error' % url)
	return response




# ��ȡŴ�װ�����ӰԺ�ĳ����б�
def get_city_list(conf, inEncode = 'gb2312'):
	cityMap = dict()
	for line in open(conf):
		segs = line.strip('\n').decode(inEncode, 'ignore').split('\t')
		if len(segs) != 2:
			continue
		cityname, cityid = segs
		cityMap[cityid] = cityname
	return cityMap


# ����ĳ�������µ�ӰԺ�б��URL
def create_city_cinemalist_url(cityid, pageid='0'):
	getCityCinemaUrl = GetCityCinemaUrl % (cityid, pageid)
	return getCityCinemaUrl


# ��ӰԺ��page�н�����ӰԺ�б�
def parse_cinemalist(response):
	dataDict = json.loads(response)
	StatusKey, DataKey, TotalNumKey, HtmlKey = 'status', 'data', 'totalNum', 'html'
	totalNum = 0; cinemaList = []
	if StatusKey not in dataDict or DataKey not in dataDict:
		return totalNum, cinemaList
	# ������ӰԺid, ��ӰԺname
	contentDict = dataDict[DataKey]
	if TotalNumKey in contentDict:
		totalNum = contentDict[TotalNumKey]
	if HtmlKey in contentDict:
		htmlContent = contentDict[HtmlKey]
		htmlContent = re.sub('[\r\n]', '', htmlContent)
		cinemaList = re.findall(CinemaListRegex, htmlContent)
		
	return int(totalNum), cinemaList


# ��ȡָ��ĳ�����еĵ�ӰԺ�б�
def get_city_cinemalist(cityid):
	
	# ץȡӰԺ�б���ҳ
	firstPageUrl = create_city_cinemalist_url(cityid)
	response = GetRequest(firstPageUrl)
	totalNum, cinemaList = parse_cinemalist(response)
	if totalNum <= CinemaNumPerPage:
		return cinemaList

	# ����ӰԺҳ��,ץȡÿҳ
	pageNum = (totalNum / CinemaNumPerPage)
	for idx in xrange(1, pageNum+1):
		url = create_city_cinemalist_url(cityid, str(idx))
		response = GetRequest(url)
		totalNum, restCinemaList = parse_cinemalist(response)
		if totalNum == 0 or len(restCinemaList) == 0:
			break
		cinemaList += restCinemaList
	return cinemaList




# ��ȡ���г���������ӰԺ����Ϣ
def get_all_city_cinemalist(cityMap, output):
	fd = open(output, 'w+')
	for cityid in cityMap:
		cityname = cityMap[cityid]
		logging.info(("get %s cinema list" % cityname).encode(Coding, 'ignore'))
		cinemaList = get_city_cinemalist(cityid)
		
		for item in cinemaList:
			if len(item) == 0:
				continue
			fd.write(('%s\t%s\t%s\n' % (cityid, cityname, '\t'.join(item))).encode(Coding, 'ignore'))	
	fd.close()


# ��ȡ���е�ӰԺ������
def get_cinema_urllist(conf, inEncode='GB2312'):
	cinemaUrlList = []
	for line in open(conf):
		segs = line.strip('\n').split('\t')#.decode(inEncode, 'ignore').split('\t')
		if len(segs) != 5:
			continue
		cinemaurl = segs[2]
		cinemaurl = NuomiBaseUrl + re.sub('#.*$', '', cinemaurl)
		cinemaUrlList.append(cinemaurl)
	return cinemaUrlList



# ��ȡĳ��ӰԺ����Ƭ��Ϣ
def get_playinfo(url, jsonToLineTool):
	playinfoList = []
	response = GetRequest(url)
	content = re.sub('[\r\n]', '', response)
	# ��ȡӰԺ��Ƭ��json�ַ���
	match = re.search(PlayinfoJsonRegex, content)
	if match is None:
		logging.error('%s not contain playinfos' % url)
		return playinfoList

	movieInfo = match.group(1)
	movieJsonStr = movieInfo[:-1]
	# ����json
	obj = json.loads(movieJsonStr)
	return jsonToLineTool.parse(obj)


# ��ȡ����ӰԺ����Ƭ��Ϣ
def get_playinfo_of_cinema(cinemaListConf, output):
	cinemaUrlList = get_cinema_urllist(cinemaListConf)
	jsonToLineTool = JsonToLine(MovieExtractConf)
	fd = open(output, 'w+')
	for cinemaUrl in cinemaUrlList:
		cinemaid = re.sub('.*=', '', cinemaUrl)
		playinfoList = get_playinfo(cinemaUrl, jsonToLineTool)
		for playinfo in playinfoList:
			fd.write(('%s\t%s\n' % (cinemaid, playinfo)))	
	fd.close()
	logging.info('get all playinfo done.')



def normal_nuomi_date(date):
	week = re.sub('[0-9\.]', '', date).strip()
	date = re.sub('[^0-9\.]', '', date).strip()
	date = date.replace('.', '-')
	
	today = dateTool.todayStr()
	curYear = dateTool.year()
	
	normDate = '%s-%s' % (curYear, date)
	if normDate >= today:
		return week, normDate
	return '', ''



#print normal_nuomi_date(u'����04.25')



# ��ȡ����һ����Ӱ�������
def extract_normal_cm_info(playinfo, output, inEncode='GB2312'):
	fd = open(output, 'w+')
	for line in open(playinfo):
		segs = line.strip('\n').decode(inEncode, 'ignore').split('\t')
		if len(segs) != 11:
			continue

		#9344    9939    �ҵ���Ұ��Ů��  ����04.25       12:20   14:07   16.6    7��     ����    2D      javascript:void(0);
		#cinemaid  movieid  source  date  week  start  end  price  ting  language  3d  ticketurl
		#1000031 6205    ΢�ŵ�ӰƱ      2016-04-22      ����    10:10   11:58   43      9����   ����    2D      http://m.wepiao.com
		# ������Ч��ticketUrl
		if segs[10].find('javascript:')	!= -1:
			continue

		# ��һ������
		date = segs[3]
		week, date = normal_nuomi_date(date)
		if len(week) == 0 or len(date) == 0:
			continue
		
		# ������Ҫ���һ�����ˣ���URL�е�ʱ��Ҫ��ʵ�ʵ���ӳʱ��һ��
		dateTimestamp = segs[10]
		dateTimestamp = re.sub('.*&date=', '', dateTimestamp)
		dateTimestamp = re.sub('&.*', '', dateTimestamp)
		onlineDate = dateTool.sec2time(dateTimestamp[:-3])
		if onlineDate.strip() != date.strip():
			continue

		segs[10] = NuomiBaseUrl + segs[10]

		# ��ȡǰ�����Ϣ���������Ϣ
		prefixInfo = '\t'.join(segs[0:2])
		suffixInfo = '\t'.join(segs[4:11])
		
		fd.write(('%s\t%s\t%s\t%s\t%s\n' % (prefixInfo, Source, date, week, suffixInfo)).encode(Coding, 'ignore'))	
	fd.close()
	logging.info('extract and normal cinema-movie-relation info done.[%s]' % output)




# ��ȡ����һ����Ӱ�������
def extract_normal_movie_info(playinfo, output, inEncode='GB2312'):
	# ȥ�أ���һ����Ӱ����
	movieInfoMap = dict()
	for line in open(playinfo):
		segs = line.strip('\n').decode(inEncode, 'ignore').split('\t')
		if len(segs) != 11:
			continue
		movieid, moviename = segs[1], segs[2]
		movieInfoMap[movieid] = moviename

	# �����Ӱ��ȫ������
	fd = open(output, 'w+')
	for movieid in movieInfoMap:
		moviename = movieInfoMap[movieid]
		fd.write(('%s\t%s\t%s\t0\tdirector\n' % (Source, movieid, moviename)).encode(Coding, 'ignore'))	
	fd.close()
	logging.info('extract and normal movie info  done.[%s]' % output)



# ��ȡ cinema  movie  cinema_movie_relation ��Ϣ
def normal_cinema_movie_info(cinemaFile, playinfoFile, inEncode='GB2312'):
	# ��ȡ & ��һ����Ӱ����
	extract_normal_movie_info(playinfoFile, MovieInfo)

	# ��ȡ & ��һ����Ƭ��Ϣ
	extract_normal_cm_info(playinfoFile, CinemaMovieRelation)
	logging.info('all done.')



# ��ȡŴ������ӰԺ�б�
#get_all_city_cinemalist(get_city_list(CityConf), CinemaList)


# ��ȡ����ӰԺ����Ƭ��Ϣ
get_playinfo_of_cinema(CinemaList, MoviePlayinfo)


# ��ȡ cinema  movie  cinema_movie_relation ��Ϣ
normal_cinema_movie_info(CinemaList, MoviePlayinfo)
