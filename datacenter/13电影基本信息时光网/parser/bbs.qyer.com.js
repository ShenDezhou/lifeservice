var result=[];
var MAX_NEXTPAGE_NUM = 5;
var current_nextpage_num = 0;

function main()
{
    //parseBaseInfos();
    // 需要一些时间来加载图片
    window.setTimeout(parseBaseInfos,2000);
    //scrollPage(parseBaseInfos);
}


function scrollPage(callbackFun) {
	var scrollHeight = document.body.scrollTop;
	var clientHeight = document.documentElement.clientHeight;
	var totalHeight = document.documentElement.scrollHeight;

	if (scrollHeight + clientHeight + 100 < totalHeight) {
			window.scrollBy(0, clientHeight);
		    window.setTimeout(scrollPage,200);
		    return;
	}
	callbackFun();
}


/*
 *  本函数内容需要您填充
 *  即在页面加载完成后可以直接解析的字段内容
 *  常见情况是抽取URL 基本信息等内容
*/
function parseBaseInfos(){
    /* 
    // 以 http://place.qyer.com/poi/V2EJalFlBzZTZg/ 网页中抽取(url  title  photo)为例
    // 抽取以jQuery的方式进行，可以根据自己的需求写特定的归一化函数对抽取的值进行归一化，参考 normalStr
    var url = window.location.href;
    var title = $.trim($('.poiDet-largeTit > h1.cn').text());
	var photo = $('.poiDet-placeinfo p.coverphoto > img').attr('src');

	pushResult('url', url);
	pushResult('title', normalStr(title));
    pushResult('photo', photo);
    */
    var url = window.location.href;
    var title = $.trim( $('#bbsDetailBanner div.signs').text() );
    var authorName = $.trim( $('.bbs_info_content div.names strong').text() );
    var authorPhoto = $.trim( $('.bbs_info_content div.names a > img').attr('src') );
    var authorLevel = $.trim( $('.bbs_info_content div.names span:contains("袋长老")').text() ).replace(/袋长老/g, '');
    var date = $.trim( $('.bbs_info_content div.names span.date').text() );
    var like = $.trim( $('.bbs_info_content div.names span.like').text() );
    var collect = $.trim( $('.bbs_info_content div.names span.collect').text() );
    var tags = '';
    $('.bbs_detail_tag span.tag').each( function() {
        var tag = $(this).text();
        if (tags === '') {
            tags = tag;
        } else {
            tags = tags + ',' + tag;
        }
    });
    var isEssence = $.trim( $('.bbs_info_content div.names span#detail-essence').text() ).replace(/级精华/g, '');
    
    // 替换页面的图片
    //<img src="http://pic.qyer.com/album/user/697/64/R0BSRB4GYw/index/680x" data-original="http://pic.qyer.com/album/user/697/64/R0BSRB4GYw/index/680x">
    $('img').each(function(){
        var replaceImg = $(this).attr('data-original');
        if (replaceImg && replaceImg.length > 0) {
            $(this).attr('src', replaceImg);
        }
    });
    var content = normalStr($('div.bbs_detail_planbill').html() + $('div.bbs_detail_list').html());
    
    pushResult("url",  url);
    pushResult("title",  title);
    pushResult("authorName",  authorName);
    pushResult("authorPhoto",  authorPhoto);
    pushResult("authorLevel",  authorLevel);
    pushResult("date",  date);
    pushResult("like",  like);
    pushResult("collect",  collect);
    pushResult("tags",  tags);
    pushResult("isEssence",  isEssence);
    pushResult("content",  content);

    sendMessage(result);
}


/*
 *  本函数内容需要您填充
 *  即抽取在每次翻页时，需要解析的字段内容
 *  常见情况是抽取翻页的评论信息
*/
function parseTurnPageInfos() {
    // 以 http://place.qyer.com/poi/V2EJalFlBzZTZg/ 网页中抽取评论列表（urserName  userPhoto）为例
    // 与parseBaseInfos抽取基本信息不同， 抽取的是列表型信息，所以使用了.each 
    /*
    // user's comments
    $('#commentlist > li').each(
        function(){
            var userPhoto = $(this).find('.largeavatar > img').attr('src');
            var userName = $(this).find('.largeavatar > span').text();
            pushResult('userName', userName);
            pushResult('userPhoto', userPhoto);
        }
    );
    */
}


/* 本函数内容需要您填充
 * 即找到页面的翻页按钮，没翻一页调用parseTurnPageInfos进行解析
 * 以 http://place.qyer.com/poi/V2EJalFlBzZTZg/ 网页中翻页为例，代码如下
 * 您需要修改的是 var nextPage = $('.ui_page_item.ui_page_next'); 到您实际的需求
*/
function clickFunc(){
    parseTurnPageInfos();

    // 根据您的需替换下面这一行即可
    var nextPage = $('.ui_page_item.ui_page_next');
    
    if (++current_nextpage_num<=MAX_NEXTPAGE_NUM && nextPage && nextPage.length > 0) {
        nextPage[0].click();
		window.setTimeout(clickFunc, 1000);
		return;
    }
    sendMessage(result);
}


function pushResult(key, val) {
    if (key && key.length>0 && val && val.length>0) {
        result.push(key + '\t' + val);
    }
}

function normalStr(str) {
    return str.replace(/[\r\n]/g, '').replace(/\s+/g,' ');
}

