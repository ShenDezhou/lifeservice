var result=[];

hasClick = false;
function main()
{
//	debugger;
   // window.setTimeout(scroll,500, 1);
parse();
    //scroll(1);
}

function scroll(i) { 
    window.scrollBy(0, 1000); 
    if(i<8){ 
        window.setTimeout(scroll, 500, i+1); 
    } else {
            parse();
        /*if (!hasClick) {
            hasClick = true;
            document.getElementsByClassName('ksb _kvc')[0].click()
            window.setTimeout(scroll, 500, 2); 
        } else {
            parse();
        }*/
    }
}

function parse() {
    var url = window.location.href;
    var imgCount = document.querySelectorAll('div.rg_meta').length;
    result.push(url + '\t' + imgCount);
        
    for (var idx=0; idx<imgCount; ++idx) {
        var img = document.querySelectorAll('div.rg_meta')[idx].innerText
        result.push(idx + '\t' + img);
        console.info(idx + '\t' + img);  
    }
    sendMessage(result);
}
