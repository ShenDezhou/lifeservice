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
    
    title = $.trim($('div.z-head-name strong').text());
    type = "";
    $('div.z-head-name span').each(function(){
        t = $.trim($(this).text());
        if (type !== "") {
            type = type + " / " + t;
        } else {
            type = t;
        }
    });

    var addr="", tel="", site="";
    $('div.z-hospital-address div.lh30').each(function(){
        content = $.trim($(this).text());
        if (content.indexOf("医院地址：") !== -1) {
            addr = normalStr($.trim(content.replace("医院地址：", "")));
        } else if (content.indexOf("医院电话：") !== -1) {
            tel = normalStr($.trim(content.replace("医院电话：", "")));
        } 
    });
    
    
    
    
    desc = normalStr($.trim($('div.z-hospital-infor > p').text()));
    desc = desc.replace("更多>>", "");
    site = "";
    
    result.push(url + "\t" + title + "\t" + tel + "\t" + site + "\t" + type + "\t" + addr + "\t" + desc);
	sendMessage(result);
}



