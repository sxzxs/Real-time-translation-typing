Persistent
;exsample
;   logger.is_out_console := true
;   logger.is_out_file := true
;   logger.info("hello log")
;   logger.warn("hello log")
;   logger.error("hello log")
;   logger.critical("hello log")
class logger
{
    static line := true
    static file := true
    static func := true
    static is_extern_info := true
    static is_log_open := true
    static is_out_console := true
    static is_out_file := false
    static console_create_flag := false
    static log_mode := 1
    static is_formate := true
    static log_strim := ""
    static is_dll_load := false
    static is_use_cmder := false
    static is_use_editor := true
    static is_console_config := false
    static level_trace := 1
    static level_debug := 2
    static level_info := 3
    static level_warn := 4
    static level_error := 5
    static level_critical := 6
    static default_patter := "[%Y-%m-%d %H:%M:%S.%e] [thread %=7t] [%=8l] %^%v%$   (%ius)" ;https://github.com/gabime/spdlog/wiki/3.-Custom-formatting
    static LOG4AHK_G_MY_DLL_USE_MAP := map("cpp2ahk.dll" , map("cpp2ahk", 0, "log_simple", 0, "log_simple_mt_color", 0, "set_console_transparency", 0, "log_set_format", 0))
    static log4ahk_load_all_dll_path()
    {
        SplitPath(A_LineFile,,&dir)
        path := ""
        lib_path := dir
        if(A_IsCompiled)
        {
            path := (A_PtrSize == 4) ? A_ScriptDir . "\lib\dll_32\" : A_ScriptDir . "\lib\dll_64\"
            lib_path := A_ScriptDir . "\lib"
        }
        else
        {
            path := (A_PtrSize == 4) ? dir . "\dll_32\" : dir . "\dll_64\"
        }
        dllcall("SetDllDirectory", "Str", path)
        for k,v in this.LOG4AHK_G_MY_DLL_USE_MAP
        {
            for k1, v1 in v 
            {
                this.LOG4AHK_G_MY_DLL_USE_MAP[k][k1] := DllCall("GetProcAddress", "Ptr", DllCall("LoadLibrary", "Str", k, "Ptr"), "AStr", k1, "Ptr")
            }
        }
        this.is_dll_load := true
        if(this.is_use_cmder && this.is_out_console)
        {
            this.attach_cmder(lib_path)
        }
        DllCall("SetConsoleTitle", "Str", A_ScriptName)
        dllcall("SetDllDirectory", "Str", A_ScriptDir)
        this.set_pattern(this.default_patter)
    }
    ;https://github.com/gabime/spdlog/wiki/3.-Custom-formatting
    ;[%Y-%m-%d %H:%M:%S.%F] [thread %=7t] [%=8l] %^%v%$   (%ius)
    static set_pattern(pattern)
    {
        buf := this.strbuf(pattern,"utf-8")
        DllCall(this.LOG4AHK_G_MY_DLL_USE_MAP["cpp2ahk.dll"]["log_set_format"], "ptr", buf)
    }
    static attach_cmder(condum_path)
    {
        app_pid := DllCall("GetCurrentProcessId")
        condum_path := condum_path . "\cmder\vendor\conemu-maximus5\ConEmu\ConEmuC.exe"
        if(FileExist(condum_path))
        {
            DllCall(this.LOG4AHK_G_MY_DLL_USE_MAP["cpp2ahk.dll"]["set_console_transparency"], "Int", 0, "cdecl int")
            console4log.show_console()
            Run(condum_path " /ATTACH /CONPID=" app_pid)
        }
    }
    static __new()
    {
        this.level := this.level_trace
        this.log4ahk_load_all_dll_path()
    }
    static __delete()
    {
        ;DllCall("FreeConsole")
    }

    static GetStdoutObject() 
    {
        x := FileOpen(DllCall("GetStdHandle", "int", -11, "ptr"), "h `n")
        return x
    }
    static GetStdinObject() 
    {
        x := FileOpen(DllCall("GetStdHandle", "int", -10, "ptr"), "h `n")
        return x
    }
    ;刷新
    static FlushInput() 
    {
        x:=DllCall("FlushConsoleInputBuffer", 'uint', this.stdin.Handle)
        return x
    }
    ;获取值
    static Gets(&str :="") 
    {
        if(this.is_dll_load == false)
        {
            this.log4ahk_load_all_dll_path()
        }
        this.Stdin := this.getStdinObject()
        this.flushInput()
        BufferSize:=8192 ;65536 bytes is the maximum
        charsRead:=0
        Ptr := (A_PtrSize) ? "uptr" : "uint"
        str := Buffer(BufferSize, 0)
        e:=DllCall("ReadConsoleW"
                ,Ptr,this.stdin.Handle
                ,Ptr, str
                ,"UInt",BufferSize
                ,Ptr "*",&charsRead
                ,Ptr,0
                ,'UInt')
        
        if (e) and (!charsRead)
            return ""
        msg := "" 
        Loop(charsRead)
            msg .= Chr(NumGet(str, (A_Index-1) * (2), "ushort"))
        msg := StrSplit(msg,'`r`n')
        str := msg[1]
        this.flushInput()
        return str
    }
    ;格式化输出
	static Putsf(msg, vargs*) 
    {
		for each, varg in vargs
            msg := StrReplace(msg, '%s', varg)
		return this.puts(msg)
	}
    ;带回车的输出
    static Puts(str*) 
    {
        if(this.is_dll_load == false)
        {
            this.log4ahk_load_all_dll_path()
        }
        this.Stdout := this.getStdoutObject()
        for k,v in str
        {
            string .= this.log4ahk_to_str(v)
        }
        r:=this.print(string . "`n")
        this.Stdout.Read(0)
        return r
    }
    ;格式化不带回车输出
	static Printf(msg, vargs*) 
    {
		for each, varg in vargs
            msg := StrSplit(msg, '%s', varg)
		return this.print(msg)
	}
    ;不带回车的输出
    static Print(str*)
    {
        ;local
        if(this.is_dll_load == false)
        {
            this.log4ahk_load_all_dll_path()
        }
        this.Stdout := this.getStdoutObject()

        for k,v in str
        {
            string .= this.log4ahk_to_str(v)
        }
        if (!StrLen(string))
            return 1
        Written := 0
        e:=DllCall("WriteConsoleW"
                , "UPtr", this.Stdout.Handle
                , "Str", string
                , "UInt", strlen(string)
                , "UInt*", &Written
                , "uint", 0)
        this.Stdout.Read(0)
        return e
    }


    static log_out(para*)
    {
        if(this.is_dll_load == false)
        {
            this.log4ahk_load_all_dll_path()
        }
        if(this.is_log_open == false || (this.is_out_console == false && this.is_out_file == false))
        {
            return
        }
        if(this.is_out_console == true && this.console_create_flag == false)
        {
            this.console_create_flag := true
        }
        if(!this.is_use_editor && this.is_out_console && !this.is_console_config)
        {
            DllCall("AllocConsole")
            DllCall("SetConsoleOutputCP", "int", 65001)
            consoleHandle := DllCall("CreateFile", "str", "CONOUT$","int", 0x80000000 | 0x40000000, "int", 0x00000002, "int", 0, "int", 3, "int",  0, "int", 0)
            DllCall("SetStdHandle", "int", -11, "Ptr", consoleHandle)
            bk := CallbackCreate(console_close_callback)
            DllCall("SetConsoleCtrlHandler", "Ptr", bk, "Int", 1)
            console_close_callback(dwCtrlType)
            {

                DllCall("FreeConsole")
                return true
            }
            this.is_console_config := true
        }
        if(A_IsCompiled)
        {
            this.line := false
        }
        file_info := ""
        line_info := ""
        func_info := ""
        if(this.is_extern_info)
        {
            if(this.line || this.file)
            {
                err_obj := error("", -2)
                SplitPath(err_obj.file, &file_info)
                line_info := err_obj.line
            }
            if(this.func)
            {
                err_obj_up := error("", -3)
                func_info := err_obj_up.what
            }
            if(this.is_formate)
            {
                file_info := this.file ? "[" StrReplace(Format("{:-15}",substr(file_info, 1, 15)), A_Space, ".") "] " : ""
                line_info := this.line ? "[" Format("{:04}", substr(line_info, 1, 4)) "] " : ""
                func_info := this.func ? "[" StrReplace(Format("{:-15}", substr(func_info, 1, 15)), A_Space, ".") "] " : ""
            }
            else
            {
                file_info := this.file ? "[" file_info "] " : ""
                line_info := this.line ? "[" line_info "] " : ""
                func_info := this.func ? "[" func_info "] " : ""
            }
        }
        log_str := ""
        for k,v in para
        {
            log_str .= this.log4ahk_to_str(v) . " "
        }
        log_str := file_info func_info line_info "| " this.log_strim log_str
        buf := this.strbuf(log_str,"utf-8")
        result := DllCall(this.LOG4AHK_G_MY_DLL_USE_MAP["cpp2ahk.dll"]["log_simple"], "ptr", buf, "int", this.log_mode, "int", this.is_out_file, "int", this.is_out_console, "cdecl int")

        if(result != 0)
        {
            msgbox("dll call error!")
        }

    }
    static trace(para*)
    {
        if(this.level > this.level_trace)
            Return
        this.log_strim := ""
        this.log_mode := 1
        this.log_out(para*)
    }
    static debug(para*)
    {
        if(this.level > this.level_debug)
            Return
        this.log_strim := ""
        this.log_mode := 2
        this.log_out(para*)
    }
    static info(para*)
    {
        if(this.level > this.level_info)
            Return
        this.log_strim := ""
        this.log_mode := 3
        this.log_out(para*)
    }
    static warn(para*)
    {
        if(this.level > this.level_warn)
            Return
        this.log_strim := ""
        this.log_mode := 4
        this.log_out(para*)
    }
    static err(para*)
    {
        if(this.level > this.level_error)
            Return
        if(this.level > this.level_info)
            Return
        this.log_strim := ""
        this.log_mode := 5
        this.log_out(para*)
    }
    static critical(para *)
    {
        if(this.level > this.level_critical)
            Return
        this.log_strim := ""
        this.log_mode := 6
        this.log_out(para*)
    }
    static get_trim_position()
    {
        this.log_mode := 1
        stack_position := 0
        index_position := 0
        while(1)
        {
            stack_position++
            func_stack := Error("", index_position--)
            if(RegExMatch(func_stack.what, "^-[0-9]+$"))
            {
                break
            }
            if(stack_position > 20)
            {
                break
            }
        }
        return stack_position
    }
    static in(para *)
    {
        stack_position := this.get_trim_position()
        loop(stack_position - 3)
        {
            strim .= ">"
        }
        this.log_strim := strim
        this.log_out(para*)
    }
    static out(para*)
    {
        stack_position := this.get_trim_position()
        loop(stack_position - 3)
        {
            strim .= "<"
        }
        this.log_strim := strim
        this.log_out(para*)
    }
    static log4ahk_to_str(str)
    {
        rtn := ""
        if(isobject(str))
        {
            rtn := Log4ahk_json.stringify(str)
            rtn := strreplace(rtn, "`n")
            rtn := strreplace(rtn, " ")
        }
        else
        {
            try rtn := string(str)
        }
        return rtn
    }
    static strbuf(str, encoding)
    {
        buf := buffer(strput(str, encoding))
        strput(str, buf, encoding)
        return buf
    }
}
swtich_console(*)
{
    console4log.switch_console()
}
class console4log
{
    static switch_console()
    {
        if(this.IsConsoleVisible())
        {
            this.hide_console()
        }
        else
        {
            this.show_console()
        }
    }
    static get_console_hwnd()
    {
        ConsoleHWnd := DllCall("GetConsoleWindow")
        return ConsoleHWnd
    }
    static hide_console()
    {
        DllCall("ShowWindow","Int",this.get_console_hwnd(), "Int", 0)
    }
    static show_console()
    {
        DllCall("ShowWindow","Int",this.get_console_hwnd(), "Int", 5)
    }
    static IsConsoleVisible()
    {
        return DllCall("IsWindowVisible","Int", this.get_console_hwnd())
    }
}
;my thqby
class Log4ahk_json{
	static null := ComValue(1, 0), true := ComValue(0xB, 1), false := ComValue(0xB, 0)
	/**
	 * Converts a AutoHotkey Object Notation JSON string into an object.
	 * @param text A valid JSON string.
	 * @param keepbooltype convert true/false/null to JSON.true / JSON.false / JSON.null where it's true, otherwise 1 / 0 / ''
	 */
	static parse(text, keepbooltype := false) {
		keepbooltype ? (_true := this.true, _false := this.false, _null := this.null) : (_true := true, _false := false, _null := "")
		NQ := "", LF := "", LP := 0, P := "", R := ""
		D := [C := (A := InStr(text := LTrim(text, " `t`r`n"), "[") = 1) ? [] : Map()], text := LTrim(SubStr(text, 2), " `t`r`n"), L := 1, N := 0, V := K := "", J := C, !(Q := InStr(text, '"') != 1) ? text := LTrim(text, '"') : ""
		Loop Parse text, '"' {
			Q := NQ ? 1 : !Q
			NQ := Q && (SubStr(A_LoopField, -3) = "\\\" || (SubStr(A_LoopField, -1) = "\" && SubStr(A_LoopField, -2) != "\\"))
			if !Q {
				if (t := Trim(A_LoopField, " `t`r`n")) = "," || (t = ":" && V := 1)
					continue
				else if t && (InStr("{[]},:", SubStr(t, 1, 1)) || RegExMatch(t, "^-?\d*(\.\d*)?\s*[,\]\}]")) {
					Loop Parse t {
						if N && N--
							continue
						if InStr("`n`r `t", A_LoopField)
							continue
						else if InStr("{[", A_LoopField) {
							if !A && !V
								throw Error("Malformed JSON - missing key.", 0, t)
							C := A_LoopField = "[" ? [] : Map(), A ? D[L].Push(C) : D[L][K] := C, D.Has(++L) ? D[L] := C : D.Push(C), V := "", A := Type(C) = "Array"
							continue
						} else if InStr("]}", A_LoopField) {
							if !A && V
								throw Error("Malformed JSON - missing value.", 0, t)
							else if L = 0
								throw Error("Malformed JSON - to many closing brackets.", 0, t)
							else C := --L = 0 ? "" : D[L], A := Type(C) = "Array"
						} else if !(InStr(" `t`r,", A_LoopField) || (A_LoopField = ":" && V := 1)) {
							if RegExMatch(SubStr(t, A_Index), "m)^(null|false|true|-?\d+\.?\d*)\s*[,}\]\r\n]", &R) && (N := R.Len(0) - 2, R := R.1, 1) {
								if A
									C.Push(R = "null" ? _null : R = "true" ? _true : R = "false" ? _false : IsNumber(R) ? R + 0 : R)
								else if V
									C[K] := R = "null" ? _null : R = "true" ? _true : R = "false" ? _false : IsNumber(R) ? R + 0 : R, K := V := ""
								else throw Error("Malformed JSON - missing key.", 0, t)
							} else
								throw Error("Malformed JSON - unrecognized character-", 0, A_LoopField " in " t)
						}
					}
				} else if InStr(t, ':') > 1
					throw Error("Malformed JSON - unrecognized character-", 0, SubStr(t, 1, 1) " in " t)
			} else if NQ && (P .= A_LoopField '"', 1)
				continue
			else if A
				LF := P A_LoopField, C.Push(InStr(LF, "\") ? UC(LF) : LF), P := ""
			else if V
				LF := P A_LoopField, C[K] := InStr(LF, "\") ? UC(LF) : LF, K := V := P := ""
			else
				LF := P A_LoopField, K := InStr(LF, "\") ? UC(LF) : LF, P := ""
		}
		return J
		UC(S, e := 1) {
			static m := Map(Ord('"'), '"', Ord("a"), "`a", Ord("b"), "`b", Ord("t"), "`t", Ord("n"), "`n", Ord("v"), "`v", Ord("f"), "`f", Ord("r"), "`r", Ord("e"), Chr(0x1B), Ord("N"), Chr(0x85), Ord("P"), Chr(0x2029), 0, "", Ord("L"), Chr(0x2028), Ord("_"), Chr(0xA0))
			v := ""
			Loop Parse S, "\"
				if !((e := !e) && A_LoopField = "" ? v .= "\" : !e ? (v .= A_LoopField, 1) : 0)
					v .= (t := InStr("ux", SubStr(A_LoopField, 1, 1)) ? SubStr(A_LoopField, 1, RegExMatch(A_LoopField, "^[ux]?([\dA-F]{4})?([\dA-F]{2})?\K") - 1) : "") && RegexMatch(t, "i)^[ux][\da-f]+$") ? Chr(Abs("0x" SubStr(t, 2))) SubStr(A_LoopField, RegExMatch(A_LoopField, "^[ux]?([\dA-F]{4})?([\dA-F]{2})?\K")) : m.has(Ord(A_LoopField)) ? m[Ord(A_LoopField)] SubStr(A_LoopField, 2) : "\" A_LoopField, e := A_LoopField = "" ? e : !e
			return v
		}
	}

	/**
	 * Converts a AutoHotkey Array/Map/Object to a Object Notation JSON string.
	 * @param obj A AutoHotkey value, usually an object or array or map, to be converted.
	 * @param expandlevel The level of JSON string need to expand, by default expand all.
	 * @param space Adds indentation, white space, and line break characters to the return-value JSON text to make it easier to read.
	 * @param unicode_escaped Convert non-ascii characters to \uxxxx where unicode_escaped = true
	 */
	static stringify(obj, expandlevel := unset, space := "  ", unicode_escaped := false) {
		expandlevel := IsSet(expandlevel) ? Abs(expandlevel) : 10000000
		return Trim(CO(obj, expandlevel))
		CO(O, J := 0, R := 0, Q := 0) {
			static M1 := "{", M2 := "}", S1 := "[", S2 := "]", N := "`n", C := ",", S := "- ", E := "", K := ":"
			if (OT := Type(O)) = "Array" {
				D := !R ? S1 : ""
				for key, value in O {
					F := (VT := Type(value)) = "Array" ? "S" : InStr("Map,Object", VT) ? "M" : E
					Z := VT = "Array" && value.Length = 0 ? "[]" : ((VT = "Map" && value.count = 0) || (VT = "Object" && ObjOwnPropCount(value) = 0)) ? "{}" : ""
					D .= (J > R ? "`n" CL(R + 2) : "") (F ? (%F%1 (Z ? "" : CO(value, J, R + 1, F)) %F%2) : ES(value, J, unicode_escaped)) (OT = "Array" && O.Length = A_Index ? E : C)
				}
			} else {
				D := !R ? M1 : ""
				for key, value in (OT := Type(O)) = "Map" ? (Y := 1, O) : (Y := 0, O.OwnProps()) {
					F := (VT := Type(value)) = "Array" ? "S" : InStr("Map,Object", VT) ? "M" : E
					Z := VT = "Array" && value.Length = 0 ? "[]" : ((VT = "Map" && value.count = 0) || (VT = "Object" && ObjOwnPropCount(value) = 0)) ? "{}" : ""
					D .= (J > R ? "`n" CL(R + 2) : "") (Q = "S" && A_Index = 1 ? M1 : E) ES(key, J, unicode_escaped) K (F ? (%F%1 (Z ? "" : CO(value, J, R + 1, F)) %F%2) : ES(value, J, unicode_escaped)) (Q = "S" && A_Index = (Y ? O.count : ObjOwnPropCount(O)) ? M2 : E) (J != 0 || R ? (A_Index = (Y ? O.count : ObjOwnPropCount(O)) ? E : C) : E)
					if J = 0 && !R
						D .= (A_Index < (Y ? O.count : ObjOwnPropCount(O)) ? C : E)
				}
			}
			if J > R
				D .= "`n" CL(R + 1)
			if R = 0
				D := RegExReplace(D, "^\R+") (OT = "Array" ? S2 : M2)
			return D
		}
		ES(S, J := 1, U := false) {
			static ascii := Map("\", "\", "`a", "a", "`b", "b", "`t", "t", "`n", "n", "`v", "v", "`f", "f", "`r", "r", Chr(0x1B), "e", "`"", "`"", Chr(0x85), "N", Chr(0x2029), "P", Chr(0x2028), "L", "", "0", Chr(0xA0), "_")
			switch Type(S) {
				case "Float":
					if (v := '', d := InStr(S, 'e'))
						v := SubStr(S, d), S := SubStr(S, 1, d - 1)
					if ((StrLen(S) > 17) && (d := RegExMatch(S, "(99999+|00000+)\d{0,3}$")))
						S := Round(S, Max(1, d - InStr(S, ".") - 1))
					return S v
				case "Integer":
					return S
				case "String":
					v := ""
					if (U && RegExMatch(S, "m)[\x{7F}-\x{7FFF}]")) {
						Loop Parse S
							v .= ascii.Has(A_LoopField) ? "\" ascii[A_LoopField] : Ord(A_LoopField) < 128 ? A_LoopField : "\u" format("{1:.4X}", Ord(A_LoopField))
						return '"' v '"'
					} else {
						Loop Parse S
							v .= ascii.Has(A_LoopField) ? "\" ascii[A_LoopField] : A_LoopField
						return '"' v '"'
					}
				default:
					return S == this.true ? "true" : S == this.false ? "false" : "null"
			}
		}
		CL(i) {
			Loop (s := "", i - 1)
				s .= space
			return s
		}
	}
}