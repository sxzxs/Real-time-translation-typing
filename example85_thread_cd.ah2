#Requires AutoHotkey v2.0
#include <log>
#include <zmq>
CoordMode('ToolTip', 'Screen')
Persistent

logger.is_log_open := true
logger.is_use_editor := true

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
        text := o['text']
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
        rtn := youdaocd(text)
        logger.info(rtn)
    }
    catch as e
    {
        return
    }
    g_tt_hwnd := ToolTip(rtn, x, y - 28, 1)
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