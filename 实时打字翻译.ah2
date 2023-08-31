#Requires AutoHotkey v2+
#include <Direct2DRender>
#include <zmq>
#include <log>

logger.is_log_open := false

CoordMode('ToolTip', 'Screen')
OnMessage(WM_CHAR := 0x0102, ON_MESSAGE_WM_CHAR)
OnMessage(WM_IME_CHAR := 0x0286, ON_MESSAGE_WM_IME_CHAR)
main()
main()
{
    global g_eb := Edit_box(0, 0, 1000, 100)
	global g_zmq_ctx := zmq_ctx_new()
	global g_sender2plug := Zmq_send2plug() ;通过zmq 和 plug通讯
    global g_thread_plug_cd := Worker('#include ' A_scriptdir '/thread.ah2', string(g_sender2plug.ctx))
    g_json_path := A_ScriptDir . "/config/setting.json"
    global g_is_ime_char := false
    global g_cursor_x := 0
    global g_cursor_y := 0

    global g_config := Map()
    loadconfig(&g_config, g_json_path)
    global g_current_api := g_config['cd']

    g_eb.hide()
	loop
	{ 
	}until(g_thread_plug_cd.Ready)
    g_thread_plug_cd['g_config'] := g_config

    Hotkey('!y', (key) => fanyi())
    Hotkey('~Esc', (key) => g_eb.hide())
	HotIfWinActive("ahk_id " g_eb.ui.hwnd)
        Hotkey("!enter", sound_play)
        Hotkey("enter", (key) => send_command('translate'))
        Hotkey("^enter", (key) => send_command('Primitive'))
        Hotkey("~tab", tab_send)
    HotIf()
}
sound_play(*)
{
    data := A_Clipboard
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

send_command(p*)
{
    data := g_eb.text
    g_eb.hide()
    if(p[1] == 'Primitive')
        A_Clipboard := data
    SendInput('{RShift Down}{Insert}{RShift Up}')
}

tab_send(*)
{
    global g_current_api
    ;找到当前index
    current_index := 1
    for k,v in g_config['all_api']
    {
        if(v = g_current_api)
        {
            current_index := k
            break
        }
    }
    loop g_config['all_api'].Length
    {
        current_index++
        if(current_index > g_config['all_api'].Length)
            current_index := 1
        api := g_config['all_api'][current_index]
        if(g_config[api]['is_open'] && g_current_api != api)
        {
            g_current_api := api
            break
        }
    }
    ToolTip('[' g_current_api ']', g_cursor_x, g_cursor_y - 28, 1)
    g_eb.draw('tab')
}

fanyi(*)
{
    global g_cursor_x
    global g_cursor_y
    if(!(hwnd := GetCaretPosEx(&x, &y, &w, &h)))
    {
        MouseGetPos(&x, &y)
    }
    g_cursor_x := x
    g_cursor_y := y
    ToolTip('[' g_current_api ']', g_cursor_x, g_cursor_y - 28, 1)
    g_eb.show(x, y)
    g_eb.draw()
}
cd(text, x := 0, y := 0)
{
    try
    {
        send2cd_param := Map()
        send2cd_param['x'] := x
        send2cd_param['y'] := y
        send2cd_param['text'] := text
        send2cd_param['is_ime_char'] := g_is_ime_char
        send2cd_param['api'] := g_current_api
        str := JSON.stringify(send2cd_param)
        g_sender2plug.pub(str)
    }
    catch as e
    {
        logger.err(e.Message)
        return
    }
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
        this.ui := Direct2DRender(x, y, w, h,,, false)
        this.text := ''
    }
    show(x := 0, y := 0)
    {
        this.ui.gui.show('x' x ' y' y)
    }
    hide()
    {
        global g_is_ime_char
        this.clear()
        this.draw('esc')
        this.ui.gui.hide()
        g_is_ime_char := false
        ToolTip()
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
        logger.info(wh)
        this.move(x, y, wh.width + 100, wh.height + 100)
        if(ui.BeginDraw())
        {
            ui.FillRoundedRectangle(0, 0, wh.width, wh.height, 5, 5, 0xcc1E1E1E)
            ui.DrawRoundedRectangle(0, 0, wh.width, wh.height, 5, 5, 0xffff0000, 1)
            ui.DrawText(this.text, 0, 0, 20, 0xFFC9E47E)
            logger.info(this.text)
            ui.EndDraw()
        }
        if(flag = 'esc' || flag = 'tab' || SubStr(this.text, -1) == A_Space)
        {
            cd(this.text, x, y)
            return
        }
        switch(g_current_api)
        {
            case 'baidu':
            {
                if(g_config['baidu']['is_real_time_translate'] = 1)
                    cd(this.text, x, y)
            }
            case 'youdao':
            {
                cd(this.text, x, y)
            }
            case 'ali':
            {
                if(g_config['ali']['is_real_time_translate'] = 1)
                    cd(this.text, x, y)
            }
        }
    }
    clear()
    {
        this.text := ''
    }
    push(char)
    {
        if(char == '`b')
            this.text := SubStr(this.text, 1, -1)
        else
            this.text .= char
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

class Zmq_send2plug
{
    __New() 
    {
		zmq_version(&a := 0, &b := 0, &c := 0)
		logger.info("zmq版本: ", a, b, c)
		this.ctx := ctx := g_zmq_ctx
		this.socket := socket := zmq_socket(ctx, ZMQ_PUB)
		rtn := zmq_bind(socket, "inproc://main")
    }
    __Delete() 
	{
		zmq_close(this.socket)
		zmq_ctx_shutdown(this.ctx)
	}
	pub(data := unset)
	{
		if(IsSet(data) == 1 || InStr(data, '@stop') || InStr(data, '@exit'))
		{
        	zmq_send_string(this.socket, data,,ZMQ_DONTWAIT)
		}
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