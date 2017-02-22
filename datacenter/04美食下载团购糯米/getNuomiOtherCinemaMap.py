
#coding=gb2312

nuomiCinemaMap = dict()
otherCinemaMap = dict()
input = '/fuwu/Merger/Output/movie/cinema_movie_rel.table'
for line in open(input):
	segs = line.strip('\n').decode('gb2312', 'ignore').split('\t')
	cinemaid, source, ting = segs[1], segs[3], segs[9]
	
	if source.find(u'Ŵ��') != -1:
		if cinemaid not in nuomiCinemaMap:
			nuomiCinemaMap[cinemaid] = []
		if ting not in nuomiCinemaMap[cinemaid]:
			nuomiCinemaMap[cinemaid].append(ting)
	else:
		if cinemaid not in otherCinemaMap:
			otherCinemaMap[cinemaid] = []
		if ting not in otherCinemaMap[cinemaid]:
			otherCinemaMap[cinemaid].append(ting)

# Ŵ��ӰԺ���������Ƿ񶼱�����
for cinemaid in otherCinemaMap:
	if cinemaid not in nuomiCinemaMap:
		#print ('#%s\t%s\t%s' % (cinemaid, u'Ŵ��', '\t'.join(nuomiCinemaMap[cinemaid]))).encode('gb2312', 'ignore')
		continue
	noMatchTingList = []
	for ting in nuomiCinemaMap[cinemaid]:
		if ting not in otherCinemaMap[cinemaid]:
			noMatchTingList.append(ting)
	if len(noMatchTingList) == 0:
		continue

	# ���ڲ�һ�µ����
	normTing = '\t'.join(otherCinemaMap[cinemaid])
	noMatchTing = '\t'.join(noMatchTingList)
	print ('%s\t%s\t%s' % (cinemaid, u'��Ŵ��', normTing)).encode('gb2312', 'ignore')
	print ('%s\t%s\t%s' % (cinemaid, u'Ŵ��', noMatchTing)).encode('gb2312', 'ignore')





