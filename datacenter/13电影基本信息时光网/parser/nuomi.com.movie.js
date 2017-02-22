var result=[];
var movieInfoArray = [];
var poi = '';
var url = '';
var fetchTime = '';
var cinemaName = '';
var cinemaAddr = '';
var cinemaTel = '';


function main()
{
    url = window.location.href;
    fetchTime = formatDate();
    // 解析影院基本信息
    parseCinemaInfo();
    // 解析每个电影的排片信息
    movieArray = $('a.j-img-wrapper');
    if (movieArray && movieArray.length > 0) {
        movieArray.eq(0)[0].click();
        window.setTimeout(function(){
            parseEveryMovie(movieArray, 0)
        }, 5*100);
    } else {
        resultObj = {};
        resultObj["url"] = url;
        resultObj["fetchTime"] = fetchTime;
        resultObj["cinemaName"] = cinemaName;
        resultObj["cinemaAddr"] = cinemaAddr;
        resultObj["cinemaTel"] = cinemaTel;
        resultObj["poi"] = poi;
        resultObj["movieList"] = [];
        
        result.push(JSON.stringify(resultObj));
        sendMessage(result);
    }
}


function parseCinemaInfo() {
    cinemaName = $.trim($('li.crumb-last').text());
    cinemaAddr = $.trim($('div.cinema-info p.cb-address').text());
    if (cinemaAddr) {
        cinemaAddr = cinemaAddr.replace(/^地址：/, "");
    }
    
    cinemaTel = $.trim($('div.cinema-info p.cb-tel').text());
    if (cinemaTel) {
        cinemaTel = cinemaTel.replace(/^电话：/, "");
         cinemaTel = cinemaTel.replace(")", "-").replace("(", "");
    }
    
    poi = getPoi();
}


// 点击每一个影片
function parseEveryMovie(movieArray, idx) {
    node = movieArray.eq(idx);
    movieName = $.trim(node.find('img').attr('alt'));
    movieID = $.trim(node.attr('movieid'));
    fetchtime = formatDate();
    
    dateArray = [];
    // 排片日期     后天03.27(周日)
    $('div.w-choose-list dd').each(function(){
        dateStr = $.trim($(this).text());
        dateArray.push(dateStr);
    });
        
    // 排片信息
    playArray = [];
    $('div.w-choose-list div.list').each(function(){
        playDetailArray = []
        $(this).find('tr').each(function(){
            //info = $.trim($(this).text());
            playRowInfo = parseEveryRow(movieID, $(this));
            if (!isOwnEmpty(playRowInfo)) {
                playDetailArray.push(playRowInfo);
            }
        
        });
        if (playDetailArray.length > 0) {
            playArray.push(playDetailArray);
        }
    });
    
    
    moviePlayInfoArray = [];
    // 对每一部电影发送一次请求
    if (dateArray.length === playArray.length) {
        for (var i=0; i<dateArray.length; i++) {
            date = dateArray[i];
            date = normalDate(date);
            
            // 修改每一天的每场次的购票链接里的时间戳信息
            timestamp = "";
            if (date.length > 10) {
                timestamp = (new Date(date.substring(0, 10) + ' 00:00:00')).getTime();
            }
            playDetailArray = playArray[i];
            for(var k=0; k<playDetailArray.length; ++k) {
                playItem = playDetailArray[k];
                if (timestamp === '') {
                    playItem['ticket'] = '';
                } else {
                    playItem['ticket'] = playItem['ticket'].replace('DATE', timestamp);
                }
            }
            
            
            //playlistInfo = playArray[i].toString();
            
            // json format
            moviePlayInfo = {};
            moviePlayInfo["date"] = date;
            moviePlayInfo["playlist"] = playArray[i];
        
            moviePlayInfoArray.push(moviePlayInfo);
        }
    }
    
    //json format 每个电影的排片信息
    movieInfo = {};
    movieInfo["movieName"] = movieName;
    movieInfo["movieID"] = movieID;
    movieInfo["playInfo"] = moviePlayInfoArray;
    movieInfoArray.push(movieInfo);
    
    // 点击完最后一个电影后，发送结果
    if ((idx+1) >= movieArray.length) {
        resultObj = {};
        resultObj["url"] = url;
        resultObj["fetchTime"] = fetchTime;
        resultObj["cinemaName"] = cinemaName;
        resultObj["cinemaAddr"] = cinemaAddr;
        resultObj["cinemaTel"] = cinemaTel;
        resultObj["poi"] = poi;
        resultObj["movieList"] = movieInfoArray;
        
        result.push(JSON.stringify(resultObj));
        sendMessage(result);
        return;
    }
    
    node = movieArray.eq(idx+1);
    node[0].click();
    
    // 递归解析下一个电影
    window.setTimeout(function(){
        parseEveryMovie(movieArray, idx+1);
    }, 5*100);
}


// 解析每场次的信息
function parseEveryRow(movieID, rowObj) {
    rowInfoJson = {};
    timeRow=0, languageRow=1, hallRow=2, priceRow=3; ticketRow=4;
    tds = rowObj.find('td');
    if (tds.length > priceRow) {
        
        time = normalTime(normalStr(tds.eq(timeRow).text()));
        language = normalLanguage(normalStr(tds.eq(languageRow).text()));
        hall = $.trim(tds.eq(hallRow).text());
        price = normalPrice(normalStr(tds.eq(priceRow).text()));
        ticketUrl = tds.eq(ticketRow).find('a').attr('href');
        ticketUrl = normalTicketUrl(movieID, ticketUrl);
        if (time.length > 0 && hall.length > 0 && price.length > 0) {
            // json format
            rowInfoJson["time"] = time;
            rowInfoJson["language"] = language;
            rowInfoJson["hall"] = hall;
            rowInfoJson["price"] = price;
            rowInfoJson['ticket'] = ticketUrl;
        }
    }
    
    console.info(rowInfoJson.toString());
    
    return rowInfoJson;
}


function getPoi() {
        // food google map poi
	var poi = "";
    /* baidu_longitude":([0-9\.]+),"baidu_latitude":([0-9\.]+)} */
    $('script').each(
        function() {
            var mapUri = $(this).text();
            // "lng":139.772583007812, "lat":35.7059631347656,
            matchGroup = mapUri.match(/baidu_longitude":([0-9\.]+),"baidu_latitude":([0-9\.]+)/);
            if (matchGroup && matchGroup.length > 2) {
                 poi = matchGroup[2] + ',' + matchGroup[1];
            }
        }
    );
    return poi;
}


function isOwnEmpty(obj)
{
    for(var name in obj)
    {
        if(obj.hasOwnProperty(name))
        {
            return false;
        }
    }
    return true;
}



// 归一化购票链接
function normalTicketUrl(movieid, ticketUrl) {
    movieidRegex = '^[0-9]+$';
    ticketRegex = 'seq_no=([^&]+)&cinema_id=([^&]+)&';
    normTicketUrl = 'https://mdianying.baidu.com/ticket/select?movieId=MID&cinemaId=CID&seqNo=SNO&date=DATE';
    
    if (!movieid.match('^[0-9]+$') || !ticketUrl.match(ticketRegex)) {
        return "";
    }

    // get seq_no cinema_id
    matchGroup = ticketUrl.match(ticketRegex);
    seqNo = matchGroup[1]; cinemaID = matchGroup[2];

    normTicketUrl = normTicketUrl.replace('MID', movieid).replace('CID', cinemaID);
    normTicketUrl = normTicketUrl.replace('SNO', seqNo);

    return normTicketUrl;
}


// 归一化日期
function normalDate(dateStr) {
    "明天03.26(周六)"	
    normDate = "";
    dateRegex = "([0-9]+\.[0-9]+)\\((周.)\\)";
    matchGroup = dateStr.match(dateRegex);
    if (matchGroup && matchGroup.length > 2) {
        date = matchGroup[1].replace('.', '-');  week = matchGroup[2];
        
        // 转换03.25 -> 2016-03-25 格式
        today = new Date();
        curYear = today.toISOString().substring(0, 4);
        curMonth = today.toISOString().substring(5, 10);

        if (curMonth > date) {
            curYear = parseInt(curYear) + 1;
        }
        
        normDate = curYear + '-' + date + '\t' + week;
    }
    
    return normDate;
}

// 归一化时间
function normalTime(timeStr) {
    startEndTime = "";
    timeRegex = "([0-9]+:[0-9]+).*?([0-9]+:[0-9]+)";
    matchGroup = timeStr.match(timeRegex);
    if (matchGroup && matchGroup.length > 2) {
        startEndTime = matchGroup[1] + '\t' + matchGroup[2];
    }
    
    return startEndTime;
}

// 归一化价格
function normalPrice(price) {
   // debugger;
    normPrice = "";
    priceRegex = "¥([\.0-9]+).*?¥";
    matchGroup = price.match(priceRegex);
    if (matchGroup && matchGroup.length > 1) {
        normPrice = matchGroup[1];
    }
    return normPrice;
}

// 归一化语言。是否3D
function normalLanguage(language) {
    normLanguage = '';
    language = language.replace('/', '\t');
    if (language.split('\t').length == 2) {
        normLanguage = language;
    }
    return normLanguage;
}



// 获取当前时间
function formatDate() {
    var today = new Date();
    var dateStr = today.toISOString().substring(0, 10);
    var timeStr = today.getHours() + ":" + today.getMinutes() + ":" + today.getSeconds();
    return dateStr + " " + timeStr;
}


function pushResult(key, val) {
    if (key && key.length>0 && val && val.length>0) {
        result.push(key + '\t' + val);
    }
}

function normalStr(str) {
    return str.replace(/[\r\n]/g, '').replace(/\s+/g,' ');
}


