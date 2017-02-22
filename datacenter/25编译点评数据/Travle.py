#!/bin/bash
#coding=gb2312

import re, sys, logging
import types
from config import *
import logging

logging.basicConfig(level=logging.DEBUG,
                format='%(asctime)s %(filename)s[line:%(lineno)d] [%(levelname)s] %(message)s',
                datefmt='%Y-%m-%d %H:%M:%S',
                filename='log/travel.log',
                filemode='w')



def normalKey(key):
	key = re.sub('(^[\s ]+|[\s ]+$)', '', key)
	return key

def normalVal(val):
	val = re.sub('\t', ' ', val)
	return val



# ============= ����Item�� =================
class Item:
	''' content item '''
	URL, TITLE = 'url', 'title'
	
	# ���캯��
	def __init__(self, url='', title=''):
		self.content = dict()
		if len(url) > 0:
			self.content[self.URL] = url
		if len(title) > 0:
			self.content[self.TITLE] = title
	
	# ����һ������
	def insertLine(self, keyList, vals):
		if type(vals) is types.StringType:
			valSegs = vals.split('\t')
			if len(keyList) != len(valSegs):
				logging.error('Item init for %s error!' % vals)
				return
			for idx in xrange(0, len(keyList)):
				key, val = keyList[idx], valSegs[idx]
				self.insert(key, val)
		elif type(vals) is types.ListType:
			if len(keyList) == 0 or len(vals) == 0:
				logging.error('Item init error, is empty!')
				return
			for idx in xrange(0, len(keyList)):
				key, val = keyList[idx], vals[idx]
				self.insert(key, val)

	# ��������
	def insert(self, key, val):
		if val == '����':
			return
		if len(key) != 0 and len(val) != 0:
			self.content[key] = val
	
	# ת���ַ���
	def toString(self, keyList):
		resultStr = ''
		if self.URL not in self.content or self.TITLE not in self.content:
			return resultStr
		if len(self.content) < 3:		# ��ֻ��url, title
			return resultStr
		for key in keyList:
			tmpVal = ''
			if key in self.content:
				tmpVal = self.content[key]
			if len(resultStr) == 0:
				resultStr = tmpVal
			else:
				resultStr += '\t' + tmpVal
		return resultStr


# ============ ������ =================
class Comment:
	''' ���ε������� '''

	URL, TITLE, USERNAME = 'url', 'title', 'userName'

	def __init__(self):
		self.commentItem = None
		logging.info('Comment init.')
	
	# ��ӡ���۵��ֶ���Ϣ
	def printCommentHead(self, fd):
		head = ''
		for key in commentKey:
			head = head + '\t' + key
		fd.write(head[1:] + '\n')
	
	# ��ӡ���۵�ʵ������
	def printCommentContent(self, fd):
		if self.commentItem is not None:
			commentStr = self.commentItem.toString(commentKey)
			if len(commentStr) > 0:
				fd.write(commentStr + '\n')
		

	# ���������ļ���ת������ʽ
	# input: �����ļ�����������Ϣ��ԭʼ�����ļ�
	# output: ����ļ�����ת��������ʽ�������ļ�
	def loadCommentFile(self, input, output):
		outputFD = open(output, 'w')
		self.printCommentHead(outputFD)
		for line in open(input):
			line = line.strip('\n')
			segs = line.split('\t')
			if len(segs) != 2:
				continue
			key, val = normalKey(segs[0]), normalVal(segs[1])
			if key == self.URL:
				url = val
			elif key == self.TITLE:
				title = val;
				self.printCommentContent(outputFD)
				self.commentItem = Item(url, title)
			elif key == self.USERNAME:
				self.printCommentContent(outputFD)
				self.commentItem = Item(url, title)
				self.commentItem.insert(key, val)
			else:
				self.commentItem.insert(key, val)
					
		self.printCommentContent(outputFD)
		outputFD.close()
		logging.info('transfer raw comment file [%s] to [%s]' % (input, output))



# ======== ������Ϣ�� ===============
class BaseInfo:
	''' ���εĻ�����Ϣ�� '''

	URL, TITLE = 'url', 'title'
	CRUMB, CRUMBTYPE = 'breadcrumb', 'crumbType'

	def __init__(self):
		logging.info('BaseInfo init.')
		self.baseInfoItem = None


	# ��ӡ������Ϣ���ֶ���Ϣ
	def printHead(self, keyList, fd):
		head = ''
		for key in keyList:
			head = head + '\t' + key
		fd.write(head[1:] + '\n')


	# ��ӡ������Ϣ��ʵ������
	def printBaseInfoContent(self, fd):
		if self.baseInfoItem is not None:
			baseInfoStr = self.baseInfoItem.toString(baseinfoKey)
			if len(baseInfoStr) > 0:
				fd.write(baseInfoStr + '\n')
	

	# �������εĻ�����Ϣ�����ļ���ת�������ĸ�ʽ
	def loadBaseInfoFile(self, input, output):
		outputFD = open(output, 'w')
		self.printHead(baseinfoKey, outputFD)
		for line in open(input):
			line = line.strip('\n')
			segs = line.split('\t')
			if len(segs) != 2:
				continue
			key, val = normalKey(segs[0]), segs[1]
			if key == self.URL:
				url = val
			elif key == self.TITLE:
				title = val;
				self.printBaseInfoContent(outputFD)
				self.baseInfoItem = Item(url, title)
			elif key == self.CRUMB:
				crumbType = self.getType(val)
				self.baseInfoItem.insert(key, val)
				if len(crumbType) != 0:
					self.baseInfoItem.insert(self.CRUMBTYPE, crumbType)
				else:
					logging.error('%s crumb error!' % url)
			else:
				self.baseInfoItem.insert(key, val)
					
		self.printBaseInfoContent(outputFD)
		outputFD.close()
		self.baseInfoItem = None
		logging.info('transfer raw baseinfo file [%s] to [%s]' % (input, output))

	
	# ��keyList���ҳ�findKey��index
	def getKeyIndex(self, keyList, findKey):
		keyIndex = -1
		for idx in xrange(0, len(keyList)):
			if keyList[idx] == findKey:
				keyIndex = idx;  break
		return keyIndex

	
	# ����������е���ʾ�����������
	def getType(self, crumb):
		if crumb.find('��ʳ') != -1:
			return 'food'
		elif crumb.find('����') != -1:
			return 'sight'
		elif crumb.find('����') != -1:
			return 'shop'
		elif crumb.find('����') != -1:
			return 'food'
		else:
			return 'food'


	# �зֻ�����Ϣ���ݵ�����ʳ��������������֣�
	# input: baseinfo�ϼ�����
	# ���:  $input.food  $input.sight  $input.shop
	def splitBaseInfoFile(self, input):
		isHeadLine = True
		crumbTypeIdx = self.getKeyIndex(baseinfoKey, self.CRUMBTYPE)
		foodFD = open(input + '.food', 'w')
		shopFD = open(input + '.shop', 'w')
		sightFD = open(input + '.sight', 'w')
		self.printHead(foodKey, foodFD)	
		self.printHead(shopKey, shopFD)	
		self.printHead(sightKey, sightFD)	
	


		item = None
		for line in open(input):
			line = line.strip('\n')
			segs = line.split('\t')
			if isHeadLine:
				isHeadLine = False;  continue
			if len(segs) != len(baseinfoKey):
				continue

			item = Item()
			item.insertLine(baseinfoKey, segs)
			# �������ͣ�д�벻ͬ�ķ����ļ���
			outputFD = None; keyList = []
			if segs[crumbTypeIdx] == 'food':
				outputFD, keyList = foodFD, foodKey
			elif segs[crumbTypeIdx] == 'shop':
				outputFD, keyList = shopFD, shopKey
			elif segs[crumbTypeIdx] == 'sight':
				outputFD, keyList = sightFD, sightKey
			
			#print segs[crumbTypeIdx]
			resultStr = item.toString(keyList)
			if outputFD is not None and len(resultStr) > 0:
				outputFD.write(resultStr + '\n')

		foodFD.close(); shopFD.close(); sightFD.close()



# ======= ������ ===========
class TravelNote:
	''' ���ι����� '''

	URL, TITLE, CONTENT = 'url', 'title', 'content'
	DATE, PHOTO, AUTHORNAME = 'date', 'photo', 'authorName'
	AUTHOR = ''
	def __init__(self):
		self.travelNoteItem = None
		self.page = -1
		logging.info('TravelNote init.')
	

	def subFun(self, matches):
		if matches is not None:
			matchStr = matches.group(1)
			# ��������<a><img .*></a>�����
			if re.match("<img[^>]*>", matchStr):
				return matchStr
			# ����������ǩ�����
			pos = matchStr.rfind('>')
			if pos != -1:
				return matchStr[pos+1 : ]
			else:
				return matchStr
		return ''


	# ����ÿ��¥�Ķ����Ĳ��� 
	# <div class="bbs_detail_title clearfix">.*?<div class="bbs_detail_content">.*?</div>
	def noteSubFun_(self, matches):
		contentRegex = '<div class="bbs_detail_content">.*?</div>'
		if matches:
			matchStr = matches.group(1)
			#print 'matchStr = ' + matchStr
			matchStr = re.sub("<[/]*(em|strong)>", "", matchStr)
			# ��ȡ �ظ��� �� ���ظ���
			if re.match('.*?<strong>(.*?)<em>(.*?)</em> </strong>', matchStr):
				#print "#######################################"
				authorRegex = '.*?<div class="bbs_detail_title.*?<h3 class="titles">(.*?)<span'
				replierRegex = '.*?<strong>�ظ� .*?<em>(.*?)</em> </strong>'
				if re.match(authorRegex, matchStr) and re.match(replierRegex, matchStr):
					author = re.match(authorRegex, matchStr).group(1).strip()
					replier = re.match(replierRegex, matchStr).group(1).strip()
					#print author, replier
					#print "================================="
					# ��ʾ¥�����Լ���
					if author == replier:
						matchStr = re.sub(replierRegex, '', matchStr)
					else:
						matchStr = re.sub(contentRegex, '', matchStr)
			return matchStr

			#if re.match('.*?[^0-9]+1¥', matchStr):
			#	#print matchStr
			#	return matchStr
		return ''

	# �� �����¥���뱾�������߲�һ����ֱ���˳�
	# ���һ�����лظ�# ���ǲ�һ�£���ֱ���˳�
	# �����������ӡ
	def noteSubFun(self, matches):
		contentRegex = '<div class="bbs_detail_content">.*?</div>'
		curAuthorRegex = '.*?<div class="bbs_detail_title.*?<h3 class="titles">(.*?)<span'
		#replierRegex = '.*?bbsDetailContainer.*?�ظ�.*?[0-9]+[#¥](.*?)</td>'
		replierRegex = r'.*?<!-- ¥������ -->.*?�ظ�[\s]*[0-9]+[#¥](.*?)</div>'

		if matches:
			matchStr = matches.group(1)
			# ��ȡ��¥¥��
			if re.match(curAuthorRegex, matchStr):
				curAuthor = re.match(curAuthorRegex, matchStr).group(1).strip()
				# �Ǳ����ߵ�¥
				if curAuthor != self.AUTHOR:
					return ''
				# ��ȡ������
				matchStr = re.sub("<[/]*(em|strong)>", "", matchStr)
				if re.match(replierRegex, matchStr):
					replier = re.match(replierRegex, matchStr).group(1).strip()[:30]
					#print self.AUTHOR, curAuthor, replier
					# ¥���ظ��Լ�
					if replier.find(self.AUTHOR) != -1:
						matchStr = re.sub('�ظ�[\s]*[0-9]+[#¥].*?'+self.AUTHOR, '', matchStr)
						return matchStr
				else:
					return matchStr
		return ''


	# ȥ�����Կ�ʼ����ͼ�ĵ�һ��ͼ
	def removeHeadImg_(self, content):
		firstImgPos = content.find('<img ')
		if firstImgPos == -1:
			return content
		firstImgEndPos = content.find('>', firstImgPos+1)
		beforeImgContent = content[:firstImgPos]

		beforeImgContent = re.sub('<[^>]*?>', '', beforeImgContent)
		beforeImgContent = re.sub('[ \s]+', '', beforeImgContent)

		if len(beforeImgContent) == 0:
			content = re.sub('<img[^>]*?>', '', content, 1)
		return content

	def removeHeadImg(self, content):
		firstImgPos = content.find('<img ')
		if firstImgPos == -1:
			return content
		firstImgEndPos = content.find('>', firstImgPos+1)
		beforeImgContent = content[:firstImgPos]

		beforeImgContent = re.sub('<[^>]*?>', '', beforeImgContent)
		beforeImgContent = re.sub('[ \s]+', '', beforeImgContent)

		if len(beforeImgContent) == 0:
			content = re.sub('<img[^>]*?>', '', content, 1)
		return content





	# ��һ������
	def normalNote(self, note):
		# ȥ���յ�
		note = re.sub("<p></p>", "", note)
		# ��������תȥ��,ע��������ȥ�����е�href ���ǽ���ȥ���ڲ���
		regex = '<a[^>]*>(.*?)</a>'
		note = re.sub(regex, self.subFun, note)

		# ȥ����������ͷ��������ݣ��Լ���¥���Ǹ�����
		regex = '<table class="contentTable">.*?</table>'
		note = re.sub(regex, '', note)
		
		# ÿ��¥�ĵײ�
		regex = '<div class="bbs_detail_seting clearfix">.*?<div class="floorReplyBox"></div>'
		note = re.sub(regex, '', note)

		# ÿ��¥�Ķ�����1¥��ɾ����
		regex = '(<div class="bbs_detail_title clearfix">.*?<div class="bbs_detail_content">.*?</div>)'	
		note = re.sub(regex, self.noteSubFun, note)
		#note = re.sub(regex, '', note)
		#if self.page == 1:
		#	note = re.sub(regex, self.noteSubFun, note)
		#else:
		#	note = re.sub(regex, '', note)
			

		regex = '(<div class="bbs_detail_title clearfix">.*?</div>)'
		note = re.sub(regex, '', note)

		# ȥ��һ¥��"1¥"��ʶ
		#regex = '>[ \s]*?1¥[ \s]*?<'
		#note = re.sub(regex, '', note)
	
		# ֻ����¥����¥�㣬һ¥ֱ�����������¥����ǻظ��Լ��������
		# ȥ�� �ظ���¥�ı�ʶ, (��Ҫ�����Ƿ���¥���ظ�¥��)
		replayRegex = '<td class="editor bbsDetailContainer"> <strong>�ظ� [0-9]+#.*?</td>'
		#note = re.sub(replayRegex, '', note)

		# ȥ�� ����Ļ��з���
		regex = '<br>[ \s]*<br>[ \s]*<br>[ \s]*'
		continueSub = re.search(regex, note)
		while continueSub is not None:
			note = re.sub(regex, '<br><br>', note)
			continueSub = re.search(regex, note)
		
		# ���˵������м����Ƶ����
		regex = '<object .*?getflashplayer.*?swf.*?<\/object>'
		note = re.sub(regex, '', note)
		
		# ȥ�����Կ�ʼ����һ��ͼƬ������ͼƬ
		note = self.removeHeadImg(note)

		return note



	# ��һ��url, �ҳ��ǵڼ�ҳ����Ϣ
	def normalUrl(self, url):
		self.page = 1
		regex = '\?authorid.*$'
		url = re.sub(regex, '', url)
		regex = '\-([0-9]+).html'
		pageMatch = re.findall(regex, url)
		if pageMatch:
			self.page = pageMatch[0]
		url = re.sub(regex, '-1.html', url)
		url = str(self.page) + '\t' + url
		return url



	# ��һ��ʱ��
	def normalDate(self, date):
		searchGroup = re.search('20[0-9][0-9]\-[0-1][0-9]\-[0-3][0-9]', date)
		if searchGroup is not None:
			return searchGroup.group()
		return date



	# ��ȡ�����ܵĵ�һ��ͼƬ
	def getFirstPhoto(self, content):	
		photoRegex = u'.*?<img[^>]*?src="([^>]*?(.jpeg|680x))"[^>]*?>'
		coverPhoto = ''
		matches = re.match(photoRegex, content)
		if matches is not None:
			coverPhoto = matches.group(1)
		return coverPhoto


	# ��ӡ���ι��Ե��ֶ���Ϣ
	def printTravelNoteHead(self, fd):
		head = ''
		for key in travelNoteKey:
			head = head + '\t' + key
		fd.write(head[1:] + '\n')

	# ��ӡ���ι��Ե�ʵ������
	def printTravelNoteContent(self, fd):
		if self.travelNoteItem is not None:
			noteStr = self.travelNoteItem.toString(travelNoteKey)
			if len(noteStr) > 0:
				fd.write((noteStr + '\n'))	#.encode('gb2312', 'ignore'))

	# �������ι����ļ���ת������ʽ
	# input: �����ļ��������ι��Ե�ԭʼ�����ļ�
	# output: ����ļ�����ת��������ʽ�Ĺ����ļ�
	def loadTravelNoteFile(self, input, output):
		outputFD = open(output, 'w')
		self.printTravelNoteHead(outputFD)
		url, title = '', ''
		for line in open(input):
			line = line.strip('\n')	#.decode('gb2312', 'ignore')
			segs = line.split('\t')
			if len(segs) != 2:
				continue
			key, val = normalKey(segs[0]), normalVal(segs[1])
			if key == self.URL:
				url = self.normalUrl(val)
			elif key == self.TITLE:
				title = val;
				self.printTravelNoteContent(outputFD)
				self.travelNoteItem = Item(url, title)
			elif key == self.CONTENT:
				note = self.normalNote(val)
				self.travelNoteItem.insert(key, note)
				photo = self.getFirstPhoto(val)
				self.travelNoteItem.insert(self.PHOTO, photo)
			elif key == self.DATE:
				date = self.normalDate(val)
				self.travelNoteItem.insert(key, date)
			elif key == self.AUTHORNAME:
				self.AUTHOR = val
				self.travelNoteItem.insert(key, val)
			else:
				self.travelNoteItem.insert(key, val)
		self.printTravelNoteContent(outputFD)

		outputFD.close()
		logging.info('transfer raw travel note file [%s] to [%s]' % (input, output))






# ======= ������ ===========
class Travle:
	''' ������ '''
	def __init__(self):
		logging.info('Travel init.')

	# �����������ļ��зֳɻ�����Ϣ/����������
	def splitTravelData(self, input, baseinfoOutput, commentOutput):
		baseInfoFD = open(baseinfoOutput, 'w')
		commentFD = open(commentOutput, 'w')
		for line in open(input):
			line = line.strip('\n')
			segs = line.split('\t')
			if len(segs) != 2:
				continue
			key, val = segs[0], segs[1]
			if key in commentKey:
				commentFD.write(line + '\n')
			if key in baseinfoKey:
				baseInfoFD.write(line + '\n')
		baseInfoFD.close()
		commentFD.close()
		logging.info('split [%s] into [%s] and [%s] done.' % (input, baseinfoOutput, commentOutput))


# ������
class Filter:
	''' ����һ������������ '''

	ChineseRegx = u'.*[\u4e00-\u9fa5]+'
	CommentIdx = 9

	def __init__(self):
		logging.info('Filter init.')


	# ���˴�Ӣ�����ۣ������˲��������ĵ�����
	def filterEnglishComment(self, input, output):
		isFirstLine = True
		outputFD = open(output, 'w')
		for line in open(input):
			line = line.strip('\n').decode('gbk', 'ignore')
			if isFirstLine:
				outputFD.write((line + '\n').encode('gbk', 'ignore'))
				isFirstLine = False
			segs = line.split('\t')
			comment = segs[self.CommentIdx]
			if not re.match(self.ChineseRegx, comment):
				logging.error('english comment')
				continue
			outputFD.write((line + '\n').encode('gbk', 'ignore'))
		outputFD.close()

	# �Թ������ݽ��й���
	def filterTrevelNote(self, input, output):
		urlIdx, titleIdx, dateIdx = 0, 1, 4
		tagIdx, essenceIdx, contentIdx = 7, 8, 12
		FilterDate = '2014-06-30'

		isFirstLine = True
		outputFD = open(output, 'w')
		for line in open(input):
			line = line.strip('\n').decode('gbk', 'ignore')
			if isFirstLine:
				#outputFD.write((line + '\tbreadcrumb\n').encode('gbk', 'ignore'))
				outputFD.write((line + '\n').encode('gbk', 'ignore'))
				isFirstLine = False
			segs = line.split('\t')
			if len(segs) != len(travelNoteKey):
				continue
			url, title, date = segs[urlIdx], segs[titleIdx], segs[dateIdx]
			tags, essence, content = segs[tagIdx], segs[essenceIdx], segs[contentIdx]
			
			if date < FilterDate:
				logging.error(('too old nores\t' + url))
				continue

			outputFD.write((line + '\n').encode('gbk', 'ignore'))
			# ====================================================
			#  ������Ҫ��ȡ��������Ϊ�����ط�Ҳ��Ҫ
			# ====================================================
			#if title.find(u'����')==-1 and tags.find(u'����')==-1:
			#	logging.error(('not tokyo notes\t' + url))
			#	continue
			#outputFD.write((line + u'\t��������\n').encode('gbk', 'ignore'))


			# ��ȡ��һ��ͼƬ��Ϊ����
			#photoRegex = u'.*?<img[^>]*?src="([^>]*?(.jpeg|680x))"[^>]*?>'
			#coverPhoto = ''
			#matches = re.match(photoRegex, content)
			#if matches is not None:
			#	coverPhoto = matches.group(1)

			#outputFD.write((line + '\t' + coverPhoto + '\n').encode('gbk', 'ignore'))
		outputFD.close()




# Ϊÿ������/���� ��ӹ��ң�����
class Classfier:
	''' ��ÿ��poi���з��� '''

	def __init__(self, countryCityConf):
		logging.info('Classfier init.')
		self.ccMapConf = countryCityConf
		self.ccDict = dict()
		self.loadCountryCityMap()



	# ����<���� ����>ӳ���
	def loadCountryCityMap(self):
		for line in open(self.ccMapConf):
			line = line.strip('\n').decode('gbk', 'ignore')
			segs = line.split('\t')
			if len(segs) != 2:
				continue
			country, city = segs[0], segs[1]
			if country not in self.ccDict:
				self.ccDict[country] = []
			if city not in self.ccDict[country]:
				self.ccDict[country].append(city)


	# ��������߻�ȡ�����б�
	def getCitys(self, crumb):
		country, cityList = '', []
		segs = crumb.split('>')

		itemList = []
		for item in segs:
			item = re.sub(u'(��ʳ|����|����|����)', '', item.strip())
			if item not in itemList:
				itemList.append(item)

		# get country
		for item in itemList:
			if item in self.ccDict:
				country = item
				break

		# get citys
		if len(country) != 0:
			for item in itemList:
				if item in self.ccDict[country]:
					cityList.append(item)	

		return country, ','.join(cityList)

	
	# Ϊ�������
	def addCountryCityRow(self, dataFile, outFile, crumbIdx=10):
		isFirstLine = True
		outputFD = open(outFile, 'w')
		for line in open(dataFile):
			line = line.strip('\n').decode('gbk', 'ignore')
			country , citys = '', ''
			if isFirstLine:
				country, citys = 'country', 'city'
				isFirstLine = False
			else:
				segs = line.split('\t')
				crumb = segs[crumbIdx - 1]
				country, citys = self.getCitys(crumb)

			#print country, citys
			outputFD.write((line + '\t' + country + '\t' + citys + '\n').encode('gbk', 'ignore'))
		outputFD.close()
				






if __name__ == '__main__':

	opt = sys.argv[1]
	# �����������з�
	if opt == 'SPLIT':
		input, baseOutput, commentOut = sys.argv[2], sys.argv[3], sys.argv[4]
		travel = Travle()
		travel.splitTravelData(input, baseOutput, commentOut)
	# ��������Ϣת������ʽ
	elif opt == 'LOADCOMMENT':
		input, output = sys.argv[2], sys.argv[3]
		comment = Comment()
		comment.loadCommentFile(input, output)
	# ��������Ϣת������ʽ
	elif opt == 'LOADBASEINFO':
		input, output = sys.argv[2], sys.argv[3]
		baseInfo = BaseInfo()
		baseInfo.loadBaseInfoFile(input, output)
	# ��������Ϣ�ֳ� ����/��ʳ/����
	elif opt == 'SPLITBASEINFO': 
		input = sys.argv[2]
		baseInfo = BaseInfo()
		baseInfo.splitBaseInfoFile(input)
	# ���������ļ�ת������ļ���ʽ
	elif opt == 'LOADTRAVELNOTE':
		input, output = sys.argv[2], sys.argv[3]
		travelNote = TravelNote()
		travelNote.loadTravelNoteFile(input, output)
	# ����ȥ�����������ĵ�
	elif opt == 'FILTERENCOMMENT':
		input, output = sys.argv[2], sys.argv[3]
		filter = Filter()
		filter.filterEnglishComment(input, output)
	# ���˲�����Ҫ��Ĺ�������
	elif opt == 'FILTERNOTES':
		input, output = sys.argv[2], sys.argv[3]
		filter = Filter()
		filter.filterTrevelNote(input, output)
	# Ϊ������ӹ��ң������ֶ�
	elif opt == 'ADDCITY':
		classfier = Classfier('conf/country_city_map')
		input, output = sys.argv[2], sys.argv[3]
		if len(sys.argv) > 4:
			crumbIdx = sys.argv[4]
			classfier.addCountryCityRow(input, output, crumbIdx)
		else:
			classfier.addCountryCityRow(input, output)

