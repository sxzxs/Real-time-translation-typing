#Requires AutoHotkey v2+
#include <Direct2DRender>
#include <zmq>
#include <log>
#include <WebView2>
#include <ComVar>
#include <btt>
#include <WinHttpRequest>
#include ./utility/网页翻译集合.ah2
#include ./utility/sound.ah2
#include ./utility/lol_game.ah2

logger.is_log_open := false
logger.is_use_editor := true
logger.level := 4

CoordMode('ToolTip', 'Screen')
CoordMode('Mouse', 'Screen')
OnMessage(WM_CHAR := 0x0102, ON_MESSAGE_WM_CHAR)
OnMessage(WM_IME_CHAR := 0x0286, ON_MESSAGE_WM_IME_CHAR)

OnMessage(0x0100, ON_WM_KEYDOWN)  ; 0x0100 是 WM_KEYDOWN
;OnMessage(0x0101, ON_WM_KEYUP)    ; 0x0101 是 WM_KEYUP

main()
main()
{
    btt('加载中。。。',0, 0,,OwnzztooltipStyle1,{Transparent:180,DistanceBetweenMouseXAndToolTip:-100,DistanceBetweenMouseYAndToolTip:-20})
    global g_all_api := ['youdao', 'sougou', 'deepl', 'baidu']
    ;global g_all_api := ['sougou']
    global g_eb := Edit_box(0, 0, 1000, 100)
    global g_sound := SoundINput(A_ScriptDir '\lib\语音.html')
    global g_is_sound_mode := false
    g_sound.set_out_change_call_back(sound_call_back)
    global g_is_ime_char := false
    global g_cursor_x := 0
    global g_cursor_y := 0
    global g_current_api := 'youdao'
    global g_window_hwnd := 0
    global g_is_input_mode := true
    global g_lol_api := Lcu()

    zmq_version(&a := 0, &b := 0, &c := 0)
    logger.info("版本: ", a, b, c)
    ctx := zmq_ctx_new()
    global g_requester := zmq_socket(ctx, ZMQ_REQ)
    ;设置超时时间 -1无限等待, 0立即返回
    buf := Buffer(4), NumPut("int", 1000, buf)
    zmq_setsockopt(g_requester, ZMQ_RCVTIMEO, buf, buf.Size)
    rtn := zmq_connect(g_requester, "tcp://localhost:5555")

    g_eb.hide()

	HotIfWinExist("ahk_class RiotWindowClass")
        Hotkey('XButton1', (key) => input_sound()) ;打开翻译器
        Hotkey('XButton2', (key) => send_command('Primitive')) ;打开翻译器
        Hotkey('!XButton2', (key) => (g_eb.text := '/all ' g_eb.text, send_command('Primitive'))) ;打开翻译器
        Hotkey('^XButton2', (key) => (g_eb.text := '/all ' g_eb.text, g_eb.fanyi_result := '/all ' g_eb.fanyi_result, send_command(''))) ;打开翻译器
        Hotkey('+XButton2', (key) => send_command('')) ;打开翻译器
        Hotkey('^f8', (key) => switch_lol_send_mode())
    HotIf()
    Hotkey('!i', (key) => input_sound()) ;打开翻译器
    Hotkey('!y', (key) => fanyi()) ;打开翻译器
    Hotkey('^!y', (key) => fanyi_clipboard()) ;翻译粘贴板文本
    Hotkey('^f7', (key) => g_eb.debug()) ;调试
    Hotkey('~Esc', (key) => g_eb.hide()) ;退出
	HotIfWinExist("ahk_id " g_eb.ui.hwnd)
        Hotkey("!enter", sound_play) ;发音
        Hotkey("enter", (key) => send_command('translate')) ;发送文本
        Hotkey("^enter", (key) => send_command('Primitive')) ;发送原始文本
        Hotkey("~tab", tab_send) ;切换API
        Hotkey("^v", paste) ;粘贴
        Hotkey("^c", copy) ;复制
        Hotkey("+!enter", (key) => serpentine_naming('hump')) ;驼峰命名
        Hotkey("^!enter", (key) => serpentine_naming('snake')) ;snake命名
    HotIf()

    help_text := '
    (
        欢迎使用实时打字翻译工具
        ALT Y : 打开(键盘输入)
        ALT I : 打开(语音输入)
        ENTER : 发送结果
        CTRL ENTER : 发送原始文本
        ALT ENTER : 发音
        CTRL F7 : 展示当前API网页原始内容
        ESC : 退出
    )'
    btt(help_text,0, 0,,OwnzztooltipStyle1,{Transparent:180,DistanceBetweenMouseXAndToolTip:-100,DistanceBetweenMouseYAndToolTip:-20})
}

sound_call_back(name, text)
{
    logger.info(name, text)
    g_eb.set_text(text)
    g_eb.draw()
}

fanyi_clipboard(*)
{
    fanyi()
    g_eb.text := A_Clipboard
    g_eb.draw()
}


serpentine_naming(key := 'snake')
{
    global g_window_hwnd
    old := A_Clipboard
    cd_str := g_eb.fanyi_result
    g_eb.hide()
    cd_str := StrLower(cd_str)
    cd_str := RegExReplace(cd_str, 'i)\s+', '_')
    cd_str := RegExReplace(cd_str, "[^A-Za-z0-9_]", "")
    cd_str := Trim(cd_str, '_')

    if(key == 'hump')
    {
        ar := StrSplit(cd_str, '_')
        cd_str := ''
        for k,v in ar
            cd_str .= StrTitle(v)
    }

    A_Clipboard := cd_str
    if(g_window_hwnd)
    {
        try
        {
            WinActivate(g_window_hwnd)
            WinWaitActive(g_window_hwnd,, 1)
        }
    }
    SendInput('{RShift Down}{Insert}{RShift Up}')
    Sleep(200)
    ; A_Clipboard := old
}

copy(*)
{
    A_Clipboard := g_eb.fanyi_result
}

paste(*)
{
    g_eb.text := A_Clipboard
    g_eb.draw()
}

sound_play(*)
{
    data := g_eb.fanyi_result
    is_hz := RegExMatch(data, "\p{Han}")
    data := EncodeDecodeURI(data)
    if(!is_hz)
    {
        PlayMedia('https://dict.youdao.com/dictvoice?audio=' data)
        logger.info('https://dict.youdao.com/dictvoice?audio=' data)
    }
    else
    {
        PlayMedia('https://api.oick.cn/txt/apiz.php?text=' data '&spd=10')
        logger.info('https://api.oick.cn/txt/apiz.php?text=' data '&spd=10')
    }
}
switch_lol_send_mode(p*)
{
    global g_is_input_mode
    g_is_input_mode := !g_is_input_mode
}

send_command(p*)
{
    global g_window_hwnd
    static before_txt := g_eb.text
    try
    {
        data := g_eb.text
        g_eb.hide()
        old := A_Clipboard
        if(p[1] == 'Primitive')
            A_Clipboard := data
        else
            A_Clipboard := g_eb.fanyi_result, data := g_eb.fanyi_result
        if(g_window_hwnd)
        {
            try
            {
                WinActivate(g_window_hwnd)
                WinWaitActive(g_window_hwnd,, 1)
            }
        }

        if(WinActive('ahk_class RiotWindowClass'))
        {
            if(g_is_input_mode)
            {
                if(data == '' || data == '/all ')
                    SendCn(data before_txt)
                else
                {
                    SendCn(data)
                    before_txt := data
                }
            }
            else
            {

                if(data == '' || data == '/all ')
                    sendcmd2game(data before_txt)
                else
                {
                    sendcmd2game(data)
                    before_txt := data
                }
            }
        }
        else
        {
            SendInput('{RShift Down}{Insert}{RShift Up}')
            sleep(200)
        }
        A_Clipboard := old
    }
    catch as e
    {
        logger.err(e.Message)
    }
}

tab_send(*)
{
    global g_current_api
    global g_all_api
    ;找到当前index
    current_index := 1
    for k,v in g_all_api
    {
        if(v = g_current_api)
        {
            current_index := k
            break
        }
    }
    current_index++
    if(current_index > g_all_api.Length)
        current_index := 1
    g_current_api := g_all_api[current_index]
    logger.info('=========' g_current_api)
    btt('[' g_current_api ']',g_cursor_x, g_cursor_y - 45,,OwnzztooltipStyle1,{Transparent:180,DistanceBetweenMouseXAndToolTip:-100,DistanceBetweenMouseYAndToolTip:-20})
    g_eb.draw('tab')
}

input_sound(*)
{
    global g_cursor_x
    global g_cursor_y
    global g_window_hwnd
    global g_is_sound_mode

    g_is_sound_mode := true
    
    if(WinActive('ahk_class RiotWindowClass'))
    {
        g_window_hwnd := WinExist("A")
        x := A_ScreenWidth / 2, y:= A_ScreenHeight / 2
    }
    else
    {
        if(!(g_window_hwnd := GetCaretPosEx(&x, &y, &w, &h)))
        {
            g_window_hwnd := WinExist("A")
            MouseGetPos(&x, &y)
        }
    }

    g_cursor_x := Integer(x)
    g_cursor_y := Integer(y)
    g_eb.show(x, y)
    btt('[' g_current_api ']',g_cursor_x, g_cursor_y - 45,,OwnzztooltipStyle1,{Transparent:180,DistanceBetweenMouseXAndToolTip:-100,DistanceBetweenMouseYAndToolTip:-20})

    js := "
    (
        document.querySelector("#final").innerHTML = '';
        speechRecognition.start();
    )"
    g_sound.start()

    g_eb.draw()
}

fanyi(*)
{
    global g_cursor_x
    global g_cursor_y
    global g_window_hwnd
    if(!(g_window_hwnd := GetCaretPosEx(&x, &y, &w, &h)))
    {
        g_window_hwnd := WinExist("A")
        MouseGetPos(&x, &y)
    }
    g_cursor_x := x
    g_cursor_y := y
    g_eb.show(x, y)
    btt('[' g_current_api ']',g_cursor_x, g_cursor_y - 45,,OwnzztooltipStyle1,{Transparent:180,DistanceBetweenMouseXAndToolTip:-100,DistanceBetweenMouseYAndToolTip:-20})
    g_eb.draw()
}
ON_WM_KEYDOWN(a*)
{
    if(a[1] == 37)
        g_eb.left()
    else if(a[1] == 39)
        g_eb.right()
}

ON_MESSAGE_WM_CHAR(a*)
{
    logger.info(a*)
    logger.info(num2utf16(a[1]))
    if(a[2] != 1)
        g_eb.set_imm(a[1])
}
ON_MESSAGE_WM_IME_CHAR(a*)
{
    global g_is_ime_char
    g_is_ime_char := true
    logger.info(a*)
    logger.info(num2utf16(a[1]))
    g_eb.set_imm(a[1])
}

class Edit_box
{
    __New(x, y, w, h) 
    {
        this.x := 0
        this.y := 0
        this.w := w
        this.h := h
        this.ui := Direct2DRender(x, y, w, h,,, true)
        this.text := ''
        this.fanyi_result := ''
        this.insert_pos := 0 ;距离txt最后边的距离

        if(this.has_key('sougou'))
        {
            this.sg := sg := Sougou_web_cd()
            sg.set_out_change_call_back(this.on_change.bind(this))
            sg.set_input_box('我来自搜狗')
        }

        if(this.has_key('youdao'))
        {
            this.yd := yd := Youdao_web_cd()
            yd.set_out_change_call_back(this.on_change.bind(this))
            yd.set_input_box('我来自有道')
        }

        if(this.has_key('baidu'))
        {
            this.bd := bd := Baidu_web_cd()
            bd.set_out_change_call_back(this.on_change.bind(this))
            bd.set_input_box('我来自百度')
        }

        if(this.has_key('deepl'))
        {
            this.dp := dp := Deepl_web_cd()
            dp.set_out_change_call_back(this.on_change.bind(this))
            dp.set_input_box('我来自Deepl')
        }

        this.show_status := false
    }
    has_key(key)
    {
        global g_all_api
        for k,v in g_all_api
        {
            if(v = key)
                return true
        }
        return false
    }
    debug()
    {
        try
        {
            switch(g_current_api)
            {
                case 'baidu':
                {
                    this.bd.show(,, 1000, 700)
                }
                case 'sougou':
                {
                    this.sg.show(,, 1000, 700)
                }
                case 'youdao':
                {
                    this.yd.show(,, 1000, 700)
                }
                case 'deepl':
                {
                    this.dp.show(,, 1000, 700)
                }
            }
            g_sound.show()
        }
    }
    on_change(cd ,text)
    {
        logger.info(cd ,text)
        logger.info()
        if(this.show_status && cd = g_current_api)
        {
            this.fanyi_result := text
            this.ui.gui.GetPos(&x, &y, &w, &h)
            btt(cd ':' text,x, y - 45,,OwnzztooltipStyle1,{Transparent:180,DistanceBetweenMouseXAndToolTip:-100,DistanceBetweenMouseYAndToolTip:-20})
        }
    }
    show(x := 0, y := 0)
    {
        if(g_is_sound_mode)
            this.ui.gui.show('x' x ' y' y ' NA')
        else
            this.ui.gui.show('x' x ' y' y)
        this.show_status := true
    }
    hide()
    {
        global g_is_sound_mode
        global g_is_ime_char
        this.clear()
        this.ui.gui.hide()
        g_is_ime_char := false
        this.show_status := false
        if(g_is_sound_mode)
            g_sound.stop()
        g_is_sound_mode := false
        OwnzztooltipEnd()
    }
    move(x, y, w := 0, h := 0)
    {
        this.ui.SetPosition(x, y, w, h)
    }
    draw(flag := 0)
    {
        global g_current_api
        ui := this.ui
        ui.gui.GetPos(&x, &y, &w, &h)
        logger.info(x, y, w, h)
        ;计算文字的大小
        wh := this.ui.GetTextWidthHeight(this.text, 20)
        last_txt_wh := this.ui.GetTextWidthHeight(SubStr(this.text, -this.insert_pos), 20)
        logger.info(wh)
        this.move(x, y, wh.width + 100, wh.height + 100)
        if(ui.BeginDraw())
        {
            ui.FillRoundedRectangle(0, 0, wh.width, wh.height, 5, 5, 0xcc1E1E1E)
            ui.DrawRoundedRectangle(0, 0, wh.width, wh.height, 5, 5, 0xffff0000, 1)
            ui.DrawText(this.text, 0, 0, 20, 0xFFC9E47E)
            ui.DrawLine(wh.width - last_txt_wh.width, 0, wh.width - last_txt_wh.width, wh.height, 0xAA00FF00)
            logger.err(this.text)
            ui.EndDraw()
        }
        input_text := this.text
        if(flag = 'tab')
        {
            switch(g_current_api)
            {
                case 'baidu':
                {
                    this.bd.set_input_box('')
                }
                case 'sougou':
                {
                    this.sg.set_input_box('')
                }
                case 'youdao':
                {
                    this.yd.set_input_box('')
                }
                case 'deepl':
                {
                    this.dp.set_input_box('')
                }
            }
        }
        switch(g_current_api)
        {
            case 'baidu':
            {
                this.bd.set_input_box(input_text)
            }
            case 'sougou':
            {
                this.sg.set_input_box(input_text)
            }
            case 'youdao':
            {
                this.yd.set_input_box(input_text)
            }
            case 'deepl':
            {
                this.dp.set_input_box(input_text)
            }
        }
    }
    clear()
    {
        this.text := ''
        this.insert_pos := 0
    }
    push(char)
    {
        logger.info(char)
        logger.err(this.text)
        left_txt := SubStr(this.text, 1, StrLen(this.text) - this.insert_pos)
        right_txt := SubStr(this.text, -this.insert_pos)
        logger.err(left_txt, right_txt)
        if(char == '`b')
        {
            ;this.text := SubStr(this.text, 1, -1)
            this.text := SubStr(left_txt, 1, -1) right_txt
        }
        else
        {
            ;this.text .= char
            this.text := left_txt char right_txt
        }
        logger.err(this.text, this.insert_pos)
    }
    set_text(text)
    {
        this.text := text
    }
    left()
    {
        if(this.insert_pos < StrLen(this.text))
            this.insert_pos += 1
        this.draw()
    }
    right()
    {
        if(this.insert_pos > 0)
            this.insert_pos -= 1
        this.draw()
    }
    set_imm(char)
    {
        himc := ImmGetContext(this.ui.Hwnd)
        composition_form := COMPOSITIONFORM()
        composition_form.ptCurrentPos.x := 0
        composition_form.ptCurrentPos.y := 10
        composition_form.rcArea.left :=  0
        composition_form.rcArea.top :=  0
        composition_form.rcArea.right :=  100
        composition_form.rcArea.bottom := 100
        composition_form.dwStyle := 0x0020 ;CFS_FORCE_POSITION
        rtn := ImmSetCompositionWindow(himc, composition_form)

        candidate_form := CANDIDATEFORM()
        candidate_form.dwStyle := 0x0040 ;CFS_CANDIDATEPOS 
        candidate_form.ptCurrentPos.x := 0
        candidate_form.ptCurrentPos.y := 20

        rtn := ImmSetCandidateWindow(himc, candidate_form)
        ImmReleaseContext(this.ui.Hwnd, himc)
        logger.info(num2utf16(char))
        this.push(num2utf16(char))
        this.draw()
    }
}

class RECT extends ctypes.struct
{
	static fields := [['int', 'left'], ['int', 'top'], ['int', 'right'], ['int', 'bottom']]
}

class POINT extends ctypes.struct
{
    static  fields := [['int', 'x'], ['int', 'y']]
}

class COMPOSITIONFORM extends ctypes.struct
{
    static  fields := [['uint', 'dwStyle'], ['POINT', 'ptCurrentPos'], ['RECT', 'rcArea']]
}

class CANDIDATEFORM extends ctypes.struct
{
    static  fields := [['uint', 'dwIndex'], ['uint', 'dwStyle'], ['POINT', 'ptCurrentPos'], ['RECT', 'rcArea']]
}

ImmGetContext(hwnd)
{
    return DllCall('imm32\ImmGetContext', 'int', hwnd, 'int')
}
ImmSetCompositionWindow(HIMC, lpCompForm) ;COMPOSITIONFORM
{
    return DllCall('imm32\ImmSetCompositionWindow', 'int', HIMC, 'ptr', lpCompForm, 'int')
}
ImmSetCandidateWindow(HIMC, lpCandidate) ;CANDIDATEFORM
{
    return DllCall('imm32\ImmSetCandidateWindow', 'int', HIMC, 'ptr', lpCandidate, 'int')
}
ImmReleaseContext(hwnd, HIMC)
{
    return DllCall('imm32\ImmReleaseContext', 'int', hwnd, 'int', HIMC, 'int')
}
ImmSetOpenStatus(HIMC, status) ; HIMC, bool 
{
    return DllCall('imm32\ImmSetOpenStatus', 'int', HIMC, 'int', status, 'int')
}
ImmGetOpenStatus(HIMC)
{
    return DllCall('imm32\ImmGetOpenStatus', 'int', HIMC, 'int')
}
ImmAssociateContext(hwnd, HIMC)
{
    return DllCall('imm32\ImmAssociateContext', 'int', hwnd, 'int', HIMC, "int")
}

num2utf16(code)
{
    bf := Buffer(2, 0)
    NumPut('short', code, bf)
    return StrGet(bf, 1, 'UTF-16')
}

GetCaretPosEx(&x?, &y?, &w?, &h?) 
{
    x := h := w := h := 0
    static iUIAutomation := 0, hOleacc := 0, IID_IAccessible, guiThreadInfo, _ := init()
    if !iUIAutomation || ComCall(8, iUIAutomation, "ptr*", eleFocus := ComValue(13, 0), "int") || !eleFocus.Ptr
        goto useAccLocation
    if !ComCall(16, eleFocus, "int", 10002, "ptr*", valuePattern := ComValue(13, 0), "int") && valuePattern.Ptr
        if !ComCall(5, valuePattern, "int*", &isReadOnly := 0) && isReadOnly
            return 0
    useAccLocation:
    ; use IAccessible::accLocation
    hwndFocus := DllCall("GetGUIThreadInfo", "uint", DllCall("GetWindowThreadProcessId", "ptr", WinExist("A"), "ptr", 0, "uint"), "ptr", guiThreadInfo) && NumGet(guiThreadInfo, A_PtrSize == 8 ? 16 : 12, "ptr") || WinExist()
    if hOleacc && !DllCall("Oleacc\AccessibleObjectFromWindow", "ptr", hwndFocus, "uint", 0xFFFFFFF8, "ptr", IID_IAccessible, "ptr*", accCaret := ComValue(13, 0), "int") && accCaret.Ptr {
        NumPut("ushort", 3, varChild := Buffer(24, 0))
        if !ComCall(22, accCaret, "int*", &x := 0, "int*", &y := 0, "int*", &w := 0, "int*", &h := 0, "ptr", varChild, "int")
            return hwndFocus
    }
    if iUIAutomation && eleFocus {
        ; use IUIAutomationTextPattern2::GetCaretRange
        if ComCall(16, eleFocus, "int", 10024, "ptr*", textPattern2 := ComValue(13, 0), "int") || !textPattern2.Ptr
            goto useGetSelection
        if ComCall(10, textPattern2, "int*", &isActive := 0, "ptr*", caretTextRange := ComValue(13, 0), "int") || !caretTextRange.Ptr || !isActive
            goto useGetSelection
        if !ComCall(10, caretTextRange, "ptr*", &rects := 0, "int") && rects && (rects := ComValue(0x2005, rects, 1)).MaxIndex() >= 3 {
            x := rects[0], y := rects[1], w := rects[2], h := rects[3]
            return hwndFocus
        }
        useGetSelection:
        ; use IUIAutomationTextPattern::GetSelection
        if textPattern2.Ptr
            textPattern := textPattern2
        else if ComCall(16, eleFocus, "int", 10014, "ptr*", textPattern := ComValue(13, 0), "int") || !textPattern.Ptr
            goto useGUITHREADINFO
        if ComCall(5, textPattern, "ptr*", selectionRangeArray := ComValue(13, 0), "int") || !selectionRangeArray.Ptr
            goto useGUITHREADINFO
        if ComCall(3, selectionRangeArray, "int*", &length := 0, "int") || length <= 0
            goto useGUITHREADINFO
        if ComCall(4, selectionRangeArray, "int", 0, "ptr*", selectionRange := ComValue(13, 0), "int") || !selectionRange.Ptr
            goto useGUITHREADINFO
        if ComCall(10, selectionRange, "ptr*", &rects := 0, "int") || !rects
            goto useGUITHREADINFO
        rects := ComValue(0x2005, rects, 1)
        if rects.MaxIndex() < 3 {
            if ComCall(6, selectionRange, "int", 0, "int") || ComCall(10, selectionRange, "ptr*", &rects := 0, "int") || !rects
                goto useGUITHREADINFO
            rects := ComValue(0x2005, rects, 1)
            if rects.MaxIndex() < 3
                goto useGUITHREADINFO
        }
        x := rects[0], y := rects[1], w := rects[2], h := rects[3]
        return hwndFocus
    }
    useGUITHREADINFO:
    if hwndCaret := NumGet(guiThreadInfo, A_PtrSize == 8 ? 48 : 28, "ptr") {
        if DllCall("GetWindowRect", "ptr", hwndCaret, "ptr", clientRect := Buffer(16)) {
            w := NumGet(guiThreadInfo, 64, "int") - NumGet(guiThreadInfo, 56, "int")
            h := NumGet(guiThreadInfo, 68, "int") - NumGet(guiThreadInfo, 60, "int")
            DllCall("ClientToScreen", "ptr", hwndCaret, "ptr", guiThreadInfo.Ptr + 56)
            x := NumGet(guiThreadInfo, 56, "int")
            y := NumGet(guiThreadInfo, 60, "int")
            return hwndCaret
        }
    }
    return 0
    static init() {
        try
            iUIAutomation := ComObject("{E22AD333-B25F-460C-83D0-0581107395C9}", "{30CBE57D-D9D0-452A-AB13-7AC5AC4825EE}")
        hOleacc := DllCall("LoadLibraryW", "str", "Oleacc.dll", "ptr")
        NumPut("int64", 0x11CF3C3D618736E0, "int64", 0x719B3800AA000C81, IID_IAccessible := Buffer(16))
        guiThreadInfo := Buffer(A_PtrSize == 8 ? 72 : 48), NumPut("uint", guiThreadInfo.Size, guiThreadInfo)
    }
}

;by tebayaki
;PlayMedia("https://dict.youdao.com/dictvoice?audio=apple")

PlayMedia(uri, time_out := 5000) 
{
    DllCall("Combase\RoActivateInstance", "ptr", CreateHString("Windows.Media.Playback.MediaPlayer"), "ptr*", iMediaPlayer := ComValue(13, 0), "HRESULT")
    iUri := CreateUri(uri)
    ComCall(47, iMediaPlayer, "ptr", iUri) ; SetUriSource
    ComCall(45, iMediaPlayer) ; Play
    index := 1
    loop {
        ComCall(12, iMediaPlayer, "uint*", &state := 0) ; CurrentState
        if(index != 1)
            Sleep(20)
        index++
    } until (state == 3 || index > (time_out / 20))

    index := 1
    loop {
        ComCall(12, iMediaPlayer, "uint*", &state := 0) ; CurrentState
        if(index != 1)
            Sleep(20)
        index++
        Sleep(20)
    } until (state == 4 || index > (time_out / 20))
}

CreateUri(str) 
{
    DllCall("ole32\IIDFromString", "str", "{44A9796F-723E-4FDF-A218-033E75B0C084}", "ptr", iid := Buffer(16), "HRESULT")
    DllCall("Combase\RoGetActivationFactory", "ptr", CreateHString("Windows.Foundation.Uri"), "ptr", iid, "ptr*", factory := ComValue(13, 0), "HRESULT")
    ComCall(6, factory, "ptr", CreateHString(str), "ptr*", uri := ComValue(13, 0))
    return uri
}

CreateHString(str) 
{
    DllCall("Combase\WindowsCreateString", "wstr", str, "uint", StrLen(str), "ptr*", &hString := 0, "HRESULT")
    return { Ptr: hString, __Delete: (_) => DllCall("Combase\WindowsDeleteString", "ptr", _, "HRESULT") }
}

loadconfig(&config, json_path)
{
    outputvar := FileRead(json_path)
    config := JSON.parse(outputvar)
}
;保存配置函数
saveconfig(config, json_path)
{
    str := JSON.stringify(config, 4)
    FileDelete(json_path)
    FileAppend(str, json_path, 'UTF-8')
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

sendcmd2game(str)
{
    logger.info("sendcn")
    g_lol_api.get_hero_name_and_id(&name, &id)
	;<font color="#40C1FF">[队伍] 玩家名 (英雄名): </font><font color="#FFFFFF">喊话内容</font>	
    if(InStr(str, '/all '))
    {
        str := LTrim(str, '/all ')
        zmq_send_string(g_requester,'<font color="#ff0000">[所有人] ' id  '(' name '): </font><font color="#FFFFFF">' str '</font>')
    }
    else
    {
        zmq_send_string(g_requester,'<font color="#40C1FF">[队伍] ' id  '(' name '): </font><font color="#FFFFFF">' str '</font>')
    }

    rtn := zmq_recv_string(g_requester, &recv_string := '')
    logger.info("sendcn ok")
}

SendCn(str)
{
    SendInput("{Enter}")
    Sleep(200)
    charList:=StrSplit(str)
    for key,val in charList{
        ; 转换每个字符为{U+16进制Unicode编码}
        out.="{U+" . Format("{:X}",ord(val)) . "}"
    }
    SendInput(out)
    Sleep(400)
    SendInput("{Enter}")
}
