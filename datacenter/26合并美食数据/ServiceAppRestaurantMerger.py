#!/bin/python
#coding=gb2312

import sys, re, logging
from MathTool import *
from DateTimeTool import DateTimeTool as dateTool

DEBUG = True
DEBUG = False


# ������־
today = dateTool.today()
logging.basicConfig(level=logging.DEBUG,
                format='%(asctime)s %(filename)s[line:%(lineno)d] [%(levelname)s] %(message)s',
                datefmt='%Y-%m-%d %H:%M:%S',
                filename='logs/ServiceAppMerger_' + today + '.log',
                filemode='w+')


class Item:
	# ���캯��
	def __init__(self, id, title, domain, tel, area, addr, poi):
		self.id = id
		self.poi = poi
		self.tel = tel
		self.area = area
		self.addr = addr
		self.title = title
		self.domain = domain



# �������APP��Ŀ ��ʳ�̵�ĺϲ���
class RestaurantMerger:
	
	sep, telSep = '\t', '|'
	idRow, urlRow, titleRow = -1, -1, -1
	telRow, areaRow, addrRow, poiRow = -1, -1, -1, -1

	def __init__(self):
		self.lastID, self.lastUrl = '', ''
		self.lastTitle, self.lastTel = '', ''
		self.lastArea, self.lastAddr = '', ''
		self.lastPoiStr = ''
		self.lastPoi = ('', '')
		self.mathTool = MathTool()
		
		# ����ʹ��
		self.debugDistance = ''
		self.debugAddrDis = ''


	def getDomain(self, url):
		urlSegs = url.split('/')
		if len(urlSegs) > 2:
			return urlSegs[2]


	def normalPoi(self, poiStr):
		poiSeg = poiStr.split(',')
		if len(poiSeg) != 2:
			return ('', '')
		lat, lng = float(poiSeg[0]), float(poiSeg[1])
		lat = str(float("%.3f" % lat))
		lng = str(float("%.3f" % lng))
		return (lat, lng)

	
	def telSame(self, curTel, lastTel):
		curTelSet = set(curTel.split(self.telSep))
		lastTelSet = set(lastTel.split(self.telSep))
		# �н���
		if len(curTelSet.intersection(lastTelSet)) > 0:
			return True
		return False


	# ��ַ���淶����һ�£�ʹ��LCS���ʺ�
	# ֱ�Ӽ�����ͬ���ַ�������(��ȱ�ݵķ���)
	def addrSimilar(self, curAddr, lastAddr):
		curAddrSet, lastAddrSet = set(curAddr), set(lastAddr)
		curAddrLen, lastAddrLen = len(curAddrSet), len(lastAddrSet)
		minLen = lastAddrLen
		if curAddrLen < lastAddrLen:
			minLen = curAddrLen
		# ����
		commLen = len(curAddrSet.intersection(lastAddrSet))
		if commLen >= (minLen * 0.6):
			if DEBUG:
				#print '[Right]:', curAddr, lastAddr
				self.debugAddrDis = 'commLen= ' + str(commLen) + ', minLen=' + str(minLen) + ', ratio=' + str(float(commLen) / minLen) + ', curAddr=[' + curAddr + '],  lastAddr=[' + lastAddr + ']'
			return True
		if DEBUG:
			#print '[Error]:', curAddr, lastAddr
			self.debugAddrDis = 'commLen= ' + str(commLen) + ', minLen=' + str(minLen) + ', ratio=' + str(float(commLen) / minLen) + ', curAddr=[' + curAddr + '],  lastAddr=[' + lastAddr + ']'
		return False


	# ��Ϊ������ 1km ֮��Ķ���ͬ
	def distanceNear(self, curPoi, lastPoi):
		distance = self.mathTool.poiDistance(curPoi, lastPoi)
		if distance <= 1000:
			self.debugDistance = distance
			return True
		self.debugDistance = distance
		return False


	def getKeyRow(self, headLine):
		segs = headLine.split(self.sep)
		for row in xrange(0, len(segs)):
			if segs[row] == 'id': self.idRow = row
			elif segs[row] == 'url': self.urlRow = row
			elif segs[row] == 'tel': self.telRow = row
			elif segs[row] == 'poi': self.poiRow = row
			elif segs[row] == 'area': self.areaRow = row
			elif segs[row] == 'addr': self.addrRow = row
			elif segs[row] == 'title': self.titleRow = row


	# �绰������ͬ��������ͬ��������ͬ
	def mergeByTel(self, file):
		lastSameTelList = []
		isFirstLine = True

		for line in open(file):
			line = line.strip('\n')
			if isFirstLine:
				isFirstLine = False
				self.getKeyRow(line)
				continue
			
			segs = line.split(self.sep)

			curID = segs[self.idRow]
			curUrl, curTitle = segs[self.urlRow], segs[self.titleRow]
			curArea, curTel = segs[self.areaRow], segs[self.telRow]
			curAddr, curPoi = segs[self.addrRow], self.normalPoi(segs[self.poiRow])

			if len(curTel) < 7: continue
			distance = self.mathTool.poiDistance(curPoi, self.lastPoi)
			# ����Ҳ�ø�
			if self.lastTel == curTel:
				if curArea == self.lastArea and \
					self.getDomain(self.lastUrl) != self.getDomain(curUrl):
					# ����Ӧ����һ����Χ��
					if DEBUG:
						#self.debugAddrDis = 'commLen= ' + str(commLen) + ', minLen=' + str(minLen) + ', ratio=' + str(float(commLen) / minLen) + ', curAddr=[' + curAddr + '],  lastAddr=[' + lastAddr + ']'
						self.debugAddrDis = 'curAddr=[' + curAddr + '],  lastAddr=[' + self.lastAddr + ']'
						print '\t[debug]: curAddr=[' + curAddr + '],  lastAddr=[' + self.lastAddr + ']'
					if self.distanceNear(curPoi, self.lastPoi):
						print 'tel\t' + curID + '\t' + self.lastID + '\t' + str(distance)
			
			self.lastID, self.lastUrl = curID, curUrl
			self.lastTel, self.lastTitle = curTel, curTitle
			self.lastArea, self.lastAddr = curArea, curAddr
			self.lastPoi = curPoi

	
	# ������ͬ��domain��ͬ��area��ͬ
	# �绰���� or ��ַ���� or poi������һ����Χ
	def mergeByTitle(self, file):
		lastSameTitleList = []
		isFirstLine = True
		lineNum = 0

		for line in open(file):
			lineNum += 1
			if lineNum % 1000 == 0:
				logging.info("has handle %d lines" % lineNum)			
			line = line.strip('\n')
			if isFirstLine:
				isFirstLine = False
				self.getKeyRow(line)
				continue

			segs = line.split(self.sep)
			
			curID = segs[self.idRow]
			curUrl, curTitle = segs[self.urlRow], segs[self.titleRow]
			curArea, curTel = segs[self.areaRow], segs[self.telRow]
			curAddr, curPoi = segs[self.addrRow], self.normalPoi(segs[self.poiRow])
			curDomain = self.getDomain(curUrl)

			if len(curTitle) == 0: continue

			if curTitle == self.lastTitle:
				for lastItem in lastSameTitleList:
					if curArea == lastItem.area and curDomain != lastItem.domain:
						# ��������һ�����Ƽ���
						isSimiliar = True
						#if self.telSame(curTel, lastItem.tel):
						#	isSimiliar = True
						
						if not self.addrSimilar(curAddr, lastItem.addr):
							isSimiliar = False
						
						if not self.distanceNear(curPoi, lastItem.poi):
							isSimiliar = False
						
						if isSimiliar:
							print 'title\t' + curID + '\t' + lastItem.id
						if DEBUG:
							print '\t[debug] addrDis=[' + str(self.debugAddrDis) + ']  distance=[' + str(self.debugDistance) + ']'
			else:
				lastSameTitleList = []

			self.lastTitle = curTitle
			curItem = Item(curID, curTitle, curDomain, curTel, curArea, curAddr, curPoi)
			lastSameTitleList.append(curItem)



def test():
	merger = RestaurantMerger()
	#addr1 = '��ֱ���ڴ��267����Ʒ���ⷿ��'
	#addr2 = '�������̿���15��(���˶�����԰����)'
	addr1 = '�����ж�������̶·8��'
	addr2 = '������ ��̶����԰8��(��̶�����Ŷ�)'
	print merger.addrSimilar(addr1, addr2)
#test()


if __name__ == '__main__':
	if len(sys.argv) < 3:
		print 'Usage: python bin/ServiceAppMerger.py -opt input'
		sys.exit(-1)

	merger = RestaurantMerger()
	opt, input = sys.argv[1], sys.argv[2]

	if opt == '-title':
		merger.mergeByTitle(input)
	elif opt == '-tel':
		merger.mergeByTel(input)






