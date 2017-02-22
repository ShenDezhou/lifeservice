#! /usr/bin/python

import sys, os
sys.path.append(os.getcwd())

from pylibozzy.libparse.spider_page_parser import get_part_block
from lxml import etree

Encode = 'gb2312'
prefix = "./pages"
STOP_WORD = [u'\u3000', u'?', u'\u2001', u'\u0020']

def get_site(url):
	url_parts = url.split("/")
	if len(url_parts) < 3:
		return None
	return url_parts[2]

site_data_dic = {}



for info_dict in get_part_block(prefix, ["xmlpage"]):
	print info_dict
	if "Url" not in info_dict:
		continue
	url = info_dict["Url"]
	print '\t'.join(info_dict.keys())
	
	if "xmlpage" not in info_dict:
		continue
	xmlpage = info_dict["xmlpage"]
	xmlpage = xmlpage.decode("utf16")

	print '\n\n'
	print url
	print xmlpage.encode(Encode, 'ignore')
	print '\n\n'

	content_title_tb = xmlpage.find("<content-title>")
	content_title_te = xmlpage.find("</content-title>")
	content_title = xmlpage[content_title_tb+len("<content-title>"):content_title_te]

	content_tb =  xmlpage.find("<major>")
	content_te = xmlpage.find("</major>", content_tb)
	content = xmlpage[content_tb+len("<major>"):content_te]

	if content_title_tb < 0 or content_title_te < 0:
		l1 = None
	else:
		l1 = content_title.encode(Encode, 'ignore')

	if  content_tb < 0 or content_te < 0:
		l2 = None
	else:
		l2 = content.encode(Encode, 'ignore')
	print url + "\t" + str(l1) + "\t" + str(l2)	
