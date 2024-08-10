#Requires AutoHotkey v2.0

class Lcu
{
    __New()
    {
        ;https://127.0.0.1:2999/liveclientdata/activeplayer
        ;https://127.0.0.1:2999/liveclientdata/allgamedata
        this.local_port := 2999
        this.base_url := 'https://127.0.0.1:'
        if(!this.get_cmd_info())
            logger.err('获取状态失败，请先打开客户端，然后管理员模式运行!!!')

        this.normal_modes := 
        {
            0: "5V5 训练模式", ; 这是自定义的编号
            420: "排位赛 单排/双排",
            430: "匹配模式 自选",
            440: "排位赛 灵活排位",
            450: "极地大乱斗 嚎哭深渊",
            830: "人机 召唤师峡谷 入门",
            840: "人机 召唤师峡谷 新手",
            850: "人机 召唤师峡谷 一般",
            1090: "云顶之弈 匹配",
            1100: "云顶之弈 排位",
            2000: "新手教程 一",
            2010: "新手教程 二",
            2020: "新手教程 三"
        }

    }
    ;游戏状态字符串
    get_game_status_string(status)
    {
        mp := Map(
            "Error", '获取错误', 
            "None", '游戏大厅',
            "Lobby", '房间内',
            "Matchmaking", '匹配中',
            "ReadyCheck", '找到对局',
            "ChampSelect", '选英雄中',
            "InProgress", '游戏中',
            "PreEndOfGame", '游戏即将结束',
            "WaitingForStats", '等待结算页面',
            "EndOfGame", '游戏结束',
            "Reconnect", '等待重新连接'
        )
        if(mp.Has(status))
            return mp[status]
        else
            return 'Error'
    }

    ;获取命令参数
    get_cmd_info()
    {
        cmd_result := ReadProcessStdOut('cmd /c wmic PROCESS WHERE name="LeagueClientUx.exe" GET commandline')
        if(RegExMatch(cmd_result, '"--remoting-auth-token=(.*?)"', &sub_pt1)
            && RegExMatch(cmd_result, '"--app-port=(.*?)"', &sub_pt2)
            && RegExMatch(cmd_result, '"--app-pid=(.*?)"', &sub_pt3))
        {
            this.token := sub_pt1[1]
            this.port := sub_pt2[1]
            this.app_id := sub_pt3[1]
            this.auth  := StringToBase64("riot:" this.token)
        }
        else
            return false
        return true
    }
    ;创建房间
    create_room(que_id := 1090)
    {
        ;/lol-lobby/v2/lobby 作者：Marioㄹ https://www.bilibili.com/read/cv6477040/ 出处：bilibili
        rtn := this.request('POST', '/lol-lobby/v2/lobby',, JSON.stringify({queueId : que_id}))
        return rtn
    }
    ;获取房间
    get_room(&room)
    {
        room := ''
        rtn := this.request('GET', '/lol-lobby/v2/lobby', &text)
        if(rtn)
        {
            try
            {
                js := JSON.parse(text)
                if(js.Has('gameConfig') && js['gameConfig'].Has('queueId'))
                    room := js['gameConfig']['queueId']
            }
            catch as e
            {
                rtn := false
                logger.err(e.Message)
            }
        }
        return rtn
    }
    ;创建5v5房间
    create_room_5v5(lobbyName := "test_lobby", teamSize := 5)
    {
        post_obj := 
        {
            customGameLobby: 
            {
                configuration: 
                {
                    gameMode: "PRACTICETOOL",
                    gameMutator: "",
                    gameServerRegion: "",
                    mapId: 11,
                    mutators: 
                    {
                        id: 1
                    },
                    spectatorPolicy: "AllAllowed",
                    teamSize: teamSize
                },
                lobbyName: lobbyName,
                lobbyPassword: 'None'
            },
            isCustom: True
        }
        rtn := this.request('POST', '/lol-lobby/v2/lobby',, JSON.stringify(post_obj))
        return rtn
    }
    ;获取天赋
    gain_rune_talent(&talent)
    {
        rtn := this.request('GET', '/lol-perks/v1/currentpage', &text)
        if(rtn)
        {
            try
            {
                talent := JSON.parse(text)
            }
            catch as e
            {
                rtn := false
                logger.err(e.Message)
            }
        }
        return rtn
    }
    ;获取状态
    get_status(&status)
    {
        rtn := this.request('GET', '/lol-lobby/v2/lobby/matchmaking/search-state', &text)
        if(rtn)
        {
            try
            {
                js := JSON.parse(text)
                status := js['searchState']
            }
            catch as e
            {
                rtn := false
                logger.err(e.Message)
            }
        }
        return rtn
    }
    ;获取客户端状态,比如 游戏中,大厅中
    get_game_status(&status)
    {
        if(this.request('GET', '/lol-gameflow/v1/gameflow-phase', &status := ''))
        {
            if(RegExMatch(status, '"(.*)"', &sub_pt))
                status := sub_pt[1]
            else
                return false
        }
        else
            return false
        return true
    }
    ;接受对局
    accept_a_match()
    {
        rtn := this.request('POST', '/lol-matchmaking/v1/ready-check/accept')
        return rtn
    }
    ;自动开始下一句对局
    auto_next_game()
    {
        rtn := this.request('POST', '/lol-lobby/v2/play-again')
        return rtn
    }
    ;排队
    search_queue()
    {
        rtn := this.request('POST', '/lol-lobby/v2/lobby/matchmaking/search')
        return rtn
    }
    ;获取英雄名字和id
    get_hero_name_and_id(&hero_name, &hero_id)
    {
        rtn := this.request('GET', '/liveclientdata/activeplayer', &data,, this.local_port)
        rtn := this.request('GET', '/liveclientdata/allgamedata', &data,, this.local_port)
        if(rtn)
        {
            try
            {
                js := JSON.parse(data)
                hero_name := js['allPlayers'][1]['championName']
                hero_id := js['activePlayer']['summonerName']
            }
            catch as e
            {
                rtn := false
                logger.err(e.Message)
            }
        }
        return rtn
    }


    ;获取英雄信息
    get_hero_info(&attack_speed, &currentHealth, &maxHealth, &healthRegenRate)
    {
        rtn := this.request('GET', '/liveclientdata/activeplayer', &data,, this.local_port)
        if(rtn)
        {
            try
            {
                js := JSON.parse(data)
                attack_speed := js['championStats']['attackSpeed']
                currentHealth := js['championStats']['currentHealth']
                maxHealth := js['championStats']['maxHealth']
                healthRegenRate := js['championStats']['healthRegenRate']
            }
            catch as e
            {
                rtn := false
                logger.err(e.Message)
            }
        }
        return rtn
    }
    ;发送请求
    request(interface, api, &text := false, post_data := '',port := this.port)
    {
        rtn := true
        try
        {
            api := this.base_url port api
            whq := WinHttpRequest()
            whq.Option[4] := 13056
            whq.Open(interface, api, true)
            whq.SetRequestHeader('Content-Type', 'application/json')
            whq.SetRequestHeader('Accept', 'application/json')
            whq.SetRequestHeader('Authorization', 'Basic ' this.auth)
            whq.Send(post_data)
            whq.WaitForResponse()
            if(!IsSet(text) || (IsSet(text) && text != false))
            {
                body := whq.ResponseBody
                text := StrGet(body, 'UTF-8')
                logger.info('original:' text)
            }
        }
        catch as e
        {
            rtn := false
            logger.err(e)
        }
        return rtn
    }
}

StringToBase64(String, Encoding := "UTF-8")
{
	static CRYPT_STRING_BASE64 := 0x00000001
	static CRYPT_STRING_NOCRLF := 0x40000000

	Binary := Buffer(StrPut(String, Encoding))
	StrPut(String, Binary, Encoding)
	if !(DllCall("crypt32\CryptBinaryToStringW", "Ptr", Binary, "UInt", Binary.Size, "UInt", (CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF), "Ptr", 0, "UInt*", &Size := 0))
		throw Error("CryptBinaryToStringW failed", -1)

	Base64 := Buffer(Size << 1, 0)
	if !(DllCall("crypt32\CryptBinaryToStringW", "Ptr", Binary, "UInt", Binary.Size, "UInt", (CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF), "Ptr", Base64, "UInt*", Size))
		throw Error("CryptBinaryToStringW failed", -1)

	return StrGet(Base64)
}

ReadProcessStdOut(cmd, stdin := "", encoding := "cp0") {
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
        if !DllCall("WriteFile", "ptr", hWritePipeIn, "astr", stdin, "uint", StrPut(stdin, "cp0") - 1, "uint*", &lpNumberOfBytesWritten := 0, "ptr", 0){
            DllCall("CloseHandle", "ptr", hWritePipeIn)
            throw OSError()
        }
        DllCall("CloseHandle", "ptr", hWritePipeIn)
    }

    stdout := ""
    while DllCall("ReadFile", "ptr", hReadPipeOut, "ptr", buf := Buffer(4096), "uint", buf.Size, "uint*", &lpNumberOfBytesRead := 0, "ptr", 0) && lpNumberOfBytesRead
        stdout .= StrGet(buf, lpNumberOfBytesRead, encoding)
    DllCall("CloseHandle", "ptr", hReadPipeOut)

    return stdout
}