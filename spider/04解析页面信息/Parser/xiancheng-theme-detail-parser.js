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
	
	var title = trim($('h1.hot-title').text());
	var intro = trim($('div.hot-info').text());
	var themeInfo = title + '\t' + intro;

	$('ul.list.hot-list li').each(function(){
		var img = $(this).find('div.wrap-img').attr('style');
		if (img) {
			img = img.replace(/^.*url\(/, '').replace(')', '');
		}
		var reason = $(this).find('div.reason-box').text();
		if (reason) {
			reason = reason.replace('�Ƽ�����', '');
		}
		var shopIntro = trim($(this).find('div.shop-info > h3').text());
		var shopUrl = trim($(this).find('div.shop-info > h3 > a').attr('href'));
		var shopTitle = trim($(this).find('div.shop-info p.icon-map2').text());
		var likeCnt = trim($(this).find('div.shop-info i').text());
		var itemInfo = shopTitle + '\t' + img + '\t' + shopUrl + '\t' + shopIntro + '\t' + likeCnt + '\t' + reason;
	    	
		pushResult(url, themeInfo + '\t' + itemInfo);
	})
	
}


// ����url�ַ�����ͬ�Ľ�������
parse = function(url, content) {
    parseBaseInfo(url, content);
}

// ���⿪�Žӿ�
exports.parse = parse;
