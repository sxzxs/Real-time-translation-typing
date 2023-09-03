;杂项函数
;by Tebayaki
;读取进程标准输出
ReadProcessStdOut(cmd, stdin := "", encoding := "cp0", is_wait := true) {
    sa := Buffer(24)
    NumPut("uint", sa.Size, sa)
    NumPut("ptr", 0, "uint", 1, sa, 8)

    if !DllCall("CreatePipe", "ptr*", &hReadPipeOut := 0, "ptr*", &hWritePipeOut := 0, "ptr", sa, "uint", 0)
        throw OSError()
    DllCall("SetHandleInformation", "ptr", hReadPipeOut, "uint", 1, "uint", 0)

    si := Buffer(104, 0)
    NumPut("uint", si.Size, si)
    NumPut("uint", 0x101, si, 60)
    NumPut("ptr", hWritePipeOut, si, 88)

    if stdin !== "" {
        if !DllCall("CreatePipe", "ptr*", &hReadPipeIn := 0, "ptr*", &hWritePipeIn := 0, "ptr", sa, "uint", 0)
            throw OSError()
        DllCall("SetHandleInformation", "ptr", hWritePipeIn, "uint", 1, "uint", 0)
        NumPut("ptr", hReadPipeIn, si, 80)
    }

    if !DllCall("CreateProcessW", "ptr", 0, "str", cmd, "ptr", 0, "ptr", 0, "int", true, "uint", 0, "ptr", 0, "ptr", 0, "ptr", si, "ptr", pi := Buffer(24)) {
        DllCall("CloseHandle", "ptr", hWritePipeOut)
        DllCall("CloseHandle", "ptr", hReadPipeOut)
        throw OSError()
    }
    DllCall("CloseHandle", "ptr", NumGet(pi, "ptr"))
    DllCall("CloseHandle", "ptr", NumGet(pi, 8, "ptr"))
    DllCall("CloseHandle", "ptr", hWritePipeOut)


    if stdin !== "" {
        DllCall("CloseHandle", "ptr", hReadPipeIn)
        if !DllCall("WriteFile", "ptr", hWritePipeIn, "astr", stdin, "uint", StrPut(stdin, encoding) - 1, "uint*", &lpNumberOfBytesWritten := 0, "ptr", 0){
            DllCall("CloseHandle", "ptr", hWritePipeIn)
            throw OSError()
        }
        DllCall("CloseHandle", "ptr", hWritePipeIn)
    }

	if(!is_wait)
		return

    stdout := ""
    while DllCall("ReadFile", "ptr", hReadPipeOut, "ptr", buf := Buffer(4096), "uint", buf.Size, "uint*", &lpNumberOfBytesRead := 0, "ptr", 0) && lpNumberOfBytesRead
        stdout .= StrGet(buf, lpNumberOfBytesRead, encoding)
    DllCall("CloseHandle", "ptr", hReadPipeOut)

    return stdout
}
;使用案例,脚本改名都没用,照样只能运行一个.
/*
if(Single("456")) 
{
	MsgBox('提示,程序已启动!`n请勿重复运行')
	ExitApp
}
*/
;返回1为重复,返回0为第一个运行
class Single_instance
{
	static create(flag)
	{
		this.handle := DllCall("CreateMutex", "Ptr",0, "int",0, "str", "Ahk_Single_" flag)
		return A_LastError == 0xB7 ? true : false
	}
	static close()
	{
		DllCall("CloseHandle", 'ptr', this.handle)
	}
}
;清理重复进程
instance_once()
{
    CurPID := DllCall("GetCurrentProcessId")
    List := WinGetList(A_ScriptFullPath ' ahk_class AutoHotkey')
	for k,v in List
    { 
		PID := WinGetPID('ahk_id ' v)
        If (PID != CurPID)
			ProcessWaitClose(PID)
    }
}

ExecScript(Script, Params := "", AhkPath := "") 
{
    Name := Pipe := Call := Shell := Exec := ''
    Name := "AHK_CQT_" . A_TickCount
    Pipe := []
    Loop(2) 
	{
        Pipe.Push(DllCall("CreateNamedPipe"
        , "Str", "\\.\pipe\" . Name
        , "UInt", 2, "UInt", 0
        , "UInt", 255, "UInt", 0
        , "UInt", 0, "UPtr", 0
        , "UPtr", 0, "UPtr"))
    }

    If (!FileExist(AhkPath)) 
        AhkPath := A_AhkPath

    Call := AhkPath ' /CP65001 \\.\pipe\' Name
    shell := ComObject("WScript.Shell")
    Exec := Shell.Exec(Call . " " . Params)
    DllCall("ConnectNamedPipe", "UPtr", Pipe[1], "UPtr", 0)
    DllCall("CloseHandle", "UPtr", Pipe[1])
    DllCall("ConnectNamedPipe", "UPtr", Pipe[2], "UPtr", 0)
    FileOpen(Pipe[2], "h", "UTF-8").Write(Script)
    DllCall("CloseHandle", "UPtr", Pipe[2])
    Return Exec
}
switchime(ime := "A")
{
	if (ime = 1)
		DllCall("SendMessage", 'UInt', WinActive("A"), 'UInt', 80, 'UInt', 1, 'UInt', DllCall("LoadKeyboardLayout", 'Str',"00000804", 'UInt', 1))
	else if (ime = 0)
		DllCall("SendMessage", 'UInt', WinActive("A"), 'UInt', 80, 'UInt', 1, 'UInt', DllCall("LoadKeyboardLayout", 'Str','', 'UInt', 1))
	else if (ime = "A")
		Send('#{Space}')
}

RunAsAdmin() 
{
    if !A_IsAdmin && !(DllCall("GetCommandLine", "str") ~= " /restart(?!\S)") 
	{
        try Run('*RunAs "' (A_IsCompiled ? A_ScriptFullPath '" /restart' : A_AhkPath '" /restart "' A_ScriptFullPath '"'))
        ExitApp
    }
}

; by just me
Edit_VCENTER(HEDIT) { ; The Edit control must have the ES_MULTILINE style (0x0004 \ +Multi)!
   ; EM_GETRECT := 0x00B2 <- msdn.microsoft.com/en-us/library/bb761596(v=vs.85).aspx
   ; EM_SETRECT := 0x00B3 <- msdn.microsoft.com/en-us/library/bb761657(v=vs.85).aspx
   RC := Buffer(16, 0)
   DllCall("User32.dll\GetClientRect", "Ptr", HEDIT, "Ptr", RC)
   CLHeight := NumGet(RC, 12, "Int")
   HFONT := SendMessage(0x0031, 0, 0, HEDIT) ;WM_GETFONT
   HDC := DllCall("GetDC", "Ptr", HEDIT, "UPtr")
   DllCall("SelectObject", "Ptr", HDC, "Ptr", HFONT)
   RC := Buffer(16, 0)
   DTH := DllCall("DrawText", "Ptr", HDC, "Str", "W", "Int", 1, "Ptr", RC, "UInt", 0x2400)
   DllCall("ReleaseDC", "Ptr", HEDIT, "Ptr", HDC)
   rtn := SendMessage(0x00BA, 0, 0, HEDIT) ; EM_GETLINECOUNT

   TXHeight := DTH * rtn
   If (TXHeight > CLHeight)
      Return False
   RC := Buffer(16, 0)
   SendMessage(0x00B2, 0, RC.Ptr, HEDIT)
   DY := (CLHeight - TXHeight) // 2
   NumPut("int", DY, RC, 4)
   NumPut("int", TXHeight + DY, RC, 12)
   SendMessage(0x00B3, 0, RC.Ptr, HEDIT)
}


;设置暗色主题，win10
set_the_dark_theme()
{

    if(instr(A_OSVersion, '10.') != 1)
        return
    ;https://stackoverflow.com/a/58547831/894589
    uxtheme := DllCall("GetModuleHandle", "str", "uxtheme", "ptr")
    SetPreferredAppMode := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 135, "ptr")
    FlushMenuThemes := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 136, "ptr")
    DllCall(SetPreferredAppMode, "int", 1) ; Dark
    DllCall(FlushMenuThemes)
}

set_editor_cursor_end(handle)
{
    SendMessage(0xB1, -2, -1,, 'ahk_id ' handle)
    SendMessage(0xB7,,,, 'ahk_id ' handle)
}

;by tebayaki
;MsgBox FindProcessByExePath("C:\Windows\explorer.exe")
FindProcessByExePath(exePath, max := 300) {
    buf := Buffer(max * 4)
    DllCall("psapi\EnumProcesses", "ptr", buf, "uint", buf.Size, "uint*", 0)
    VarSetStrCapacity(&found, 261)
    while A_Index < max && pid := NumGet(buf, A_Index * 4, "uint") {
        if h := DllCall("OpenProcess", "uint", 0x410, "int", false, "uint", pid, "ptr") {
            DllCall("psapi\GetModuleFileNameExW", "ptr", h, "ptr", 0, "str", found, "uint", 261)
            DllCall("CloseHandle", "ptr", h)
            if found = exePath
                return pid
        }
    }
    return 0
}