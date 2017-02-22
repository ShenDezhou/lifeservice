#!/bin/python
#coding=gb2312
#/*******************************************************************************
# * Author	 : liubing@sogou-inc.com
# * Last modified : 2016-04-27 16:16
# * Filename	 : PathPathFileTool.py
# * Description	 : �ļ�������
# * *****************************************************************************/
import os, time, re
import os.path


#���������·���Ƿ���һ���ļ���os.path.isfile()
#���������·���Ƿ���һ��Ŀ¼��os.path.isdir()
#���������·���Ƿ���ش�:os.path.exists()
#����һ��·����Ŀ¼�����ļ���:os.path.split()
#����ָ��Ŀ¼�µ������ļ���Ŀ¼��:os.listdir()
#��ȡ·������os.path.dirname()
#��ȡ�ļ�����os.path.basename()
#��ȡ�ļ����ԣ�os.stat��file��
#��ȡ�ļ���С��os.path.getsize��filename��
# filemt= time.localtime(os.stat(filename).st_mtime)  
# time.strftime("%Y-%m-%d %H:%M",filemt)   



class PathFileTool(object):

	''' �ļ������� '''
	
	def __init__(self):
		pass


	# ��ȡ�ļ�������޸�ʱ��
	@staticmethod
	def get_mtime(path):
		if not os.path.exists(path):
			return None
		filemt= time.localtime(os.stat(path).st_mtime)
		return time.strftime("%Y-%m-%d %H:%M:%S",filemt) 


	# ��ȡ�ļ��Ĵ���ʱ��
	@staticmethod
	def get_ctime(path):
		if not os.path.exists(path):
			return None
		filemt= time.localtime(os.stat(path).st_ctime)
		return time.strftime("%Y-%m-%d %H:%M:%S",filemt) 
	

	# ��ȡָ��Ŀ¼�µ������ļ�
	@staticmethod
	def get_latest_file(path, fileRegex=None):
		latestCtime = ""
		latestFile = None
		if not os.path.exists(path) or os.path.isfile(path):
			return latestFile
		for file in os.listdir(path):
			filePath = '%s/%s' % (os.path.dirname(path), file)
			if os.path.isdir(filePath):
				continue
			if fileRegex and not re.match(fileRegex, file):
				continue
			curCtime = PathFileTool.get_mtime(filePath)
			if curCtime > latestCtime:
				latestCtime = curCtime
				latestFile = filePath
		return latestFile

	
	# ��ȡָ���ļ���С
	@staticmethod
	def get_filesize(file, unit='K'):
		if not os.path.exists(file) or os.path.isdir(file):
			return -1
		fileSize = os.path.getsize(file)
		if unit == 'K':
			unitSize = '%.2f' % (float(fileSize) / 1024)
			if unitSize != '0.00':
				return '%sk' % unitSize
		elif unit == 'M' or unit == 'm':
			unitSize = '%.2f' % (float(fileSize) / 1024 / 1024)
			if unitSize != '0.00':
				return '%sm' % unitSize
			return PathFileTool.get_filesize(file)
		elif unit == 'G' or unit == 'g':
			unitSize = '%.2f' % (float(fileSize) / 1024 / 1024 / 1024)
			if unitSize != '0.00':
				return '%sg' % unitSize
			return PathFileTool.get_filesize(file, 'M')
		return fileSize


		


#print PathFileTool.get_mtime('pathTool.py')
#print PathFileTool.get_ctime('pathTool.py')
#print PathFileTool.get_latest_file('/search/zhangk/Fuwu/Source/Crawler/beijing/movie/', 'mtime_summary$')
#print PathFileTool.get_latest_file('/search/liubing/spiderTask/result/system/task-144/', '14')
#print PathFileTool.get_latest_file('/search/liubing/spiderTask/result/system/task-144/')
#print PathFileTool.get_filesize('/search/liubing/Tool/Python/test.py', 'M')
#print PathFileTool.get_filesize('/fuwu/Merger/Output/beijing/restaurant/dianping_detail.comment.table', 'G')
#print PathFileTool.get_filesize('/fuwu/Merger/Output/beijing/restaurant/dianping_detail.comment.table', 'M')
