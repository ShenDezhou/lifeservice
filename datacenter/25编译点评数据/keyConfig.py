#!/bin/python
#coding=gb2312

# 
foodKeyNames = ['baseinfo', 'recomfood', 'tuan', 'comment']

###################  ���ڵ�������ʳ�̼����key�б� ###########################

# ������Ϣ��key
#baseinfoKey = ['url','title','breadcrumb','poi','photo','photoSet','photoCount','commentCount', 'commentSummary', 'avgPrice','score','scoreTaste','scoreCondition','scoreService','address','tel','businessDate','tags','conditionPhotoSet', 'city', 'area', 'district', 'cuisine', 'subcuisine']
# ��ʱȥ�� conditionPhotoSet �ֶ�
baseinfoKey = ['url','title','breadcrumb','poi','photo','photoCount','commentCount', 'commentSummary', 'avgPrice','score','scoreTaste','scoreCondition','scoreService','address','tel','businessDate','tags', 'city', 'area', 'district', 'cuisine', 'subcuisine', 'serviceTuan','serviceDing','serviceWai', 'vipInfo']


baseinfoKey = ['url','title','breadcrumb','poi','photo','photoSet','photoCount','downreduce','commentCount', 'commentSummary', 'avgPrice','score','scoreTaste','scoreCondition','scoreService','address','tel','businessDate','tags', 'city', 'area', 'district', 'cuisine', 'subcuisine', 'serviceTuan','serviceDing','serviceWai', 'vipInfo']

# �Ƽ��˵�key
# �������չ�� [recomfoodid resid   recommUrl   recommName  recommCount recommPhoto recommPrice]
recomfoodKey = ['url','title','recommFood']


# �Ź����Żݵ�key
#tuanKey = ['url','title','serviceTuan','serviceDing','serviceWai','tuanInfo','dingInfo','huoInfo','cuInfo','vipInfo']
tuanKey = ['url','title','tuanInfo']

# ͼ������
photosetKey = ['url', 'title', 'photoSet', 'conditionPhotoSet']

# ���۵�key
commentKey = ['url','title','userName','userPhoto','userStar','commentStar','cTasteStar','cConditionStar','cServiceStar','comment','commentPhoto','commentDate','commentZanCnt']



################### ��Ӱ�������key�б� ####################################


# ʱ������Ӱ������Ϣ����  �������  Ƭ��url  ͼ��url  ͼ������
movie_movie_detailKey = ['url','title','enName','photo','year','runtime','type','date','displaytype','onlinestatus','releasecountry','scorecnt','wantcnt', 'shortdesc', 'summary','score','rank','boxoffice', 'photosUrl', 'videosUrl', 'photosCnt', 'photoSet']

# ʱ������ӰƬ��
movie_movie_videosKey = ['url', 'title', 'video']

# ʱ������Ӱ���ռ�
movie_movie_actorsKey = ['url', 'title', 'actorInfo']

# ��Ӱ�������
movie_movie_commentsKey = ['url', 'title', 'commentUrl', 'comment']
