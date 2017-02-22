#!/bin/bash|python
#coding=gb2312
#/*******************************************************************************
# * Author	 : liubing@sogou-inc.com
# * Last modified : 2016-04-06 17:05
# * Filename	 : merge_cinema.py
# * Description	 : 
# * *****************************************************************************/

import re, sys
from MathTool import *


DistanceThreshold = 2000



# ӰԺ��
class Cinema(object):
	def __init__(self, city, id, title, poi, addr, tel):
		self.city = city
		self.id = id
		self.title = Cinema.normalTitle(city, title)
		self.poi = Cinema.normalPoi(poi)
		self.addr = Cinema.normalAddr(city, addr)
		self.tel = Cinema.normalTel(tel)

	@staticmethod
	def normalTel(tel):
		normTelList = []
		telArray = re.split('[\s,]', tel)
		for telItem in telArray:
			telItemArray = telItem.strip().split('-')
			normTel = ''.join(telItemArray[0:min(len(telItemArray), 2)])
			if len(normTel.strip()) > 0:
				normTelList.append(normTel)
		return normTelList

	@staticmethod
	def normalTitle(city, title):
		title = re.sub(u'[\-\(\)����]', '', title)
		normTitle = re.sub(city, "", title)
		return normTitle.strip()

	@staticmethod
	def normalAddr(city, addr):
		addr = re.sub(u'��.*$', '', addr)
		addr = re.sub('\(.*$', '', addr)
		normAddr = re.sub(city + u'(��)*', '', addr)
		return normAddr.strip()
		

	@staticmethod
	def normalPoi(poi):
		poiSeg = poi.split(',')
		if len(poiSeg) != 2:
			return ('', '')
		lat, lng = float(poiSeg[0]), float(poiSeg[1])
		lat, lng = str(float('%.6f' % lat)), str(float('%.6f' % lng))
		return (lat, lng)

	def toString(self):
		return '%s\t%s\t%s\t%s\t%s' % (self.city, self.id, self.title, self.poi, self.addr)	



class SimilarTool(object):
	
	@staticmethod
	def telSame(curTel, lastTel):
		if len(curTel) == 0 or len(lastTel) == 0:
			return False
		# �н���
		curTelSet, lastTelSet = set(curTel), set(lastTel)
		if len(curTelSet.intersection(lastTelSet)) > 0:
			return True
		return False

	@staticmethod
	def isTitleSame(curTitle, lastTitle):
		if curTitle == lastTitle:
			return True
		if curTitle.find(lastTitle) != -1 or lastTitle.find(curTitle) != -1:
			return True
		return False

	@staticmethod
	def titleSimilar(curTitle, lastTitle, threshold):
		# ��Ϊǰ��׺����ֱ�ӷ���True
		if SimilarTool.isTitleSame(curTitle, lastTitle):
			return True

		curTitleSet, lastTitleSet = set(curTitle), set(lastTitle)
		curTitleLen, lastTitleLen = len(curTitleSet), len(lastTitleSet)
		minLen = lastTitleLen
		if curTitleLen < lastTitleLen:
			minLen = curTitleLen
		# ����
		commLen = len(curTitleSet.intersection(lastTitleSet))
		if commLen >= (minLen * threshold):
			return True
		return False





def load_online_cinema(cinemaFile, encoding):
	cinemaMap = dict()
	firstLine = True
	for line in open(cinemaFile):
		segs = line.strip('\n').decode(encoding, 'ignore').split('\t')
		if len(segs) != 6: continue
		if firstLine: firstLine = False; continue
		city, id, title, poi, addr, tel = segs
		cinema = Cinema(city, id, title, poi, addr, tel)
		if city not in cinemaMap:
			cinemaMap[city] = []
		cinemaMap[city].append(cinema)
	return cinemaMap



mathTool = MathTool()

def merge_cinema_imp(curCinema, onlineCinemaList):
	for cinema in onlineCinemaList:
		# poi ����Ҫ��һ����Χ֮��
		distance = mathTool.poiDistance(curCinema.poi, cinema.poi)
		if distance > DistanceThreshold:
			continue
		
		if SimilarTool.titleSimilar(curCinema.title, cinema.title, 0.8):
			return cinema
		

		if SimilarTool.telSame(curCinema.tel, cinema.tel) and SimilarTool.titleSimilar(curCinema.title, cinema.title, 0.5):
			return cinema

		# title��ͬ������
		
		# title���ƣ� tel��ͬ������
		
		# title���ƣ� addr���ƣ�����
	return None



def merge_similar_cinemas(curCinema, onlineCinemaList):
	# poi ����ȽϽ���addr�Ƚ����ƣ���������
	for cinema in onlineCinemaList:
		# poi ����Ҫ��һ����Χ֮��
		distance = mathTool.poiDistance(curCinema.poi, cinema.poi)
		if distance > DistanceThreshold:
			continue
		if not SimilarTool.titleSimilar(curCinema.title, cinema.title, 0.6):
			continue
		if SimilarTool.telSame(curCinema.tel, cinema.tel):
			return cinema
		
	 	if SimilarTool.titleSimilar(curCinema.addr, cinema.addr, 0.7):
			return cinema
	return None







def merge_cinema(onlineCinemaFile, offlineCinemaFile, encoding):
	noMergerList = []
	onlineCinemaMap = load_online_cinema(onlineCinemaFile, encoding)
	for line in open(offlineCinemaFile):
		segs = line.strip('\n').decode(encoding, 'ignore').split('\t')
		if len(segs) != 6: continue
		city, id, title, poi, addr, tel = segs
		curCinema = Cinema(city, id, title, poi, addr, tel)
		if city not in onlineCinemaMap:
			continue
		mergeCinema = merge_cinema_imp(curCinema, onlineCinemaMap[city])

		if mergeCinema == None:
			noMergerList.append(curCinema)
			continue
		print ('equal\t%s\t%s' % (curCinema.toString(), mergeCinema.toString())).encode(encoding, 'ignore')
		#print ('%s' % curCinema.toString()).encode(encoding, 'ignore')
		#print ('%s' % mergeCinema.toString()).encode(encoding, 'ignore')
		print "\n"


	# û�кϲ��ɹ��ģ����յ������ȽϽ�����ַ��������еķ���
	allCinemaList = []
	for city in onlineCinemaMap:
		for cinemaItem in onlineCinemaMap[city]:
			allCinemaList.append(cinemaItem)
	for noMergeCinema in noMergerList:
		mergeCinema = merge_similar_cinemas(noMergeCinema, allCinemaList)
		if mergeCinema != None:
			print ('similar\t%s\t%s' % (noMergeCinema.toString(), mergeCinema.toString())).encode(encoding, 'ignore')
			




merge_cinema('/fuwu/Spider/Nuomi/tmp/cinema.online', '/fuwu/Spider/Nuomi/tmp/cinema.sort', 'gb2312')




def test_load_online_cinema():
	cinemaMap = load_online_cinema('/fuwu/Spider/Nuomi/tmp/cinema.online', 'gb2312')
	print len(cinemaMap)
	total = 0
	for city in cinemaMap:
		total += len(cinemaMap[city])
	print total

#test_load_online_cinema()






	#def __init__(self, city, id, title, poi, addr, tel):
#cinema = Cinema(u'�ɶ�', '123', u'���-����Ӱ�ǣ����㳡��)', '30.942205398028985,118.74754518812234', u'�ɶ������غ�ӥ��·6����۹��ʹ㳡4¥�����Ǳ��г�,6·����ֱ�', u'0731-28829915  0731-28829510')
#print cinema.tel, cinema.poi, cinema.title, cinema.addr


#0731-28829915  0731-28829510
#0731-22915555,0731-22915158
#0760-87132677-601


#print Cinema.normalTel('0731-28829915  0731-28829510')
#print Cinema.normalTitle(u'��ɽ', u'��ɽ���-����Ӱ�ǣ����㳡��)')
#print Cinema.normalTitle(u'ʯ��ׯ', u'17.5Ӱ��(׿��Ӱ��)')


#print Cinema.normPoi('30.942205398028985,118.74754518812234')
#print Cinema.normPoi('37.5314,122.0697')

#print Cinema.normalAddr(u'�ɶ�', u'�ɶ������غ�ӥ��·6����۹��ʹ㳡4¥�����Ǳ��г�,6·����ֱ�')
