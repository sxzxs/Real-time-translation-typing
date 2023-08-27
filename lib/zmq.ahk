;zmq bind for ahkv2
zmq_errno() => DllCall(zmqdll_func['zmq_errno'])
zmq_version(&major, &minor, &patch) => DllCall(zmqdll_func['zmq_version'], 'int*', &major, 'int*', &minor, 'int*', patch)
zmq_ctx_new() => DllCall(zmqdll_func['zmq_ctx_new'], 'ptr')
zmq_ctx_term(context) => DllCall(zmqdll_func['zmq_ctx_term'], 'ptr', context, "int")
zmq_ctx_shutdown(context) => DllCall(zmqdll_func['zmq_ctx_shutdown'], 'ptr', context, "int")
zmq_socket(context, type) => DllCall(zmqdll_func['zmq_socket'], 'ptr', context, "int", type, "ptr")
zmq_bind(socket, endpoint) => DllCall(zmqdll_func['zmq_bind'], "Ptr", socket, "AStr", endpoint, "Int")
zmq_unbind(socket, endpoint) => DllCall(zmqdll_func['zmq_unbind'], "Ptr", socket, "AStr", endpoint, "Int")
zmq_connect(socket, endpoint) => DllCall(zmqdll_func['zmq_connect'], "Ptr", socket, "AStr", endpoint, "Int")
zmq_disconnect(socket, endpoint) => DllCall(zmqdll_func['zmq_disconnect'], "Ptr", socket, "AStr", endpoint, "Int")
zmq_close(socket) => DllCall(zmqdll_func['zmq_close'], "Ptr", socket, "Int")
;https://www.cnblogs.com/fengbohello/p/4398953.html
zmq_setsockopt(socket, option_name, option := Buffer(4), len := 4) => DllCall(zmqdll_func['zmq_setsockopt'], "Ptr", socket, "int", option_name, "ptr", option, "int", len, "Int")
zmq_recv(socket, address, recv_size, flags := 0) => DllCall(zmqdll_func['zmq_recv'], "Ptr", socket, "ptr", address, "uptr", recv_size, "int", flags, "Int")
zmq_send(socket, address, send_size, flags := 0) => DllCall(zmqdll_func['zmq_send'], "Ptr", socket, "ptr", address, "uptr", send_size, "int", flags, "Int")
zmq_msg_init(message) => DllCall(zmqdll_func['zmq_msg_init'], "Ptr", message, "Int")
zmq_msg_size(message) => DllCall(zmqdll_func['zmq_msg_size'], "Ptr", message, "uptr")
zmq_msg_data(message) => DllCall(zmqdll_func['zmq_msg_data'], "Ptr", message, "ptr")
zmq_msg_init_size(message, size) => DllCall(zmqdll_func['zmq_msg_init_size'], "Ptr", message, "uptr", size, "int")
zmq_msg_close(message) => DllCall(zmqdll_func['zmq_msg_close'], "Ptr", message, "int")
zmq_msg_send(message, socket, flags) => DllCall(zmqdll_func['zmq_msg_send'], "Ptr", message, "ptr", socket, "int", flags, "int")
zmq_msg_recv(message, socket, flags) => DllCall(zmqdll_func['zmq_msg_recv'], "Ptr", message, "ptr", socket, "int", flags, "int")
zmq_msg_more(message) => DllCall(zmqdll_func['zmq_msg_more'], "Ptr", message, "int")
zmq_memcpy(dest, src, count) => DllCall(memcpy, "Ptr", dest, "ptr", src, "UPtr", count, "ptr")

;ZMQ_EXPORT int zmq_poll (zmq_pollitem_t *items_, int nitems_, long timeout_);
zmq_poll(items := array(map("socket", 0, "fd", 0, "events", 0, "revents", 0)), time_out := -1)
{
    x64 := (A_PtrSize == 8)
    buf := buffer(items.Length * (x64 ? 24 : 12))
    for k, v in  items
    {
        offset := (x64 ? 24 : 12) * (k - 1)
        NumPut("ptr", v['socket'], buf, offset)
        NumPut("ptr", v['fd'], buf, (x64 ? 8 : 4) + offset)
        NumPut("short", v['events'], buf, (x64 ? 16 : 8) + offset)
        NumPut("short", v['revents'], buf, (x64 ? 18 : 10) + offset)
    }
    DllCall(zmqdll_func['zmq_poll'], "Ptr", buf, "Int", items.Length, "Int", time_out, "Int")
    revents := []
    for k, v in items
    {
        offset := (x64 ? 24 : 12) * (k - 1)
        revents.Push(NumGet(buf, (x64 ? 18 : 10) + offset, "short"))
    }
    return revents
}

/**
 * 
 * @param {any} socket 
 * @param {any} str 
 * @param {string} encoding 
 * @param {number} mode 
 */
zmq_send_string(socket, str, encoding := "UTF-8", mode := 0)
{
    buf := Buffer(StrPut(str, encoding))
    StrPut(str, buf, encoding)
    rtn := zmq_send(socket, buf, buf.Size, mode)
}

/**
 * zmq接收字符串消息
 * @param {any} socket 
 * @param {varref} recv_str 
 * @param {string} encoding 
 * @param {number} mode 设置 ZMQ_DONTWAIT 非阻塞，立即返回-1, 并设置Errors为EAGAIN
 * @param {number} buf_size 
 * @returns {void} 接收到的字节,如果失败返回-1
 */
zmq_recv_string(socket, &recv_str := '', mode := 0, encoding := "UTF-8", buf_size := 1024000)
{
    buf := Buffer(buf_size, 0)
    rtn := zmq_recv(socket, buf, buf_size, mode)
    if(rtn != -1)
        recv_str := StrGet(buf, rtn, encoding)
    return rtn
}

zmq_msg_send_bin(socket, bin, mode := 0)
{
    message := Buffer(64, 0)
    zmq_msg_init_size(message, bin.Size)
    zmq_memcpy(zmq_msg_data(message), bin, bin.Size)
    rc := zmq_msg_send(message, socket, mode)
    zmq_msg_close(message)
    return rc
}

zmq_msg_recv_bin(socket, &recv_bin := Buffer(), mode := 0)
{
    message := Buffer(64, 0)
    zmq_msg_init(message)
    rtn := zmq_msg_recv(message, socket, mode)
    size := zmq_msg_size(message)
    buf := Buffer(size, 0)
    zmq_memcpy(buf, zmq_msg_data(message), size)
    recv_bin := buf
    return rtn
}

zmq_msg_send_string(socket, str, encoding := 'UTF-8', mode := 0)
{
    message := Buffer(64, 0)
    zmq_msg_init_size(message, StrPut(str, encoding))
    StrPut(str, zmq_msg_data(message), encoding)
    rc := zmq_msg_send(message, socket, mode)
    zmq_msg_close(message)
    return rc
}

zmq_msg_recv_string(socket, &recv_str := '', mode := 0, encoding := 'UTF-8')
{
    message := Buffer(64, 0)
    zmq_msg_init(message)
    rtn := zmq_msg_recv(message, socket, mode)
    size := zmq_msg_size(message)
    recv_str := StrGet(zmq_msg_data(message), size + 1, encoding)
    zmq_msg_close(message)
    return rtn
}

class zmq_constant
{
    static __New()
    {
        ;Context options                
        global ZMQ_IO_THREADS := 1
        global ZMQ_MAX_SOCKETS := 2
        global ZMQ_SOCKET_LIMIT := 3
        global ZMQ_THREAD_PRIORITY := 3
        global ZMQ_THREAD_SCHED_POLICY := 4
        global ZMQ_MAX_MSGSZ := 5
        global ZMQ_MSG_T_SIZE := 6
        global ZMQ_THREAD_AFFINITY_CPU_ADD := 7
        global ZMQ_THREAD_AFFINITY_CPU_REMOVE := 8
        global ZMQ_THREAD_NAME_PREFIX := 9

        ;Default for new contexts
        global ZMQ_IO_THREADS_DFLT := 1
        global ZMQ_MAX_SOCKETS_DFLT := 1023
        global ZMQ_THREAD_PRIORITY_DFLT := -1
        global ZMQ_THREAD_SCHED_POLICY_DFLT := -1

        ;0MQ socket definition. 
        ;Socket types
        global ZMQ_PAIR :=  0
        global ZMQ_PUB :=  1
        global ZMQ_SUB :=  2
        global ZMQ_REQ := 3
        global ZMQ_REP := 4
        global ZMQ_DEALER := 5
        global ZMQ_ROUTER := 6
        global ZMQ_PULL := 7
        global ZMQ_PUSH := 8
        global ZMQ_XPUB := 9
        global ZMQ_XSUB := 10
        global ZMQ_STREAM := 11

        ;Deprecated aliases
        global ZMQ_XREQ := ZMQ_DEALER
        global ZMQ_XREP := ZMQ_ROUTER

        ;Socket options
        global ZMQ_AFFINITY := 4
        global ZMQ_ROUTING_ID := 5
        global ZMQ_SUBSCRIBE := 6
        global ZMQ_UNSUBSCRIBE := 7
        global ZMQ_RATE := 8
        global ZMQ_RECOVERY_IVL := 9
        global ZMQ_SNDBUF := 11
        global ZMQ_RCVBUF := 12
        global ZMQ_RCVMORE := 13
        global ZMQ_FD := 14
        global ZMQ_EVENTS := 15
        global ZMQ_TYPE := 16
        global ZMQ_LINGER := 17
        global ZMQ_RECONNECT_IVL := 18
        global ZMQ_BACKLOG := 19
        global ZMQ_RECONNECT_IVL_MAX := 21
        global ZMQ_MAXMSGSIZE := 22
        global ZMQ_SNDHWM := 23
        global ZMQ_RCVHWM := 24
        global ZMQ_MULTICAST_HOPS := 25
        global ZMQ_RCVTIMEO := 27
        global ZMQ_SNDTIMEO := 28
        global ZMQ_LAST_ENDPOINT := 32
        global ZMQ_ROUTER_MANDATORY := 33
        global ZMQ_TCP_KEEPALIVE := 34
        global ZMQ_TCP_KEEPALIVE_CNT := 35
        global ZMQ_TCP_KEEPALIVE_IDLE := 36
        global ZMQ_TCP_KEEPALIVE_INTVL := 37
        global ZMQ_IMMEDIATE := 39
        global ZMQ_XPUB_VERBOSE := 40
        global ZMQ_ROUTER_RAW := 41
        global ZMQ_IPV6 := 42
        global ZMQ_MECHANISM := 43
        global ZMQ_PLAIN_SERVER := 44
        global ZMQ_PLAIN_USERNAME := 45
        global ZMQ_PLAIN_PASSWORD := 46
        global ZMQ_CURVE_SERVER := 47
        global ZMQ_CURVE_PUBLICKEY := 48
        global ZMQ_CURVE_SECRETKEY := 49
        global ZMQ_CURVE_SERVERKEY := 50
        global ZMQ_PROBE_ROUTER := 51
        global ZMQ_REQ_CORRELATE := 52
        global ZMQ_REQ_RELAXED := 53
        global ZMQ_CONFLATE := 54
        global ZMQ_ZAP_DOMAIN := 55
        global ZMQ_ROUTER_HANDOVER := 56
        global ZMQ_TOS := 57
        global ZMQ_CONNECT_ROUTING_ID := 61
        global ZMQ_GSSAPI_SERVER := 62
        global ZMQ_GSSAPI_PRINCIPAL := 63
        global ZMQ_GSSAPI_SERVICE_PRINCIPAL := 64
        global ZMQ_GSSAPI_PLAINTEXT := 65
        global ZMQ_HANDSHAKE_IVL := 66
        global ZMQ_SOCKS_PROXY := 68
        global ZMQ_XPUB_NODROP := 69
        global ZMQ_BLOCKY := 70
        global ZMQ_XPUB_MANUAL := 71
        global ZMQ_XPUB_WELCOME_MSG := 72
        global ZMQ_STREAM_NOTIFY := 73
        global ZMQ_INVERT_MATCHING := 74
        global ZMQ_HEARTBEAT_IVL := 75
        global ZMQ_HEARTBEAT_TTL := 76
        global ZMQ_HEARTBEAT_TIMEOUT := 77
        global ZMQ_XPUB_VERBOSER := 78
        global ZMQ_CONNECT_TIMEOUT := 79
        global ZMQ_TCP_MAXRT := 80
        global ZMQ_THREAD_SAFE := 81
        global ZMQ_MULTICAST_MAXTPDU := 84
        global ZMQ_VMCI_BUFFER_SIZE := 85
        global ZMQ_VMCI_BUFFER_MIN_SIZE := 86
        global ZMQ_VMCI_BUFFER_MAX_SIZE := 87
        global ZMQ_VMCI_CONNECT_TIMEOUT := 88
        global ZMQ_USE_FD := 89
        global ZMQ_GSSAPI_PRINCIPAL_NAMETYPE := 90
        global ZMQ_GSSAPI_SERVICE_PRINCIPAL_NAMETYPE := 91
        global ZMQ_BINDTODEVICE := 92

        ;Message options
        global ZMQ_MORE := 1
        global ZMQ_SHARED := 3

        ;Send/recv options
        global ZMQ_DONTWAIT := 1
        global ZMQ_SNDMORE := 2

        ;Security mechanisms
        global ZMQ_NULL := 0
        global ZMQ_PLAIN := 1
        global ZMQ_CURVE := 2
        global ZMQ_GSSAPI := 3

        ;RADIO-DISH protocol
        global ZMQ_GROUP_MAX_LENGTH := 255

        ;Deprecated options and aliases
        global ZMQ_IDENTITY := ZMQ_ROUTING_ID
        global ZMQ_CONNECT_RID := ZMQ_CONNECT_ROUTING_ID
        global ZMQ_TCP_ACCEPT_FILTER := 38
        global ZMQ_IPC_FILTER_PID := 58
        global ZMQ_IPC_FILTER_UID := 59
        global ZMQ_IPC_FILTER_GID := 60
        global ZMQ_IPV4ONLY := 31
        global ZMQ_DELAY_ATTACH_ON_CONNECT := ZMQ_IMMEDIATE
        global ZMQ_NOBLOCK := ZMQ_DONTWAIT
        global ZMQ_FAIL_UNROUTABLE := ZMQ_ROUTER_MANDATORY
        global ZMQ_ROUTER_BEHAVIOR := ZMQ_ROUTER_MANDATORY

        ;Deprecated Message options
        global ZMQ_SRCFD := 2

        ; GSSAPI definitions
        ;GSSAPI principal name types
        global ZMQ_GSSAPI_NT_HOSTBASED := 0
        global ZMQ_GSSAPI_NT_USER_NAME := 1
        global ZMQ_GSSAPI_NT_KRB5_PRINCIPAL := 2

        ;0MQ socket events and monitoring
        ;Socket transport events (TCP, IPC and TIPC only)
        global ZMQ_EVENT_CONNECTED := 0x0001
        global ZMQ_EVENT_CONNECT_DELAYED := 0x0002
        global ZMQ_EVENT_CONNECT_RETRIED := 0x0004
        global ZMQ_EVENT_LISTENING := 0x0008
        global ZMQ_EVENT_BIND_FAILED := 0x0010
        global ZMQ_EVENT_ACCEPTED := 0x0020
        global ZMQ_EVENT_ACCEPT_FAILED := 0x0040
        global ZMQ_EVENT_CLOSED := 0x0080
        global ZMQ_EVENT_CLOSE_FAILED := 0x0100
        global ZMQ_EVENT_DISCONNECTED := 0x0200
        global ZMQ_EVENT_MONITOR_STOPPED := 0x0400
        global ZMQ_EVENT_ALL := 0xFFFF
        ;Unspecified system errors during handshake. Event value is an errno
        global ZMQ_EVENT_HANDSHAKE_FAILED_NO_DETAIL := 0x0800
        ;Handshake complete successfully with successful authentication (if enabled). Event value is unused
        global ZMQ_EVENT_HANDSHAKE_SUCCEEDED := 0x1000
        ;Protocol errors between ZMTP peers or between server and ZAP handler. Event value is one of ZMQ_PROTOCOL_ERROR_
        global ZMQ_EVENT_HANDSHAKE_FAILED_PROTOCOL := 0x2000
        ;Failed authentication requests. Event value is the numeric ZAP status  code, i.e. 300, 400 or 500
        global ZMQ_EVENT_HANDSHAKE_FAILED_AUTH := 0x4000
        global ZMQ_PROTOCOL_ERROR_ZMTP_UNSPECIFIED := 0x10000000
        global ZMQ_PROTOCOL_ERROR_ZMTP_UNEXPECTED_COMMAND := 0x10000001
        global ZMQ_PROTOCOL_ERROR_ZMTP_INVALID_SEQUENCE := 0x10000002
        global ZMQ_PROTOCOL_ERROR_ZMTP_KEY_EXCHANGE := 0x10000003
        global ZMQ_PROTOCOL_ERROR_ZMTP_MALFORMED_COMMAND_UNSPECIFIED := 0x10000011
        global ZMQ_PROTOCOL_ERROR_ZMTP_MALFORMED_COMMAND_MESSAGE := 0x10000012
        global ZMQ_PROTOCOL_ERROR_ZMTP_MALFORMED_COMMAND_HELLO := 0x10000013
        global ZMQ_PROTOCOL_ERROR_ZMTP_MALFORMED_COMMAND_INITIATE := 0x10000014
        global ZMQ_PROTOCOL_ERROR_ZMTP_MALFORMED_COMMAND_ERROR := 0x10000015
        global ZMQ_PROTOCOL_ERROR_ZMTP_MALFORMED_COMMAND_READY := 0x10000016
        global ZMQ_PROTOCOL_ERROR_ZMTP_MALFORMED_COMMAND_WELCOME := 0x10000017
        global ZMQ_PROTOCOL_ERROR_ZMTP_INVALID_METADATA := 0x10000018
        ;the following two may be due to erroneous configuration of a peer
        global ZMQ_PROTOCOL_ERROR_ZMTP_CRYPTOGRAPHIC := 0x11000001
        global ZMQ_PROTOCOL_ERROR_ZMTP_MECHANISM_MISMATCH := 0x11000002
        global ZMQ_PROTOCOL_ERROR_ZAP_UNSPECIFIED := 0x20000000
        global ZMQ_PROTOCOL_ERROR_ZAP_MALFORMED_REPLY := 0x20000001
        global ZMQ_PROTOCOL_ERROR_ZAP_BAD_REQUEST_ID := 0x20000002
        global ZMQ_PROTOCOL_ERROR_ZAP_BAD_VERSION := 0x20000003
        global ZMQ_PROTOCOL_ERROR_ZAP_INVALID_STATUS_CODE := 0x20000004
        global ZMQ_PROTOCOL_ERROR_ZAP_INVALID_METADATA := 0x20000005
        global ZMQ_PROTOCOL_ERROR_WS_UNSPECIFIED := 0x30000000

        global ZMQ_POLLIN := 1
        global ZMQ_POLLOUT := 2
        global ZMQ_POLLERR := 4
        global ZMQ_POLLPRI := 8

        global ZMQ_POLLITEMS_DFLT := 16
        global ZMQ_HAS_CAPABILITIES := 1

        ;Deprecated aliases
        global ZMQ_STREAMER := 1
        global ZMQ_FORWARDER := 2
        global ZMQ_QUEUE := 3
        ;load dll
        global zmqdll := 'libzmq-v141-mt-4_3_4.dll'
        global zmqdll_func := map("zmq_atomic_counter_dec", 0
               , "zmq_atomic_counter_destroy", 0
               , "zmq_atomic_counter_inc", 0
               , "zmq_atomic_counter_new", 0
               , "zmq_atomic_counter_set", 0
               , "zmq_atomic_counter_value", 0
               , "zmq_bind", 0                   ; *
               , "zmq_close", 0                  ; *
               , "zmq_connect" , 0               ; *
               , "zmq_ctx_destroy", 0            ; deprecate by zmq_ctx_term
               , "zmq_ctx_get", 0
               , "zmq_ctx_new", 0                ; *
               , "zmq_ctx_set", 0
               , "zmq_ctx_shutdown", 0           ; *
               , "zmq_ctx_term", 0               ; *
               , "zmq_curve_keypair", 0
               , "zmq_curve_public", 0
               ; , "zmq_curve"
               , "zmq_disconnect", 0             ; *
               , "zmq_errno", 0                  ; *
               , "zmq_getsockopt", 0
               ; , "zmq_gssapi"
               , "zmq_has", 0
               , "zmq_init", 0                   ; deprecate by zmq_ctx_new
               ; , "zmq_inproc"
               ; , "zmq_ipc"
               , "zmq_msg_close", 0              ; *
               , "zmq_msg_copy", 0
               , "zmq_msg_data", 0               ; *
               , "zmq_msg_gets", 0
               , "zmq_msg_get", 0
               , "zmq_msg_init_data", 0
               , "zmq_msg_init_size", 0
               , "zmq_msg_init", 0               ; *
               , "zmq_msg_more", 0               ; *
               , "zmq_msg_move", 0
               , "zmq_msg_recv", 0               ; *
               , "zmq_msg_routing_id", 0
               , "zmq_msg_send", 0
               , "zmq_msg_set_routing_id", 0
               , "zmq_msg_set", 0
               , "zmq_msg_size", 0
               ; , "zmq_null"
               ; , "zmq_pgm"
               ; , "zmq_plain"
               ; , "zmq_poller"
               , "zmq_poll", 0                   ; *
               , "zmq_proxy_steerable", 0
               , "zmq_proxy", 0                  ; *
               , "zmq_recvmsg", 0                ; deprecate by zmq_msg_recv
               , "zmq_recv", 0                   ; *
               , "zmq_send_const", 0
               , "zmq_sendmsg", 0                ; deprecate by zmq_msg_send
               , "zmq_send", 0                   ; *
               , "zmq_setsockopt", 0             ; *
               , "zmq_socket_monitor", 0
               , "zmq_socket", 0                 ; *
               , "zmq_strerror", 0               ; *
               ; , "zmq_tcp"
               , "zmq_term", 0                   ; deprecate by zmq_ctx_term
               ; , "zmq_timers"
               ; , "zmq_tipc"
               ; , "zmq_udp"
               , "zmq_unbind", 0                 ; *
               , "zmq_version", 0                ; *
               ; , "zmq_vmci"
               ,"zmq_errno", 0
               , "zmq_z85_decode", 0
               , "zmq_z85_encode", 0)
        SplitPath(A_LineFile,,&dir)
        if(A_IsCompiled)
            path := (A_PtrSize == 4) ? A_ScriptDir . "\lib\dll_32\" : A_ScriptDir . "\lib\dll_64\"
        else
            path := (A_PtrSize == 4) ? dir . "\dll_32\" : dir . "\dll_64\"
        dllcall("SetDllDirectory", "Str", path)
        for k,v in zmqdll_func
            zmqdll_func[k] := DllCall("GetProcAddress", "Ptr", DllCall("LoadLibrary", "Str", zmqdll, "Ptr"), "AStr", k, "Ptr")
        dllcall("SetDllDirectory", "Str", A_ScriptDir)
        global memcpy := DllCall("GetProcAddress", "Ptr", DllCall("LoadLibrary", "Str", "ntdll.dll", "Ptr"), "AStr", "memcpy", "Ptr")
    }
}