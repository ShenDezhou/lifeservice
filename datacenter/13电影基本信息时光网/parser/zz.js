var result=[];
var url="", filmUrl="", title="";
current_scroll_num = 0;
MAX_SCROLL_NUM = 3;

function main()
{
    // ���¹���һ��
    var scrollHeight = $(document).scrollTop();
    var clientHeight = 400;
    var totalHeight = $(document).height();
    while (scrollHeight + clientHeight + 200 < totalHeight && ++current_scroll_num < MAX_SCROLL_NUM) {
        window.scrollBy(0, clientHeight);
        scrollHeight = $(document).scrollTop();
        totalHeight = $(document).height();
    }
    
    
    window.setTimeout(parseBaseInfos, 1 * 1000);
}


/*
 *  ������������Ҫ�����
 *  ����ҳ�������ɺ����ֱ�ӽ������ֶ�����
 *  ��������ǳ�ȡURL ������Ϣ������
*/
function parseBaseInfos(){
    
    // �� http://place.qyer.com/poi/V2EJalFlBzZTZg/ ��ҳ�г�ȡ(url  title  photo)Ϊ��
    // ��ȡ��jQuery�ķ�ʽ���У����Ը����Լ�������д�ض��Ĺ�һ�������Գ�ȡ��ֵ���й�һ�����ο� normalStr
    url = window.location.href;
    
    /*
    title = $('div.navbar-title').text();
    pushResult('url', url);
    pushResult('title', title);
    */
    

    filmUrl = url.replace(/\/comments.*$/, '');
    title = $.trim($('div.navbar-title').text());
    if (title) {
        title = $.trim(title.replace('���� -', ''));
    }
    // alert(title + '\t' + filmUrl);
    pushResult('url', filmUrl);
    pushResult('title', title);

    now = new Date().getTime();
    pushResult('fetch-date', now);

    pushResult('commentUrl', url);
    $('li.list-view-item').each(function(){
        var cDetailUrl = $.trim($(this).find('a').attr('href'));
        if (cDetailUrl) {
            cDetailUrl = 'http://m.maoyan.com' + cDetailUrl;
        }
        var user = $.trim($(this).find('footer > em').text());
        var userImg = $.trim($(this).find('footer > img').attr('src'));
        
        var starOne = $(this).find('i.empty-star').length;
        var starHalf = $(this).find('i.icon.icon-star-half-o').length;
        var star = 5 - starOne - starHalf * 0.5;
	if (star < 0) {
		star = 0;
	}

        var comment = normalStr($.trim($(this).find('p.content').text()));
        var commentDate = $.trim($(this).find('time.timeago').attr('title'));
        
        var zanCnt = $.trim($(this).find('i.icon.icon-approve').next().text());
        var commentVal = user+"@@@"+userImg+"@@@"+star+"@@@"+zanCnt+'@@@'+commentDate+"@@@"+cDetailUrl+'@@@'+comment;
        pushResult('comment', commentVal);
        
    });

    sendResult(result);
    /*
    ����ͷ��
    �����ǳ�
    �����Ǽ�
    ��������
    ��������
    ����
    �����б�����
    */
     //sendMessage(result);
}




function pushResult(key, val) {
    if (key && key.length>0 && val && val.length>0) {
        result.push(key + '\t' + val);
    }
}

function normalStr(str) {
    return str.replace(/[\r\n]/g, '').replace(/\s+/g,' ');
}

function normalUrl(url) {
    return url.replace(/\?.*$/, "");
}
