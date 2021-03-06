#!/bin/python
#coding=gb2312

# 用于对时光网的影院与商业合作的影院进行合并
# 因为各自的名称不同
# 用于对商业合作的影院数据的合并

import sys, re, logging
from MathTool import *
from DateTimeTool import DateTimeTool as dateTool

DEBUG = True
DEBUG = False


# 定义日志
today = dateTool.today()
logging.basicConfig(level=logging.DEBUG,
                format='%(asctime)s %(filename)s[line:%(lineno)d] [%(levelname)s] %(message)s',
                datefmt='%Y-%m-%d %H:%M:%S',
                filename='logs/ServiceAppCinemaMerger_' + today + '.log',
                filemode='w+')


class Item:
	# 构造函数
	def __init__(self, id, title, domain, city, poi):
		self.id = id
		self.poi = poi
		self.city = city
		self.title = title
		self.domain = domain



# 生活服务APP项目 美食商店的合并类
class CinemaMerger:
	
	sep, telSep = '\t', '|'
	idRow, urlRow, titleRow, domainRow = -1, -1, -1, -1
	telRow, areaRow, addrRow, poiRow = -1, -1, -1, -1
	cityRow = -1;

	def __init__(self):
		self.lastID, self.lastUrl = '', ''
		self.lastTitle, self.lastTel = '', ''
		self.lastArea, self.lastAddr = '', ''
		self.lastPoiStr = ''
		self.lastPoi = ('', '')
		self.mathTool = MathTool()
		
		# 测试使用
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
		# 有交集
		if len(curTelSet.intersection(lastTelSet)) > 0:
			return True
		return False

	
	def normTitle(self, title, city):
		title = title.replace(city + u'市', "")
		title = title.replace(city, "")
		#print ("\t[" + title + ']').encode('gb2312', 'ignore')
		rawTitle = title

		title = re.sub(u"(国际影院|国际影城|电影院|电影城|影剧院|影院|剧院|影城)", "", title)
		title = re.sub(u"[（\(].*$", "", title)
		title = re.sub(u"店$", "", title)
		if title == "":
			title = rawTitle
		return title



	def titleSimilar(self, curTitle, lastTitle, threshold):
		# 去除城市，等信息
		curTitleSet = set(curTitle)
		lastTitleSet = set(lastTitle)
		
		minLen = len(curTitleSet)
		if len(lastTitleSet) < minLen:
			minLen = len(lastTitleSet)

		#print len(curTitleSet), len(lastTitleSet), len(curTitleSet.intersection(lastTitleSet))
		# 有交集
		if len(curTitleSet.intersection(lastTitleSet)) > minLen * threshold:
			return True
		return False


	# 认为距离在 1km 之类的都相同
	def distanceNear(self, curPoi, lastPoi):
		distance = self.mathTool.poiDistance(curPoi, lastPoi)
		if distance <= 2000:
			self.debugDistance = distance
			return True
		self.debugDistance = distance
		return False


	def getKeyRow(self, headLine):
		segs = headLine.split(self.sep)
		for row in xrange(0, len(segs)):
			if segs[row] == 'id': self.idRow = row
			elif segs[row] == 'resource': self.domainRow = row
			elif segs[row] == 'poi': self.poiRow = row
			elif segs[row] == 'city': self.cityRow = row
			elif segs[row] == 'address': self.addrRow = row
			elif segs[row] == 'title': self.titleRow = row


	# 地址相同，区域相同，域名不同
	def mergeByAddr(self, file):
		isFirstLine = True
		
		lastID, lastTitle = '', ''
		lastAddr, lastDomain = '', ''

		for line in open(file):
			line = line.strip('\n')
			if isFirstLine:
				isFirstLine = False
				self.getKeyRow(line)
				continue
			
			segs = line.split(self.sep)

			curID = segs[self.idRow]
			curDomain, curTitle = segs[self.domainRow], segs[self.titleRow]
			curAddr, curPoi = segs[self.addrRow], self.normalPoi(segs[self.poiRow])
			
			distance = self.mathTool.poiDistance(curPoi, self.lastPoi)
			# 地址相同，domain不同
			if lastAddr == curAddr:
				if curDomain != lastDomain:
					#print ('addr\t%s\t%s\t%s\t%s\t%s\t%s' % (curID, lastID, curTitle, lastTitle, curPoi, lastPoi))
					print ('addr\t%s\t%s\t%s\t%s' % (curDomain, curID, lastDomain, lastID))
			lastID, lastTitle = curID, curTitle
			lastAddr, lastDomain = curAddr, curDomain
			lastPoi = curPoi
	
	# poi相同，域名不同
	def mergeByPoi(self, file):
		isFirstLine = True
		
		lastID, lastTitle = '', ''
		lastPoi, lastDomain = '', ''

		for line in open(file):
			line = line.strip('\n')
			if isFirstLine:
				isFirstLine = False
				self.getKeyRow(line)
				continue
			
			segs = line.split(self.sep)

			curID, curTitle = segs[self.idRow], segs[self.titleRow]
			curDomain, curPoi = segs[self.domainRow], segs[self.poiRow]
			#curDomain, curTitle = segs[self.domainRow], segs[self.titleRow]
			#curAddr, curPoi = segs[self.addrRow], self.normalPoi(segs[self.poiRow])
			
			# 地址相同，domain不同
			if lastPoi == curPoi:
				if curDomain != lastDomain:
					print ('poi\t%s\t%s\t%s\t%s' % (curDomain, curID, lastDomain, lastID))
			lastID, lastTitle = curID, curTitle
			lastPoi, lastDomain = curPoi, curDomain
	
	# 名称相同，domain不同，area相同
	# 地址相似 or poi距离在一定范围
	def mergeByTitle(self, file):
		lastSameTitleList = []
		isFirstLine = True

		for line in open(file):
			line = line.strip('\n')
			if isFirstLine:
				isFirstLine = False
				self.getKeyRow(line)
				continue

			segs = line.split(self.sep)
			
			curID = segs[self.idRow]
			curDomain, curTitle = segs[self.domainRow], segs[self.titleRow]
			curCity, curPoi = segs[self.cityRow], self.normalPoi(segs[self.poiRow])
			curAddr = segs[self.addrRow]

			if len(curTitle) == 0: continue

			if curTitle == self.lastTitle:
				for lastItem in lastSameTitleList:
					if curCity == lastItem.city and curDomain != lastItem.domain:
						# 如下任意一个相似即可
						isSimiliar = True
						
						if not self.distanceNear(curPoi, lastItem.poi):
							isSimiliar = False
						
						if isSimiliar:
							print ('title\t%s\t%s\t%s\t%s' % (curDomain, curID, lastItem.domain, lastItem.id))
						#else:
						#	print '\t[debug] distance=[' + str(self.debugDistance) + ']'
							
							if DEBUG:
								print '\t[debug] distance=[' + str(self.debugDistance) + ']'
			else:
				lastSameTitleList = []
				self.lastTitle = curTitle
			
			curItem = Item(curID, curTitle, curDomain, curCity, curPoi)
			lastSameTitleList.append(curItem)



	def mergeByDistanceImp(self, mtimeDict, noMtimeDict):
		MIN_DISTANCE = 10000
		for mtimeCinema in mtimeDict:
			mtimeTitle, mtimeNormTitle, mtimePoi = mtimeDict[mtimeCinema]
			minDistance = MIN_DISTANCE; similarCinema = ''
			for noMtimeCinema in noMtimeDict:
				noMtimeTitle, noMtimeNormTitle, noMtimePoi = noMtimeDict[noMtimeCinema]
				#isNear, isTitleSimilar
				#if self.distanceNear(mtimePoi, noMtimePoi):
				titleSimilar = self.titleSimilar(mtimeTitle, noMtimeTitle, 0.8)
				normTitleSimilar = self.titleSimilar(mtimeNormTitle, noMtimeNormTitle, 0.8)
				distance = self.mathTool.poiDistance(mtimePoi, noMtimePoi)
				if (titleSimilar or normTitleSimilar) and distance < minDistance:
					minDistance = distance
					similarCinema = noMtimeCinema
			if minDistance != MIN_DISTANCE:
				print ('distance\t%s\t%s' % (mtimeCinema, similarCinema)).encode('gb2312', 'ignore')
				#print ('distance\t%d\t%s\t%s' % (minDistance, mtimeCinema, similarCinema)).encode('gb2312', 'ignore')
				noMtimeDict.pop(noMtimeCinema)



	# 城市相同， poi很近， 名称相似即可
	def mergeByDistance(self, file):
		isFirstLine = True
		lastCity = '';
		mtimeCinemaDict, notMtimeCinemaDict = dict(), dict()


		for line in open(file):
			line = line.strip('\n').decode('gb2312', 'ignore')
			if isFirstLine:
				isFirstLine = False
				self.getKeyRow(line)
				#print self.poiRow, self.addrRow
				continue

			segs = line.split(self.sep)
			
			curID = segs[self.idRow]
			curDomain, curTitle = segs[self.domainRow], segs[self.titleRow]
			curCity, curPoi = segs[self.cityRow], self.normalPoi(segs[self.poiRow])
			curAddr = segs[self.addrRow]
			normCutTitle = self.normTitle(curTitle, curCity)


			if len(curTitle) == 0: continue

			if curCity != lastCity:
				self.mergeByDistanceImp(mtimeCinemaDict, notMtimeCinemaDict)
				mtimeCinemaDict.clear()
				notMtimeCinemaDict.clear()
			
			lastCity = curCity
			key = curDomain + '\t' + curID + '\t' + curTitle + ' @@@ ' + normCutTitle + '\t' + curAddr
			#key = curDomain + '\t' + curID
			value = (curTitle, normCutTitle, curPoi)
			if curDomain == u"时光网":
				mtimeCinemaDict[key] = value
			else:
				notMtimeCinemaDict[key] = value
		
		# 处理最后一组
		self.mergeByDistanceImp(mtimeCinemaDict, notMtimeCinemaDict)
		


def test():
	merger = CinemaMerger()
	#addr1 = '东直门内大街267号优品蛋糕房内'
	#addr2 = '德外六铺炕街15号(近人定湖公园南门)'
	addr1 = '北京市东城区龙潭路8号'
	addr2 = '东城区 龙潭湖公园8号(龙潭湖北门东)'
	print merger.addrSimilar(addr1, addr2)
#test()



if __name__ == '__main__':
	if len(sys.argv) < 3:
		print 'Usage: python bin/ServiceAppCinemaMerger.py -opt input'
		sys.exit(-1)

	merger = CinemaMerger()
	opt, input = sys.argv[1], sys.argv[2]

	if opt == '-title':
		merger.mergeByTitle(input)
	elif opt == '-addr':
		merger.mergeByAddr(input)
	elif opt == '-poi':
		merger.mergeByPoi(input)
	elif opt == '-distance':
		merger.mergeByDistance(input)





