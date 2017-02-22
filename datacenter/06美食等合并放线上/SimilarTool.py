#!/bin/python
#coding=gb2312
#/*******************************************************************************
# * Author	 : liubing@sogou-inc.com
# * Last modified : 2016-04-08 16:51
# * Filename	 : SimilarTool.py
# * Description	 : ����������
# * *****************************************************************************/

class SimilarTool(object):
	
	@staticmethod
	def hasIntersection(lList, rList):
		if len(rList) == 0 or len(rList) == 0:
			return False
		# �н���
		lSet, rSet = set(lList), set(rList)
		if len(lSet.intersection(rSet)) > 0:
			return True
		return False

	@staticmethod
	def isStrSame(lStr, rStr):
		if lStr == rStr:
			return True
		if lStr.find(rStr) != -1 or rStr.find(lStr) != -1:
			return True
		return False

	@staticmethod
	def strSimilar(lStr, rStr, threshold):
		# ��Ϊǰ��׺����ֱ�ӷ���True
		if SimilarTool.isStrSame(lStr, rStr):
			return True

		lStrSet, rStrSet = set(lStr), set(rStr)
		lStrLen, rStrLen = len(lStrSet), len(rStrSet)
		
		totalLen = (lStrLen + rStrLen) / 2
		#minLen = rStrLen
		#if lStrLen < rStrLen:
		#	minLen = lStrLen

		# ����
		commLen = len(lStrSet.intersection(rStrSet))
		#if commLen >= (minLen * threshold):
		if commLen >= (totalLen * threshold):
			return True
		return False

	
	@staticmethod
	def similar(lStr, rStr):
		lStrSet, rStrSet = set(lStr), set(rStr)
		lStrLen, rStrLen = len(lStrSet), len(rStrSet)
		if lStrLen == 0 or rStrLen == 0:
			return 0
		totalLen = (lStrLen + rStrLen) / 2
		# ����
		commLen = len(lStrSet.intersection(rStrSet))
		return (1.0 * commLen / totalLen)


#print SimilarTool.similar('�����к���������6������·��վC�ڳ��ҹպ�ͬ����200��·�������׵�Сѧ����300�ף�', '������ ����ׯ·61��Ժ����(����6������·�ӵ���C�����ҹպ�ͬ����100��)')


