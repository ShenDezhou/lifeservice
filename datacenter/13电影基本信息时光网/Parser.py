#!/bin/python
#coding=gbk

import sys, re
import logging
import copy
import simplejson as json

from keyConfig import *
from DateTimeTool import DateTimeTool as dateTool

class CtimeCinemaParser:
	infoRegex = '.*cinemaShowtimesScriptVariables = (.*)'
	
	filmInfoRegex = '.*<div class="filminfo">(.*?)<div>'
	
	# IMAX: ico_c_f01   3D: ico_c_f02  VIP:ico_c_f03  �й���Ļ:ico_c_f04  DOBLY:ico_c_f06  4k:ico_c_f08  ��ͣ����ico_c_f14
	# ��ˢ��:ico_c_f12  WIFI:ico_c_f13  ȡƱ����ico_c_f25
	IMAX_FLAG = 'ico_c_f01'
	VIP_FLAG = 'ico_c_f03'

	roomNumRegex = '.*<p class="lovetxt"><b>([0-9]+)</b>��Ӱ��'
	seatNumRegex = '.*<p class="lovetxt"><b>([0-9]+)</b>����λ'
	businessTimeRegex = '.*Ӫҵʱ�䣺([^<]+)</span>'
	loveRateRegex = '.*<li class="lovepic">.*?<i>.*?"([0-9]+)".*?<li>'


	id, title, addr, tel = '', '', '', ''
	lat, lng, roomNum, seatNum = '', '', '', ''
	hasIMAX, hasVIP = False, False
	cityid, businessTime, rate = '', '', ''

	def __init__(self):
		# config log format
		today = dateTool.today()
		logging.basicConfig(level=logging.DEBUG,
                format='%(asctime)s %(filename)s[line:%(lineno)d] [%(levelname)s] %(message)s',
                datefmt='%Y-%m-%d %H:%M:%S',
                filename='logs/CtimeCinemaParser_' + today + '.log',
                filemode='a')
		logging.info('init CtimeCinemaParser')
		

	def loadConfFile(self, conf):
		for line in open(conf):
			line = line.strip('\n')
			if len(line) == 0 or line.startswith('#'):
				continue
			segs = line.split('\t')
			if len(segs) != 3:
				continue
			type, key, regex = segs[0], segs[1], segs[2]
			if type not in self.confMap:
				map = dict()
				self.confMap[type] = map
			self.confMap[type][key] = regex


	def printItemList(self, itemList, fd):
		for item in itemList:
			fd.write("%s\n" % item)

	
	# ����key�б��map�л�ȡ��Ӧval������
	def getValueList(self, keyList, kvMap):
		valueList = []
		for key in keyList:
			value = ''
			if key in kvMap:
				value = kvMap[key]
				valueList.append(value)
		return valueList

	# �Ƿ�list��Ԫ��Ϊ��
	def isListItemAllEmpty(self, list):
		for item in list:
			if len(item) != 0:
				return False
		return True


	def normalValue(self, value):
		value = value.strip()
		value = re.sub('\t', ' ', value)
		value = value.replace('<![CDATA[', '')
		value = value.replace(']]>', '')
		return value.strip()

	def getRegexValue(self, regex, content):
		findList = re.findall(regex, content)
		if len(findList) == 0:
			return ''
		value = findList[0]
		return self.normalValue(value)



	# ����ӰԺ����λ�����ṩ�ķ������Ϣ
	def parseCinemaServiceInfo(self, content):
		#roomNum = self.getRegexValue(self.roomNumRegex, content)
		#seatNum = self.getRegexValue(self.seatNumRegex, content)
		self.businessTime = self.getRegexValue(self.businessTimeRegex, content)

		content = self.getRegexValue(self.filmInfoRegex, content)
		if content.find(self.IMAX_FLAG) != -1:
			self.hasIMAX = True
		if content.find(self.VIP_FLAG) != -1:
			self.hasVIP = True
	

	# ���������JSON����
	def parseShowtimeJson(self, line):
		matchGroup = re.match(self.infoRegex, line)
		if not matchGroup:
			return
		infoJson = matchGroup.group(1)
		cityidRegex = '.*"cityid":([0-9]+)'
		cinemaIdRegex = '.*"cinemaId":([0-9]+),'
		cinemaNameRegex = '.*"namecn":"([^"]+)"'
		cinemaAddrRegex = '.*"address":"([^"]+)"'
		cinemaTelRegex = '.*"telphone":"([^"]+)"'
		lngRegex = '.*"longitude":([0-9\.]+)'
		latRegex = '.*"latidude":([0-9\.]+)'
		rateRegex = '.*"rating":([0-9\.]+)'

		self.id = self.getRegexValue(cinemaIdRegex, line)
		self.cityid = self.getRegexValue(cityidRegex, line)
		self.title = self.getRegexValue(cinemaNameRegex,line)
		self.addr = self.getRegexValue(cinemaAddrRegex,line)
		self.tel = self.getRegexValue(cinemaTelRegex,line)
		self.lng = self.getRegexValue(lngRegex,line)
		self.lat = self.getRegexValue(latRegex,line)
		self.rate = self.getRegexValue(rateRegex,line)

	def parse(self, file):
		content = ''
		for line in open(file):
			line = line.strip()
			content += line
			# ���д���ӰԺ��Ϣ��json����
			self.parseShowtimeJson(line)
			# ȫ�����ݴ�������
		self.parseCinemaServiceInfo(content)
		print ("%s\t%s\t%s\t%s\t%s\t%s,%s\t%s\t%d\t%s" % (self.cityid, self.id, self.title, self.addr, self.tel, self.lat, self.lng, self.businessTime, self.hasIMAX, self.rate))



if __name__ == '__main__':
	input = sys.argv[1]
	parser = CtimeCinemaParser()
	parser.parse(input)



