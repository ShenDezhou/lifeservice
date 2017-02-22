var result=[];

function main() {
    parseHospitalList();
}

function normalStr(str) {
    return str.replace(/[\r\n]/g, '').replace(/\s+/g,' ');
}

function pushResult(key, val) {
    if (key && key.length>0 && val && val.length>0) {
        result.push(key + '\t' + val);
    }
}

// 从数组中获取第一个不为空的值
function takeFirst(valueArray) {
    for (var idx in valueArray) {
        if (valueArray[idx] && valueArray[idx].length > 0) {
            return valueArray[idx];
        }
    }
    return '';
}


function formatDate() {
    var today = new Date();
    var dateStr = today.toISOString().substring(0, 10);
    var timeStr = today.getHours() + ":" + today.getMinutes() + ":" + today.getSeconds();
    return dateStr + " " + timeStr;
}


function parseHospitalList(){
    // basic info
    var url = window.location.href;

    var title = $.trim($('div.l_cont > div.t_bor h1').text());
    var desc = $.trim($('div.l_cont > div.t_bor div.text').text());
    
    var tel="", site="", type="", addr="";
    $('div.infor li').each(function(){
        content = $.trim($(this).text());
        if (content.indexOf("【电话】") !== -1) {
            tel = $.trim(content.replace("【电话】", ""));
        } else if (content.indexOf("【网址】") !== -1) {
            site = $.trim(content.replace("【网址】", ""));
        } else if (content.indexOf("【地址】") !== -1) {
            addr = $.trim(content.replace("【地址】", ""));
        } else if (content.indexOf("【类型】") !== -1) {
            type = $.trim(content.replace("【类型】", ""));
        }
    });
    result.push(url + "\t" + title + "\t" + tel + "\t" + site + "\t" + type + "\t" + addr + "\t" + desc);

	sendMessage(result);
}



