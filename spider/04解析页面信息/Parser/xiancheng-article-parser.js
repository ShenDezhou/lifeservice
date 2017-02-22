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
	
	var crumb = trim($('p.bnav-xc').text());
	if (crumb) {
		crumb = crumb.replace(/.*>/, '');
	}
	var reason = trim($('div.reason-text').text());
	var title = trim($('div.artcile-detail > h2').text());
	var shopname = trim($('div.shop-msg h3').text());
	var addr = trim($('div.shop-msg strong:contains("��ַ��")').parent().text());
	var time = trim($('div.shop-msg strong:contains("ʱ�䣺")').parent().text());
	var price = trim($('div.shop-msg strong:contains("�۸�")').parent().text());
	var tel = trim($('div.shop-msg strong:contains("��ϵ��")').parent().text());
	if (reason) { reason = trim(reason.replace('�Ƽ�����', '')); }
	if (addr) { addr = trim(addr.replace('��ַ��', '')); }
	if (time) { time = trim(time.replace('ʱ�䣺', '')); }
	if (price) { price = trim(price.replace('�۸�', '')); }
	if (tel) { tel = trim(tel.replace('��ϵ��', '')); }
	
	
	//var detail = normalStr($('div.artcile-detail').last().html());
	//if (detail) {
	//	detail = detail.replace(/&#x/g, "\\u");
	//	Detail = detail.replace(/;/g, "");
	//}
	var shopInfo = crumb + '\t' + title + '\t' + reason + '\t' + shopname + '\t' + addr + '\t' + time + '\t' + price + '\t' + tel;
	
	if (title.length > 0) {
		pushResult(url, shopInfo);
	}
	
}


// ����url�ַ�����ͬ�Ľ�������
parse = function(url, content) {
    parseBaseInfo(url, content);
}

// ���⿪�Žӿ�
exports.parse = parse;
