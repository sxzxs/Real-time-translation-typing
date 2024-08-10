/************************************************************************
 * @file: WinHttpRequest.ahk
 * @description: 网络请求库
 * @author thqby
 * @date 2021/08/01
 * @version 0.0.18
 ***********************************************************************/
#Requires AutoHotkey v2.0

class WinHttpRequest {
	static AutoLogonPolicy := {
		Always: 0,
		OnlyIfBypassProxy: 1,
		Never: 2
	}
	static Option := {
		UserAgentString: 0,
		URL: 1,
		URLCodePage: 2,
		EscapePercentInURL: 3,
		SslErrorIgnoreFlags: 4,
		SelectCertificate: 5,
		EnableRedirects: 6,
		UrlEscapeDisable: 7,
		UrlEscapeDisableQuery: 8,
		SecureProtocols: 9,
		EnableTracing: 10,
		RevertImpersonationOverSsl: 11,
		EnableHttpsToHttpRedirects: 12,
		EnablePassportAuthentication: 13,
		MaxAutomaticRedirects: 14,
		MaxResponseHeaderSize: 15,
		MaxResponseDrainSize: 16,
		EnableHttp1_1: 17,
		EnableCertificateRevocationCheck: 18,
		RejectUserpwd: 19
	}
	static PROXYSETTING := {
		PRECONFIG: 0,
		DIRECT: 1,
		PROXY: 2
	}
	static SETCREDENTIALSFLAG := {
		SERVER: 0,
		PROXY: 1
	}
	static SecureProtocol := {
		SSL2: 0x08,
		SSL3: 0x20,
		TLS1: 0x80,
		TLS1_1: 0x200,
		TLS1_2: 0x800,
		All: 0xA8
	}
	static SslErrorFlag := {
		UnknownCA: 0x0100,
		CertWrongUsage: 0x0200,
		CertCNInvalid: 0x1000,
		CertDateInvalid: 0x2000,
		Ignore_All: 0x3300
	}

	__New(UserAgent := unset) {
		(this.whr := ComObject('WinHttp.WinHttpRequest.5.1')).Option[0] := IsSet(UserAgent) ? UserAgent : 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.114 Safari/537.36 Edg/89.0.774.68'
	}

	request(url, method := 'GET', post_data?, headers := {}) {
		this.Open(method, url)
		for k, v in headers.OwnProps()
			this.SetRequestHeader(k, v)
		this.Send(post_data?)
		return this.ResponseText
	}
	enableRequestEvents(Enable := true) {
		static vtable := init_vtable()
		if !Enable
			return this._ievents := this._ref := 0
		if this._ievents
			return
		IConnectionPointContainer := ComObjQuery(pwhr := ComObjValue(this.whr), '{B196B284-BAB4-101A-B69C-00AA00341D07}')
		DllCall('ole32\CLSIDFromString', 'str', '{F97F4E15-B787-4212-80D1-D380CBBF982E}', 'ptr', IID_IWinHttpRequestEvents := Buffer(16))
		ComCall(4, IConnectionPointContainer, 'ptr', IID_IWinHttpRequestEvents, 'ptr*', IConnectionPoint := ComValue(0xd, 0))	; IConnectionPointContainer->FindConnectionPoint
		IWinHttpRequestEvents := Buffer(3 * A_PtrSize)
		NumPut('ptr', vtable.Ptr, 'ptr', ObjPtr(this), 'ptr', ObjPtr(IWinHttpRequestEvents), IWinHttpRequestEvents)
		ComCall(5, IConnectionPoint, 'ptr', IWinHttpRequestEvents, 'uint*', &dwCookie := 0)	; IConnectionPoint->Advise
		this._ievents := { __Delete: (*) => ComCall(6, IConnectionPoint, 'uint', dwCookie) }
		static init_vtable() {
			vtable := Buffer(A_PtrSize * 7), offset := vtable.Ptr
			for nParam in StrSplit('3113213')
				offset := NumPut('ptr', CallbackCreate(EventHandler.Bind(A_Index), , Integer(nParam)), offset)
			vtable.DefineProp('__Delete', { call: __Delete })
			return vtable
			static EventHandler(index, this, arg1 := 0, arg2 := 0) {
				if (index < 4) {
					IEvents := NumGet(this, A_PtrSize * 2, 'ptr')
					if index == 1
						NumPut('ptr', this, arg2)
					if index == 3
						ObjRelease(IEvents)
					else ObjAddRef(IEvents)
					return 0
				}
				req := ObjFromPtrAddRef(NumGet(this, A_PtrSize, 'ptr'))
				req.readyState := index - 2
				switch index {
					case 4:	; OnResponseStart
						try req.OnResponseStart(arg1, StrGet(arg2, 'utf-16'))
					case 5:	; OnResponseDataAvailable
						try req.OnResponseDataAvailable(
							NumGet((pSafeArray := NumGet(arg1, 'ptr')) + 8 + A_PtrSize, 'ptr'),
							NumGet(pSafeArray + 8 + A_PtrSize * 2, 'uint'))
					case 6:	; OnResponseFinished
						try req._ref := 0, req.OnResponseFinished()
					case 7:	; OnError
						try req.readyState := req._ref := 0, req.OnError(arg1, StrGet(arg2, 'utf-16'))
				}
			}
			static __Delete(this) {
				loop 7
					CallbackFree(NumGet(this, (A_Index - 1) * A_PtrSize, 'ptr'))
			}
		}
	}

	;#region IWinHttpRequest https://learn.microsoft.com/en-us/windows/win32/winhttp/iwinhttprequest-interface
	SetProxy(ProxySetting, ProxyServer, BypassList) => this.whr.SetProxy(ProxySetting, ProxyServer, BypassList)
	SetCredentials(UserName, Password, Flags) => this.whr.SetCredentials(UserName, Password, Flags)
	SetRequestHeader(Header, Value) => this.whr.SetRequestHeader(Header, Value)
	GetResponseHeader(Header) => this.whr.GetResponseHeader(Header)
	GetAllResponseHeaders() => this.whr.GetAllResponseHeaders()
	Send(Body?) => (this._ievents && this._ref := this, this.whr.Send(Body?))
	Open(verb, url, async := false) {
		this.readyState := 0
		this.whr.Open(verb, url, async)
		this.readyState := 1
	}
	WaitForResponse(Timeout := -1) => this.whr.WaitForResponse(Timeout)
	Abort() => (this._ref := this.readyState := 0, this.whr.Abort())
	SetTimeouts(ResolveTimeout := 0, ConnectTimeout := 60000, SendTimeout := 30000, ReceiveTimeout := 30000) => this.whr.SetTimeouts(ResolveTimeout, ConnectTimeout, SendTimeout, ReceiveTimeout)
	SetClientCertificate(ClientCertificate) => this.whr.SetClientCertificate(ClientCertificate)
	SetAutoLogonPolicy(AutoLogonPolicy) => this.whr.SetAutoLogonPolicy(AutoLogonPolicy)

	Status => this.whr.Status
	StatusText => this.whr.StatusText
	ResponseText => this.whr.ResponseText
	ResponseBody {
		get {
			pSafeArray := ComObjValue(t := this.whr.ResponseBody)
			pvData := NumGet(pSafeArray + 8 + A_PtrSize, 'ptr')
			cbElements := NumGet(pSafeArray + 8 + A_PtrSize * 2, 'uint')
			return ClipboardAll(pvData, cbElements)
		}
	}
	ResponseStream => this.whr.responseStream
	Option[Opt] {
		get => this.whr.Option[Opt]
		set => (this.whr.Option[Opt] := Value)
	}
	Headers {
		get {
			m := Map(), m.Default := ''
			loop parse this.GetAllResponseHeaders(), '`r`n'
				if (p := InStr(A_LoopField, ':'))
					m[SubStr(A_LoopField, 1, p - 1)] .= LTrim(SubStr(A_LoopField, p + 1))
			return m
		}
	}
	/**
	 * The OnError event occurs when there is a run-time error in the application.
	 * @prop {(this,errCode,errDesc)=>void} OnError
	 */
	OnError := 0
	/**
	 * The OnResponseDataAvailable event occurs when data is available from the response.
	 * @prop {(this,safeArray)=>void} OnResponseDataAvailable
	 */
	OnResponseDataAvailable := 0
	/**
	 * The OnResponseStart event occurs when the response data starts to be received.
	 * @prop {(this,status,contentType)=>void} OnResponseDataAvailable
	 */
	OnResponseStart := 0
	/**
	 * The OnResponseFinished event occurs when the response data is complete.
	 * @prop {(this)=>void} OnResponseDataAvailable
	 */
	OnResponseFinished := 0
	;#endregion

	readyState := 0, whr := 0, _ievents := 0
	static __New() {
		if this != WinHttpRequest
			return
		this.DeleteProp('__New')
		for prop in ['OnError', 'OnResponseDataAvailable', 'OnResponseStart', 'OnResponseFinished']
			this.Prototype.DefineProp(prop, { set: make_setter(prop) })
		make_setter(prop) => (this, value := 0) => value && (this.DefineProp(prop, { call: value }), this.enableRequestEvents())
	}
}