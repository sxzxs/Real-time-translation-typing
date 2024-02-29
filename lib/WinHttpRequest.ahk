/************************************************************************
 * @file: WinHttpRequest.ahk
 * @description: 网络请求库
 * @author thqby
 * @date 2021/04/25
 * @version 0.0.6
 ***********************************************************************/

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
		this.whr := whr := ComObject('WinHttp.WinHttpRequest.5.1')
		whr.Option[0] := IsSet(UserAgent) ? UserAgent : 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.114 Safari/537.36 Edg/89.0.774.68'
		this.IEvents := WinHttpRequest.RequestEvents.Call(ComObjValue(whr), this.id := ObjPtr(this))
	}
	__Delete() => (this.whr := this.IEvents := 0)

	request(url, method := 'GET', data := '', headers := '') {
		this.Open(method, url)
		for k, v in (headers || {}).OwnProps()
			this.SetRequestHeader(k, v)
		this.Send(data)
		return this.ResponseText
	}

	;#region IWinHttpRequest
	SetProxy(ProxySetting, ProxyServer, BypassList) => this.whr.SetProxy(ProxySetting, ProxyServer, BypassList)
	SetCredentials(UserName, Password, Flags) => this.whr.SetCredentials(UserName, Password, Flags)
	SetRequestHeader(Header, Value) => this.whr.SetRequestHeader(Header, Value)
	GetResponseHeader(Header) => this.whr.GetResponseHeader(Header)
	GetAllResponseHeaders() => this.whr.GetAllResponseHeaders()
	Send(Body := '') => this.whr.Send(Body)
	Open(verb, url, async := false) {
		this.readyState := 0
		this.whr.Open(verb, url, this.async := !!async)
		this.readyState := 1
	}
	WaitForResponse(Timeout := -1) => this.whr.WaitForResponse(Timeout)
	Abort() => this.whr.Abort()
	SetTimeouts(ResolveTimeout := 0, ConnectTimeout := 60000, SendTimeout := 30000, ReceiveTimeout := 30000) => this.whr.SetTimeouts(ResolveTimeout, ConnectTimeout, SendTimeout, ReceiveTimeout)
	SetClientCertificate(ClientCertificate) => this.whr.SetClientCertificate(ClientCertificate)
	SetAutoLogonPolicy(AutoLogonPolicy) => this.whr.SetAutoLogonPolicy(AutoLogonPolicy)
	whr := 0, readyState := 0, IEvents := 0, id := 0, async := 0
	OnResponseStart := 0, OnResponseFinished := 0
	OnResponseDataAvailable := 0, OnError := 0
	Status => this.whr.Status
	StatusText => this.whr.StatusText
	ResponseText => this.whr.ResponseText
	ResponseBody => this.whr.ResponseBody
	ResponseStream => this.whr.responseStream
	Option[Opt] {
		get => this.whr.Option[Opt]
		set => (this.whr.Option[Opt] := Value)
	}
	;#endregion
	;#region IWinHttpRequestEvents
	class RequestEvents {
		dwCookie := 0, pCPC := 0, UnkSink := 0
		__New(pwhr, pparent) {
			IConnectionPointContainer := ComObjQuery(pwhr, IID_IConnectionPointContainer := '{B196B284-BAB4-101A-B69C-00AA00341D07}')
			DllCall("ole32\CLSIDFromString", "Str", IID_IWinHttpRequestEvents := '{F97F4E15-B787-4212-80D1-D380CBBF982E}', "Ptr", pCLSID := Buffer(16))
			ComCall(4, IConnectionPointContainer, 'ptr', pCLSID, 'ptr*', &pCPC := 0)	; IConnectionPointContainer->FindConnectionPoint
			IWinHttpRequestEvents := Buffer(11 * A_PtrSize), offset := IWinHttpRequestEvents.Ptr + 4 * A_PtrSize
			NumPut('ptr', offset, 'ptr', pwhr, 'ptr', pCPC, IWinHttpRequestEvents)
			for nParam in StrSplit('3113213')
				offset := NumPut('ptr', CallbackCreate(EventHandler.Bind(A_Index), , Integer(nParam)), offset)
			ComCall(5, pCPC, 'ptr', IWinHttpRequestEvents, 'uint*', &dwCookie := 0)	; IConnectionPoint->Advise
			NumPut('ptr', dwCookie, IWinHttpRequestEvents, 3 * A_PtrSize)
			this.dwCookie := dwCookie, this.pCPC := pCPC, this.UnkSink := IWinHttpRequestEvents
			this.pwhr := pwhr

			EventHandler(index, pEvent, arg1 := 0, arg2 := 0) {
				req := ObjFromPtrAddRef(pparent)
				if (!req.async && index > 3 && index < 7) {
					req.readyState := index - 2
					return 0
				}
				switch index {
					case 1:	; QueryInterface
						NumPut('ptr', pEvent, arg2)
					case 2, 3:	; AddRef, Release
					case 4:	; OnResponseStart
						req.readyState := 2
						if (req.OnResponseStart)
							req.OnResponseStart(arg1, StrGet(arg2, 'utf-16'))
					case 5:	; OnResponseDataAvailable
						req.readyState := 3
						if (req.OnResponseDataAvailable) {
							pSafeArray := NumGet(arg1, 'ptr')
							pvData := NumGet(pSafeArray + 8 + A_PtrSize, 'ptr')
							cbElements := NumGet(pSafeArray + 8 + A_PtrSize * 2, 'uint')
							req.OnResponseDataAvailable(pvData, cbElements)
						}
					case 6:	; OnResponseFinished
						req.readyState := 4
						if (req.OnResponseFinished)
							req.OnResponseFinished()
					case 7:	; OnError
						if (req.OnError)
							req.OnError(arg1, StrGet(arg2, 'utf-16'))
				}
			}
		}
		__Delete() {
			try ComCall(6, this.pCPC, 'uint', this.dwCookie)
			loop 7
				CallbackFree(NumGet(this.UnkSink, (A_Index + 3) * A_PtrSize, 'ptr'))
			ObjRelease(this.pCPC), this.UnkSink := 0
		}
	}
	;#endregion
}