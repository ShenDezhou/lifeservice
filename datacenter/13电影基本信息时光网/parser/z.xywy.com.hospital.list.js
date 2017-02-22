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
    var listurl = window.location.href;

        var province = $.trim($('div.area-hd').text());
        province = province.replace(/地区.*$/, "");

        $('div.pb10.bdr-dashed').each(function(){
            
            $('div.bdr-dashed li') 
            city = $.trim($(this).find('div.zh-impor-area').text());
            $(this).find('li').each(function(){
                url = $.trim($(this).find('a').attr('href'));
                title = $.trim($(this).find('a').text());
                info = $.trim($(this).find('span').text());
                result.push(province + "\t" + city + "\t" + url + "\t" + title + "\t" + info);
            })
        });





	sendMessage(result);
}



