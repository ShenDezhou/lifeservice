var cheerio = require("cheerio");
var fs = require("fs");
var common = require("../lib/common.js");

var pushResult = common.pushResult;
var normalStr = common.normalStr;
var normalMultiLineStr = common.normalMultiLineStr;
var takeFirst = common.takeFirst;
var trim = common.trim;


function parseBaseInfo(url, content) {
	var $ = cheerio.load(content);
	
	var title = trim($('div.title-box h1').text());
	var reason = trim($('div.title-box h2').text());
	if (reason) { reason = reason.replace(/\|.*/, '')}
	var articleCnt = $('ul.scenic-list li').length;
	var subjectInfo = articleCnt + '\t' + title + '\t' + reason

	$('ul.scenic-list li').each(function(){
		var img = $(this).attr('style');
		if (img) {
			img = img.replace(/^.*url\(/, '').replace(')', '');
		}
		var shopIntro = trim($(this).find('h3').text());
		var shopUrl = trim($(this).find('a').attr('href'));
		if (shopUrl) {
			shopUrl = shopUrl.replace(/\-.*/, "");
			shopUrl = 'http://www.51xiancheng.com' + shopUrl; 
		}
		var shopTitle = trim($(this).find('span.icon-map').text());
		var likeCnt = trim($(this).find('i.icon-zan').text());
		
		var itemInfo = shopTitle + '\t' + img + '\t' + shopUrl + '\t' + shopIntro + '\t' + likeCnt;
	    	
		pushResult(url, subjectInfo + '\t' + itemInfo);
	})
}


// ����url�ַ�����ͬ�Ľ�������
parse = function(url, content) {
    parseBaseInfo(url, content);
}

// ���⿪�Žӿ�
exports.parse = parse;
