;████████╗██╗   ██╗██████╗ ██╗███╗   ██╗ ██████╗     ████████╗██████╗  █████╗ ███╗   ██╗███████╗██╗      █████╗ ████████╗██╗ ██████╗ ███╗   ██╗
;╚══██╔══╝╚██╗ ██╔╝██╔══██╗██║████╗  ██║██╔════╝     ╚══██╔══╝██╔══██╗██╔══██╗████╗  ██║██╔════╝██║     ██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║
;   ██║    ╚████╔╝ ██████╔╝██║██╔██╗ ██║██║  ███╗       ██║   ██████╔╝███████║██╔██╗ ██║███████╗██║     ███████║   ██║   ██║██║   ██║██╔██╗ ██║
;   ██║     ╚██╔╝  ██╔═══╝ ██║██║╚██╗██║██║   ██║       ██║   ██╔══██╗██╔══██║██║╚██╗██║╚════██║██║     ██╔══██║   ██║   ██║██║   ██║██║╚██╗██║
;   ██║      ██║   ██║     ██║██║ ╚████║╚██████╔╝       ██║   ██║  ██║██║  ██║██║ ╚████║███████║███████╗██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║
;   ╚═╝      ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═══╝ ╚═════╝        ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
#Requires AutoHotkey v2.0
#include <log>
#include <zmq>
CoordMode('ToolTip', 'Screen')
Persistent

logger.is_log_open := false
logger.is_use_editor := true

g_config := Map()

g_text := ''
g_last_text := ''
ctx := A_Args[1]

socket := zmq_socket(ctx, ZMQ_SUB)
rtn := zmq_connect(socket, "inproc://main")
rtn := zmq_setsockopt(socket, ZMQ_SUBSCRIBE, buf := StrBuf(''), buf.Size - 1)

SetTimer(exe_command , 50)
OnExit(exit)
return

exit(*)
{
    zmq_close(socket)
    zmq_ctx_shutdown(ctx)
}
exe_command(*)
{
	Critical 'on'
    global g_tt_hwnd
    try
    {
        rtn := zmq_recv_string(socket, &recv_str := '', ZMQ_DONTWAIT)
        if(rtn == -1)
            return
        if(recv_str != '')
            logger.info(recv_str)
        o := JSON.parse(recv_str)
        x := o['x']
        y := o['y']
        is_ime_char := o['is_ime_char']
        text := o['text']
        api := o['api']
    }
    catch as e
    {
        logger.info('Parse recv error!')
        return
    }

    if(text == '@stop' || text == '')
    {
        ToolTip('')
        return
    }
    try
    {
        ;ToolTip('[' api ']', x, y - 28, 1)
        switch (api)
        {
            case "youdao":
            {
                rtn := youdaocd(text)
            }
            case "baidu":
            {
                is_hz := RegExMatch(text, "\p{Han}")
                if(is_hz)
                    rtn := baiducd(text, g_config['baidu']['BaiduFanyiAPPID'], g_config['baidu']['BaiduFanyiAPPSEC'], 'zh', 'en')
                else
                    rtn := baiducd(text, g_config['baidu']['BaiduFanyiAPPID'], g_config['baidu']['BaiduFanyiAPPSEC'], 'en', 'zh')
            }
            case "ali":
            {

            }
            case 'google':
            {
                rtn := googlecd(text)
            }
            default:
        }
        logger.info(rtn)
    }
    catch as e
    {
        return
    }
    g_tt_hwnd := ToolTip('[' api '] ' rtn, x, y - 28, 1)
    A_Clipboard := rtn
	Critical 'off'
}

youdaocd(text)
{
    Url := 'http://fanyi.youdao.com/translate?smartresult=dict&smartresult=rule&smartresult=ugc&sessionFrom=null'
    postdata := 'type=AUTO&i=' text '&doctype=json&xmlVersion=1.4&keyfrom=fanyi.web&ue=UTF-8&typoResult=true&flag=false'
    rtn := WinHttp(Url ,"POST", postdata)
    str := byteToStr(rtn, 'UTF-8')
    js := JSON.parse(str)
    return js['translateResult'][1][1]['tgt']
}
;发送接收数据
WinHttp(Httpurl, Httpmode := "GET", Httppostdata := "")
{
    Httpmode := StrUpper(Httpmode) 
    XMLHTTP := ComObject("Microsoft.XMLHTTP")
    XMLHTTP.open(Httpmode, Httpurl, false)
    XMLHTTP.setRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 5.1; rv:11.0) Gecko/20100101 Firefox/11.0")
    if Httpmode == 'POST'
    {
        XMLHTTP.setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
        XMLHTTP.send(Httppostdata)
    }else
        XMLHTTP.send()
    return XMLHTTP.ResponseBody
}
;将原始数据流以指定的编码的形式读出
byteToStr(body, charset)
{
    Stream := ComObject("Adodb.Stream")
    Stream.Type := 1
    Stream.Mode := 3
    Stream.Open()
    Stream.Write(body)
    Stream.Position := 0
    Stream.Type := 2
    Stream.Charset := charset
    str := Stream.ReadText()
    Stream.Close()
    return str
}
; 返回包含字符串的缓冲对象.
StrBuf(str, encoding := 'UTF-8')
{
    ; 计算所需的大小并分配缓冲.
    buf := Buffer(StrPut(str, encoding))
    ; 复制或转换字符串.
    StrPut(str, buf, encoding)
    return buf
}

baiducd(keyword, BaiduFanyiAPPID := '', BaiduFanyiAPPSEC := '', from:="en", to:="zh")
{
	salt:=A_Now
    MD5Sign := StrLower(MD5_str(BaiduFanyiAPPID  keyword  salt BaiduFanyiAPPSEC))
	URL:=Format("http://api.fanyi.Baidu.com/api/trans/vip/translate?q={1}&from={2}&to={3}&appid={4}&salt={5}&sign={6}",keyword,from,to,BaiduFanyiAPPID,salt,MD5Sign )
	WebRequest := ComObject("WinHttp.WinHttpRequest.5.1")
	WebRequest.Open("GET", url)
	WebRequest.Send()
	result := WebRequest.ResponseText
    try
    {
        o := JSON.parse(result)
        result := o['trans_result'][1]['dst']
    }
    catch as e
    {
        result := ''
    }
	return result
}

MD5_str(str, encoding := 'UTF-8')
{
    bf := StrBuf(str, encoding)
    if(encoding = 'UTF-8')
        size := bf.Size - 1
    else if(encoding = 'UTF-16')
        size := bf.Size - 2
    else
        return ''

    return MD5(bf, size)
    StrBuf(str, encoding := 'UTF-8')
    {
        len := StrPut(str, encoding)
        buf := Buffer(StrPut(str, encoding))
        StrPut(str, buf, encoding)
        return buf
    }
}
MD5(Data, Size:=0)
{
	MD5_CTX:=Buffer(104), DllCall("advapi32\MD5Init", "Ptr", MD5_CTX)
	DllCall("advapi32\MD5Update", "Ptr", MD5_CTX, "Ptr", Data, "UInt", (!Size&&Type(Data)="Buffer") ? Data.Size : Size)
	DllCall("advapi32\MD5Final", "Ptr", MD5_CTX), MD5:=""
	Loop 16
		MD5 .= Format("{:02X}", NumGet(MD5_CTX, 87+A_Index, "UChar"))
	return MD5
}

googlecd(keyword, time_out := 2)
{
    ;zh-TW en
    from := 'en'
    to := 'zh-CN'
    if(RegExMatch(keyword, "\p{Han}"))
    {
        from := 'zh-CN'
        to := 'en'
    }
    ;https://translate.googleapis.com/translate_a/single?dt=t&client=gtx&sl=%from_lang%&tl=%to_lang%&dj=1&ie=UTF-8&oe=UTF-8&q=%text_selected%
    URL := Format('https://translate.googleapis.com/translate_a/single?dt=t&client=gtx&sl={1}&tl={2}&dj=1&ie=UTF-8&oe=UTF-8&q={3}', from, to, EncodeDecodeURI(keyword))
	WebRequest := ComObject("WinHttp.WinHttpRequest.5.1")
	WebRequest.Open("GET", url, true)
    WebRequest.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36")
	WebRequest.Send()
    try
    {
        WebRequest.WaitForResponse(time_out)
	    result := WebRequest.ResponseText
        o := JSON.parse(result)
        result := o['sentences'][1]['trans']
    }
    catch as e
    {
        result := ''
    }
	return result
}


EncodeDecodeURI(str, encode := true, component := true) {
    ; Adapted from teadrinker: https://www.autohotkey.com/boards/viewtopic.php?p=372134#p372134
    static Doc, JS
    if !IsSet(Doc) {
        Doc := ComObject("htmlfile")
        Doc.write('<meta http-equiv="X-UA-Compatible" content="IE=9">')
        JS := Doc.parentWindow
        ( Doc.documentMode < 9 && JS.execScript() )
    }
    Return JS.%( (encode ? "en" : "de") . "codeURI" . (component ? "Component" : "") )%(str)
}
