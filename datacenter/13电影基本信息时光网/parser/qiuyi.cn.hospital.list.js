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

function normalStar(star) {
    if (!star) {
        return '';
    }
    star = normalStr(star);
    star = star.replace('user-rank-rst urr-rank', '');
    star = star.replace('sml-rank-stars sml-str', '');
    if (star && star.length > 0){
        return (parseFloat(star)/10).toString();
    }
    return star;
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

    $('div.hos_a li dd').each(function(){
        tel = $.trim($(this).find('p.phone').attr('href'));
        url = $.trim($(this).find('a').attr('href'));
        title = $.trim($(this).find('a').text());
        type = "";
        $(this).find('span').each(function(){
            t = $.trim($(this).text());
            if (type === "") {
                type = t;
            } else {
                type = type + "\t" + t;   
            }
        });
        
        result.push(listurl + '\t' + url + '\t' + title + '\t' + tel + '\t' + type);    
    });


	sendMessage(result);
}



