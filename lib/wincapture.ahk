/************************************************************************
 * @description Windows capture library, including `DXGI`, `DWM`, `WGC`. And some bitmap functions.
 * @author thqby
 * @date 2022/04/19
 * @version 1.2.6
 ***********************************************************************/
#Requires AutoHotkey v2+

class wincapture {
	static ptr := 0, refcount := 0
	static init(path := "") {


		SplitPath(A_LineFile,, &dir)
		dllpath := ""
		if(A_IsCompiled)
			dllpath := A_ScriptDir '\lib\' (A_PtrSize * 8) 'bit\wincapture.dll'
		else
			dllpath := dir '\' (A_PtrSize * 8) 'bit\wincapture.dll'


		if (!this.ptr) {
			if !(module := DllCall("LoadLibrary", "str", dllpath, "ptr"))
				throw Error("load dll fail")
			this.ptr := module
		}
		++this.refcount
	}
	static free() {
		if (this.refcount) {
			if (--this.refcount)
				return
			DllCall("FreeLibrary", "ptr", this)
			this.ptr := 0
		}
	}

	; Screen capture by `DXGI desktop duplication`, support for multithreading and only one instance in the process.
	; https://docs.microsoft.com/en-us/windows/win32/direct3ddxgi/desktop-dup-api
	class DXGI {
		__New(path := "") {
			wincapture.init(path)
			if hr := DllCall("wincapture\dxgi_start", "uint")
				throw OSError(hr)
		}
		__Delete() {
			DllCall("wincapture\dxgi_end", "uint")
			wincapture.free()
		}
		/**
		 * @param callback A callback function for accepting data, the received data is valid before the next capture or release. `void callback(BYTE* pBits, UINT Pitch, UINT Width, UINT Height, INT64 Tick)`, no data available when Tick is 0
		 * @param box Coordinates of the top left and bottom right corner of the capture area.
		 * 
		 * struct { int x1, int y1, int x2, int y2 } or Array [x1, y1, x2, y2] or 0 (full screen)
		 * 
		 * The coordinates in the top left corner of the capture screen are {0,0} when index >= 0
		 * 
		 * The coordinates are the virtual screen coordinates when index < 0, don't supported across multiple screens
		 * @param index The index of the output.
		 */
		capture(callback, box := 0, index := 0) {
			if box is Array
				t := box, NumPut("int", t[1], "int", t[2], "int", t[3], "int", t[4], box := Buffer(16))
			switch hr := DllCall("wincapture\dxgi_capture", "ptr", callback, "ptr", box, "uint", index, "uint") {
				case 0:
				case 0x887A0027:
					throw TimeoutError(OSError(0x887A0027).Message, -1)
				default:
					throw OSError(hr, -1)
			}
		}
		/**
		 * @param box Coordinates of the top left and bottom right corner of the capture area.
		 * 
		 * struct { int x1, int y1, int x2, int y2 } or Array [x1, y1, x2, y2] or 0 (full screen area)
		 * 
		 * The coordinates in the top left corner of the capture screen are {0,0} when index >= 0
		 * 
		 * The coordinates are the virtual screen coordinates when index < 0, don't supported across multiple screens
		 * @param index The index of the output.
		 * @returns bitmapbuffer
		 */
		captureAndSave(box := 0, index := 0) {
			if box is Array
				t := box, NumPut("int", t[1], "int", t[2], "int", t[3], "int", t[4], box := Buffer(16))
			switch hr := DllCall("wincapture\dxgi_captureAndSave", "ptr*", &pdata := 0, "ptr", box, "uint", index, "uint") {
				case 0:
					return BitmapBuffer.fromCaptureData(pdata)
				case 0x887A0027:
					throw TimeoutError(OSError(0x887A0027).Message, -1)
				default:
					throw OSError(hr, -1)
			}
		}
		; reset() => DllCall("wincapture\dxgi_reset", "uint")
		/**
		 * @param cached Cached the capture screen, otherwise capture multiple different regions in the same screen will wait for the next frame (ps: If there are no new frames will wait at least 1s).
		 */
		canCachedFrame(cached := false) => DllCall("wincapture\dxgi_canCachedFrame", "int", cached)
		/**
		 * @param timeout The time-out interval, in milliseconds. This interval specifies the amount of time that this method waits for a new frame before it returns to the caller. This method returns if the interval elapses, and a new desktop image is not available.
		 */
		setTimeout(timeout := 0) => DllCall("wincapture\dxgi_setTimeout", "uint", timeout)
		/**
		 * @param visible capture cursor when visible = true
		 */
		showCursor(visible := false) => DllCall("wincapture\dxgi_showCursor", "int", visible)
		/**
		 * release the captured texture.
		 * @param index The index of the output. release last captured texture when index = -1
		 */
		release(index := -1) => DllCall("wincapture\dxgi_releaseTexture", "int", index)
		; free thread-local bitmap data from calling `captureAndSave`
		freeBuffer() => DllCall("wincapture\dxgi_freeBuffer")
		/**
		 * Wait for an area of the screen to change
		 * @param timeout The milliseconds to wait.
		 * @param box Coordinates of the top left and bottom right corner of the capture area.
		 * 
		 * struct { int x1, int y1, int x2, int y2 } or Array [x1, y1, x2, y2] or 0 (full screen area)
		 * 
		 * The coordinates in the top left corner of the capture screen are {0,0} when index >= 0
		 * 
		 * The coordinates are the virtual screen coordinates when index < 0, don't supported across multiple screens
		 * @param index The index of the output.
		 */
		waitScreenChange(timeout, box := 0, index := 0) {
			if box is Array
				t := box, NumPut("int", t[1], "int", t[2], "int", t[3], "int", t[4], box := Buffer(16))
			switch hr := DllCall("wincapture\dxgi_waitScreenChange", "int", timeout, "ptr", box, "int", index, "uint") {
				case 0: return 1
				case 0x887A0027: return 0
				default:
					throw OSError(hr)
			}
		}
	}

	; Window capture by `DwmGetDxSharedSurface`, background windows(excluding minimization) are supported, but some windows are not supported.
	; https://docs.microsoft.com/en-us/windows/win32/dwm/dwm-overview
	class DWM {
		ptr := 0
		__New(path := "") {
			wincapture.init(path)
			if hr := DllCall("wincapture\dwm_init", "ptr*", this)
				throw OSError(hr)
		}
		__Delete() {
			DllCall("wincapture\dwm_free", "ptr", this)
			wincapture.free()
		}
		/**
		 * @param hwnd The hwnd of capture window.
		 * @param box Coordinates that of the top left and bottom right corner of the capture area, relative to the window.
		 * 
		 * struct { uint x1, uint y1, uint x2, uint y2 } or Array [x1, y1, x2, y2] or 0 (full window area) or 1 (window client area)
		 * @returns bitmapbuffer
		 */
		capture(hwnd, box := 0) {
			if box is Array
				t := box, NumPut("uint", t[1], "uint", t[2], "uint", t[3], "uint", t[4], box := Buffer(16))
			if hr := DllCall("wincapture\dwm_capture", "ptr", this, "ptr", hwnd, "ptr", box, "ptr", data := Buffer(32))
				throw OSError(hr)
			return BitmapBuffer.fromCaptureData(data.Ptr)
		}
		release() => DllCall("wincapture\dwm_releaseTexture", "ptr", this)
	}

	; Window and Monitor capture by `Windows.Graphics.Capture`, background windows(excluding minimization) are supported, and only win10 1903 or above is supported.
	; https://docs.microsoft.com/en-us/uwp/api/windows.graphics.capture?view=winrt-20348
	class WGC {
		ptr := 0
		__New(hwnd_or_monitor_or_index := 0, persistent := true, path := "") {
			wincapture.init(path)
			if (hwnd_or_monitor_or_index <= MonitorGetCount())
				ptr := DllCall("wincapture\wgc_init_monitorindex", "int", hwnd_or_monitor_or_index, "int", persistent, "ptr")
			else if DllCall("IsWindow", "ptr", hwnd_or_monitor_or_index)
				ptr := DllCall("wincapture\wgc_init_window", "ptr", hwnd_or_monitor_or_index, "int", persistent, "ptr")
			else
				ptr := DllCall("wincapture\wgc_init_monitor", "ptr", hwnd_or_monitor_or_index, "int", persistent, "ptr")
			if !ptr
				throw Error("create capture source fail")
			this.ptr := ptr
		}
		__Delete() {
			DllCall("wincapture\wgc_free", "ptr", this)
			wincapture.free()
		}
		showCursor(visible := false) => DllCall("wincapture\wgc_showCursor", "ptr", this, "int", visible)
		; show or hide the colored border around the capture source to indicate that a capture is in progress.
		; Each time switch devices, the colored border will be shown.
		isBorderRequired(required := false) => DllCall("wincapture\wgc_isBorderRequired", "ptr", this, "int", required)
		; Acquire all the frames of the capture source in the free thread to speed up each capture
		persistent(persistent := true) => DllCall("wincapture\wgc_persistent", "ptr", this, "int", persistent)
		release() => DllCall("wincapture\wgc_releaseTexture", "ptr", this)
		/**
		 * @param box Coordinates that of the top left and bottom right corner of the capture area, relative to the capture window or monitor.
		 * 
		 * struct { uint x1, uint y1, uint x2, uint y2 } or Array [x1, y1, x2, y2] or 0 (full monitor or window area) or 1 (window client area)
		 */
		capture(box := 0) {
			if box is Array
				t := box, NumPut("uint", t[1], "uint", t[2], "uint", t[3], "uint", t[4], box := Buffer(16))
			switch r := DllCall("wincapture\wgc_capture", "ptr", this, "ptr", box, "ptr", data := Buffer(32)) {
				case 0:
					return BitmapBuffer.fromCaptureData(data.Ptr)
				case -1:
					throw ValueError("Invalid capture range")
				case -2:
					throw TimeoutError("No frames available")
				case -3:
					throw Error("Invalid source")
				default:
					throw OSError(r)
			}
		}
	}
}

class BitmapBuffer {
	__New(bits, pitch, width, height, bytespixel := 4, offsetx := 0, offsety := 0) {
		NumPut("ptr", bits, "uint", pitch, "uint", width, "uint", height, "uint", bytespixel, "uint", offsetx, "uint", offsety, this.info := Buffer(40, 0))
		this.ptr := bits
		this.pitch := pitch
		this.width := width
		this.height := height
		this.size := pitch * height
		this.bytespixel := bytespixel
		this.offsetx := offsetx, this.offsety := offsety
		this.updateDesc(false)
	}
	static fromCaptureData(data, offsetx := 0, offsety := 0) {
		bb := BitmapBuffer(NumGet(data, "ptr"), NumGet(data += A_PtrSize, "uint"), NumGet(data += 4, "int"), NumGet(data += 4, "int"), 4, offsetx, offsety)
		bb.tick := NumGet(data + 4, "int64")
		return bb
	}
	static create(width, height, bytespixel := 4) {
		line := (width * bytespixel + 3) & -4
		data := Buffer(line * height, 0)
		bb := BitmapBuffer(data.Ptr, line, width, height, bytespixel)
		bb.data := data
		return bb
	}
	/**
	 * load picture
	 * @param pic picture file path, `HBITMAP:xxxx`, `IStream*`, picture binary buffer
	 * @param gray convert to grayscale after loading, the param is same as `cvtGray`
	 * @param thresh same as `threshold`, or params array
	 */
	static loadPicture(pic, gray := unset, thresh := unset) {
		static bmBitsoffset := 16 + A_PtrSize
		hbm := 0, stream := pic
		if (pic is Buffer) || ((pic is Object) && pic.HasProp("ptr") && pic.HasProp("size")) {
			hglobal := DllCall("GlobalAlloc", "uint", 0x2, "uint", pic.Size, "ptr")
			p := DllCall("GlobalLock", "ptr", hglobal, "ptr")
			DllCall("RtlMoveMemory", "ptr", p, "ptr", pic, "uptr", pic.Size)
			DllCall("GlobalUnlock", "ptr", hglobal), autofree := { ptr: hglobal, __Delete: (s) => DllCall("GlobalFree", "ptr", s) }
			if hr := DllCall("combase\CreateStreamOnHGlobal", "ptr", hglobal, "int", 0, "ptr*", &stream := 0)
				throw OSError(hr)
		}
		if stream is Integer {
			DllCall("ole32\IIDFromString", "str", "{7BF80980-BF32-101A-8BBB-00AA00300CAB}", "ptr", IID_IPicture := Buffer(16))
			try {
				if hr := DllCall("oleaut32\OleLoadPicture", "ptr", stream, "int", 0, "int", false, "ptr", IID_IPicture, "ptr*", &pic := 0)
					throw OSError(hr)
				ComCall(3, pic, "ptr*", &hbm := 0)
				hbm := DllCall("CopyImage", "ptr", hbm, "uint", 0, "int", 0, "int", 0, "uint", 0x2000)
			} catch
				throw
			finally {
				ObjRelease(stream), autofree := 0
				if pic
					ObjRelease(pic)
			}
		}
		if (hbm)
			pic := "HBITMAP:" hbm
		else hbm := LoadPicture(pic)
		DllCall("GetObject", "ptr", hbm, "int", 32, "ptr", bitmap := Buffer(32, 0))
		ptr := NumGet(bitmap, bmBitsoffset, "ptr")
		width := NumGet(bitmap, 4, "int")
		height := NumGet(bitmap, 8, "int")
		pitch := NumGet(bitmap, 12, "int")
		bits := NumGet(bitmap, 18, "ushort")
		if (bits != 32) {
			if SubStr(pic, 1, 8) = "HBITMAP:" {
				hModule := DllCall("LoadLibrary", "str", "gdiplus")
				NumPut("uint", 1, si := Buffer(24, 0))
				DllCall("gdiplus\GdiplusStartup", "ptr*", &pToken := 0, "ptr", si, "ptr", 0)
				DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "ptr", hbm, "Ptr", 0, "ptr*", &pBitmap := 0)
				DllCall("DeleteObject", "ptr", hbm)
				DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "ptr", pBitmap, "ptr*", &hbm := 0, "int", 0xff000000)
				DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap), DllCall("gdiplus\GdiplusShutdown", "ptr", pToken)
				DllCall("FreeLibrary", "ptr", hModule)
			} else
				DllCall("DeleteObject", "ptr", hbm), hbm := LoadPicture(pic, "GDI+")
			DllCall("GetObject", "ptr", hbm, "int", 32, "ptr", bitmap)
			ptr := NumGet(bitmap, bmBitsoffset, "ptr")
			pitch := NumGet(bitmap, 12, "int")
		}
		bb := BitmapBuffer.create(width, height)
		NumPut("ptr", ptr + (height - 1) * pitch, "int", -pitch, "uint", width, "uint", height, "uint", 4, info := Buffer(40, 0))
		DllCall("wincapture\copyBitmapData", "ptr", info, "ptr", bb, "int", bb.pitch, "ptr", 0)
		DllCall("DeleteObject", "ptr", hbm)
		if IsSet(gray)
			bb.cvtGray(gray, bb)
		if IsSet(thresh)
			if thresh is Array
				thresh.Length := 4, thresh[4] := bb, bb.threshold(thresh*), thresh.Pop()
			else bb.threshold(thresh,,, bb)
		if (bits <= 8 && bb.bytespixel != 1)
			bb.cvtBytes(1, bb)
		return bb
	}
	; load gdip bitmap
	static loadGpBitmap(pBitmap, gray := unset, thresh := unset) {
		DllCall("gdiplus\GdipBitmapLockBits", "ptr", pBitmap, "ptr", 0, "uint", 1, "int", 0x26200a, "ptr", bmpdata := Buffer(32, 0))
		width := NumGet(bmpdata, "uint")
		height := NumGet(bmpdata, 4, "uint")
		stride := NumGet(bmpdata, 8, "int")
		scan0 := NumGet(bmpdata, 16, "ptr")
		data := ClipboardAll(scan0, stride * height)
		DllCall("gdiplus\GdipBitmapUnlockBits", "ptr", bmpdata)
		bb := BitmapBuffer(data.Ptr, stride, width, height), bb.data := data
		if IsSet(gray)
			bb.cvtGray(gray, bb)
		if IsSet(thresh)
			thresh.Length := 4, thresh[4] := bb, bb.threshold(thresh*), thresh.Pop()
		return bb
	}
	static loadBase64(base64, params*) {
		if !DllCall("crypt32\CryptStringToBinary", "str", base64, "uint", 0, "uint", 0x01, "ptr", 0, "uint*", &size := 0, "ptr", 0, "ptr", 0)
			throw OSError(A_LastError)
		buf := Buffer(size)
		if !DllCall("crypt32\CryptStringToBinary", "str", base64, "uint", 0, "uint", 0x01, "ptr", buf, "uint*", &size, "ptr", 0, "ptr", 0)
			throw OSError(A_LastError)
		return this.loadPicture(buf, params*)
	}
	updateDesc(update := true) {
		if (update) {
			this.pitch := NumGet(b := this.info, o := A_PtrSize, "int")
			this.width := NumGet(b, o += 4, "int")
			this.height := NumGet(b, o += 4, "int")
			this.bytespixel := NumGet(b, o += 4, "int")
			this.offsetx := NumGet(b, o += 4, "int")
			this.offsety := NumGet(b, o += 4, "int")
			this.size := this.pitch * this.height
		}
		pitch := this.pitch
		switch bytespixel := this.bytespixel {
			case 4: tp := "uint"
			case 2: ; tp := "ushort"
				throw TypeError("unsupported bitmap type")
			case 1: tp := "uchar"
			case 3: this.DefineProp("__Item", { get: (s, x, y) => NumGet(s, y * pitch + x * 3, "uint") & 0xffffff, set: (s, v, x, y) => NumPut("uint", v, s, y * pitch + x * 3) })
			default:
				throw ValueError("invalid bytespixel")
		}
		if (bytespixel != 3)
			this.DefineProp("__Item", { get: (s, x, y) => NumGet(s, y * pitch + x * bytespixel, tp), set: (s, v, x, y) => NumPut(tp, v, s, y * pitch + x * bytespixel) })
	}
	
	getHexColor(x, y) => Format("0x{:08X}", this[x, y])

	/**
	 * @param type thresholding type
	 *
	 * THRESH_BINARY = 0, ; dst(x,y) = src(x,y) > thresh ? maxval : 0
	 *
	 * THRESH_BINARY_INV = 1, ; dst(x,y) = src(x,y) > thresh ? 0 : maxval
	 *
	 * THRESH_TRUNC = 2, ; dst(x,y) = src(x,y) > thresh > threshold : src(x,y)
	 *
	 * THRESH_TOZERO = 3, ; dst(x,y) = src(x,y) > thresh ? src(x,y) : 0
	 *
	 * THRESH_TOZERO_INV = 4, ; dst(x,y) = src(x,y) > thresh ? 0 : src(x,y)
	 *
	 * THRESH_MASK = 7,
	 * THRESH_OTSU = 8,
	 * THRESH_ITERATIVEBEST = 16,
	 * THRESH_MEAN = 32,
	 *
	 * THRESH_ADAPTIVE_SAUVOLA = 64	; local threshold adaptive
	 * @param params thresholding params
	 *
	 * (threshold_min & 0xff) | (((threshold_max ?? 0) & 0xff) << 8) when (type & ~THRESH_MASK = 0)
	 *
	 * threshold = auto_threshold + params(-255~255 correction_value) when (type & (THRESH_OTSU | THRESH_ITERATIVEBEST | THRESH_MEAN))
	 *
	 * threshold = mean*(1 + k*((std / 128) - 1)) when (type & THRESH_ADAPTIVE_SAUVOLA),
	 * correction_factor(-1.0<= params && params <= 1.0)
	 * or radius(params > 1 ? params : bmp_width >> -params)
	 * or [correction_factor, radius]
	 * @param maxval maximum value to use with the `THRESH_BINARY` and `THRESH_BINARY_INV` thresholding types
	 */
	threshold(type := 8, params := unset, maxval := 0xff, dst := unset) {
		if !IsSet(dst)
			dst := BitmapBuffer.create(this.width, this.height, 1)
		if !IsSet(params)
			params := 0
		else if !(params is Buffer) {
			t := params, params := Buffer(8, 0)
			if t is Array {
				if !(type & ~7)
					NumPut("uchar", t[1], "uchar", t[2], params)
				else if (type & 64)
					NumPut("float", t.Has(1) ? t[1] : 0, "int", t.Has(2) ? t[2] : 1, params)
				else NumPut("short", t[1], params)
			} else if ((type & 64) && t is Number) {
				if -1.0 <= t && t <= 1.0
					NumPut("float", t, params)
				else NumPut("int", t, params, 4)
			} else if t is Number
				NumPut("short", t, params)
			else
				throw ValueError("invalid param")
		}
		if !DllCall("wincapture\threshold", "ptr", this.info, "ptr", dst.info, "int", type, "ptr", params, "uchar", maxval)
			throw TypeError("invalid BitmapData")
		dst.updateDesc()
		dst.thresh := { type: type }
		if params && (type & 56)
			dst.thresh.val := NumGet(params, 2, "ushort")
		return dst
	}
	; 8bpp(only grayscale), 24bpp, 32bpp transformation
	cvtBytes(bytes := 4, dst := unset) {
		if !IsSet(dst)
			dst := BitmapBuffer.create(this.width, this.height, bytes)
		if !DllCall("wincapture\cvtBytes", "ptr", this.info, "ptr", dst.info, "short", bytes)
			throw TypeError("invalid BitmapData")
		dst.updateDesc()
		if bytes = 1
			dst.gray := 0
		return dst
	}
	/**
	 * @param mode Grayscale conversion mode.
	 *
	 * (r * 19595 + g * 38469 + b * 7472) >> 32 (mode 0)
	 *
	 * (r ^ 2.2 * 0.2973 + g ^ 2.2 * 0.6274 + b ^ 2.2 * 0.0753) ^ (1 / 2.2)	(mode 1 Adobe RGB (1998) [gamma=2.20])
	 *
	 * [r, g, b] custom rgb ratio, the percentages are `r/(r+g+b)`, `g/(r+g+b)`, `b/(r+g+b)`
	 */
	cvtGray(mode := 0, dst := unset) {
		if !IsSet(dst)
			dst := BitmapBuffer.create(this.width, this.height, 1)
		if IsObject(mode) {
			if mode is Buffer
				buf := mode
			else {
				buf := Buffer(12, 0)
				for k, v in mode
					switch k, false {
						case 1, "r": NumPut("uint", v, buf)
						case 2, "g": NumPut("uint", v, buf)
						case 3, "b": NumPut("uint", v, buf)
					}
			}
			if !DllCall("wincapture\cvtGray", "ptr", this.info, "ptr", dst.info, "ptr", buf)
				throw TypeError("invalid BitmapData")
			dst.gray := buf
		}
		if mode != 0 && mode != 1
			throw ValueError("mode only is 0 or 1")
		if !DllCall("wincapture\cvtGray", "ptr", this.info, "ptr", dst.info, "ptr", mode)
			throw TypeError("invalid BitmapData")
		else dst.gray := mode
		dst.updateDesc()
		return dst
	}
	copyTo(dst, linestep, x := 0, y := 0, w := 0, h := 0) {
		if (w * h)
			NumPut("uint", x, "uint", y, "uint", w, "uint", h, roi := Buffer(16))
		else roi := 0
		DllCall("wincapture\copyBitmapData", "ptr", this.info, "ptr", dst, "int", linestep, "ptr", roi)
	}
	; Select or copy part of the image 
	range(x1 := 0, y1 := 0, x2 := unset, y2 := unset, copy := false) {
		if !IsSet(x2)
			x2 := this.width
		if !IsSet(y2)
			y2 := this.height
		w := x2 - x1, h := y2 - y1, pitch := this.pitch, src := this.ptr + y1 * pitch + x1 * this.bytespixel
		if (copy) {
			line := (this.bytespixel * w + 3) & -4
			data := Buffer(size := line * h, 0), ptr := data.Ptr
			bb := BitmapBuffer(ptr, line, w, h, this.bytespixel, this.offsetx + x1, this.offsety + y1), bb.data := data
			NumPut("uint", x1, "uint", y1, "uint", x2, "uint", y2, roi := Buffer(16))
			DllCall("wincapture\copyBitmapData", "ptr", this.info, "ptr", bb, "int", line, "ptr", roi)
			return bb
		} else
			return BitmapBuffer(src, pitch, w, h, this.bytespixel, this.offsetx + x1, this.offsety + y1)
	}
	findColor(&x, &y, color, variation := 0, direction := 0) {
		return DllCall("wincapture\findColor", "uint*", &x := 0, "uint*", &y := 0, "ptr", this.info, "uint", color, "uint", variation, "int", direction)
	}
	findAllColor(color, maxcount := 10, variation := 0, direction := 0) {
		if size := DllCall("wincapture\findAllColor", "ptr", buf := Buffer(8 * maxcount), "uint", maxcount, "ptr", this.info, "uint", color, "uint", variation, "int", direction) {
			t := [], p := buf.Ptr
			loop size
				t.Push({ x: NumGet(p, "int"), y: NumGet(p += 4, "int") }), p += 4
			return t
		}
	}
	; the same as `findAllMultiColors`
	findMultiColors(&x, &y, colors, similarity := 1.0, variation := 0, direction := 0) {
		if colors is Array {
			t := colors
			p := NumPut("int", t.Length, colors := Buffer(4 + t.Length * 12))
			for it in t
				for k, v in it
					p := NumPut("int", v, p)
		}
		return DllCall("wincapture\findMultiColors", "int*", &x := 0, "int*", &y := 0, "ptr", this.info, "ptr", colors, "float", similarity, "uint", variation, "int", direction)
	}
	/**
	 * find multiple colors with relative position
	 * @param colors the colors to find, `[[color1, x1, y1], [color2, x2, y2]]`, omitting alpha will ignore alpha of pixel color
	 * @param similarity matching total_colors * silmilarity
	 * @param maxcount the max position count
	 * @param variation gradient value of each channel, 0x05050505
	 * @param direction find direction, x→ y↓ 0, x← y↓ 1, x→ y↑ 2, x← y↑ 3
	 */
	findAllMultiColors(colors, similarity := 1.0, maxcount := 10, variation := 0, direction := 0) {
		if colors is Array {
			t := colors
			p := NumPut("int", t.Length, colors := Buffer(4 + t.Length * 12))
			for it in t
				for k, v in it
					p := NumPut("int", v, p)
		}
		if size := DllCall("wincapture\findAllMultiColors", "ptr", buf := Buffer(8 * maxcount), "uint", maxcount, "ptr", this.info, "ptr", colors, "float", similarity, "uint", variation, "int", direction) {
			t := [], p := buf.Ptr
			loop size
				t.Push({ x: NumGet(p, "int"), y: NumGet(p += 4, "int") }), p += 4
			return t
		}
	}
	; the same as `findAllPic`
	findPic(&x, &y, bmp, similarity := 1.0, variation := 0, direction := 0) {
		if DllCall("wincapture\findPic", "int*", &x := 0, "int*", &y := 0, "ptr", this.info, "ptr", bmp.info, "float", similarity, "int64", variation, "int", direction)
			return true
		return false
	}
	/**
	 * find a region of the image for an image.
	 * @param bmp `BitmapBuffer`, the image to find
	 * @param similarity Similarity, matching total_pixels * similarity
	 * @param maxcount the max position count
	 * @param variation gradient value and transparent color, transparent_color << 32 | variation,
	 * black transparent color must is 0xff000000(32bpp) or 0xff00(8bpp)
	 *
	 * for 32bpp bitmap, a pixel color that alpha < 255 will be considered transparent, and `ignore alpha of source bitmap`
	 * @param direction find direction, x→ y↓ 0, x← y↓ 1, x→ y↑ 2, x← y↑ 3
	 */
	findAllPic(bmp, similarity := 1.0, maxcount := 10, variation := 0, direction := 0) {
		if n := DllCall("wincapture\findAllPic", "ptr", buf := Buffer(8 * maxcount), "uint", maxcount, "ptr", this.info, "ptr", bmp.info, "float", similarity, "int64", variation, "int", direction) {
			t := [], p := buf.Ptr
			loop n
				t.Push({ x: NumGet(p, "int"), y: NumGet(p += 4, "int") }), p += 4
			return t
		}
	}
	clone() => this.range(0, 0, this.width, this.height, true)
	BMP(bpp24 := false) {
		sw := this.width, sh := this.height, bytespixel := bpp24 ? 3 : 4
		bytes := sw * bytespixel, line := (bytes + 3) & -4
		bmp := Buffer(54 + (size := sh * line), 0)
		NumPut("ushort", 0x4d42, "uint", 54 + size, "uint", 0, "uint", 54, "uint", 40,
			"int", sw, "int", -sh, "ushort", 1, "ushort", bytespixel * 8, "uint", 0, "uint", size, bmp)
		if (bytespixel == this.bytespixel)
			this.copyTo(bmp.Ptr + 54, line)
		else
			this.cvtBytes(3, BitmapBuffer(bmp.Ptr + 54, line, sw, sh, 3))
		return bmp
	}
	HBITMAP(bpp24 := false) {
		sw := this.width, sh := this.height, bytespixel := bpp24 ? 3 : 4, pitch := (sw * bytespixel + 3) & -4
		if (pitch == this.pitch)
			hbm := DllCall("CreateBitmap", "int", sw, "int", sh, "uint", 1, "uint", bytespixel * 8, "ptr", this, "ptr")
		else {
			NumPut("uint", 40, "int", sw, "int", -sh, "ushort", 1, "ushort", bytespixel * 8, bm := Buffer(40, 0))
			hbm := DllCall("CreateDIBSection", "ptr", 0, "ptr", bm, "int", 0, "ptr*", &pvBits := 0, "ptr", 0, "uint", 0, "ptr")
			if (bytespixel == this.bytespixel)
				this.copyTo(pvBits, pitch)
			else
				this.cvtBytes(bpp24 ? 3 : 4, BitmapBuffer(pvBits, pitch, sw, sh))
		}
		return { ptr: hbm, __Delete: (s) => DllCall("DeleteObject", "ptr", s) }
	}
	HBITMAP_NEW(bpp24 := false) {
		sw := this.width, sh := this.height, bytespixel := bpp24 ? 3 : 4, pitch := (sw * bytespixel + 3) & -4

		NumPut("uint", 40, "int", sw, "int", -sh, "ushort", 1, "ushort", bytespixel * 8, bm := Buffer(40, 0))
		hbm := DllCall("CreateDIBSection", "ptr", 0, "ptr", bm, "int", 0, "ptr*", &pvBits := 0, "ptr", 0, "uint", 0, "ptr")
		if (bytespixel == this.bytespixel)
			this.copyTo(pvBits, pitch)
		else
			this.cvtBytes(bpp24 ? 3 : 4, BitmapBuffer(pvBits, pitch, sw, sh))

		return { ptr: hbm, __Delete: (s) => DllCall("DeleteObject", "ptr", s) }
	}
	; save to bmp file
	save(path) {
		file := FileOpen(path, "w"), file.RawWrite(this.BMP()), file.Close()
	}
	; display bitmap
	show(guiname := "") {
		static guis := Map()
		if this.bytespixel < 3
			return this.cvtBytes(3).show(guiname)
		if (!guis.Has(guiname)) {
			g := guis[guiname] := Gui("AlwaysOnTop +Resize -DPIScale", guiname), g.obm := 0
			g.hdc := { ptr: DllCall("GetDC", "ptr", g.hwnd, "ptr"), __Delete: (s) => DllCall("ReleaseDC", "ptr", g.Hwnd, "ptr", s) }
			g.mdc := { ptr: DllCall("CreateCompatibleDC", "ptr", g.hdc, "ptr"), __Delete: (s) => DllCall("DeleteDC", "ptr", s) }
			DllCall("SetStretchBltMode", "Ptr", g.hdc, "int", 4)
			if this.width > 0.8 * A_ScreenWidth
				g.Show("NA w" (w := 0.8 * A_ScreenWidth) " h" (w / this.width * this.height))
			else if this.height > 0.8 * A_ScreenHeight
				g.Show("NA h" (h := 0.8 * A_ScreenHeight) " w" (h / this.height * this.width))
			else g.Show("NA w" this.width " h" this.height)
			g.OnEvent("Close", (g, * ) => (DllCall("DeleteObject", "ptr", DllCall("SelectObject", "ptr", g.mdc, "ptr", g.obm, "ptr")), g.mdc := 0, g.hdc := 0, guis.Delete(guiname)))
			g.OnEvent("Size", (g, * ) => (g.GetClientPos(, , &w, &h), g.obm ? DllCall("StretchBlt", "ptr", g.hdc, "int", 0, "int", 0, "int", w, "int", h, "ptr", g.mdc, "int", 0, "int", 0, "int", g.width, "int", g.height, "uint", 0x00CC0020) : 0))
		} else (g := guis[guiname]).Show("NA")

		hbm := getDIBitmap()
		g.width := this.width, g.height := this.height
		if (g.obm)
			DllCall("DeleteObject", "ptr", DllCall("SelectObject", "ptr", g.mdc, "ptr", hbm, "ptr"))
		else g.obm := DllCall("SelectObject", "ptr", g.mdc, "ptr", hbm, "ptr")
		g.GetClientPos(, , &w, &h)
		DllCall("StretchBlt", "ptr", g.hdc, "int", 0, "int", 0, "int", w, "int", h, "ptr", g.mdc, "int", 0, "int", 0, "int", g.width, "int", g.height, "uint", 0x00CC0020)

		getDIBitmap() {
			bm := bm2 := Buffer(40, 0), sw := this.width, sh := this.height, ptr := this.ptr, size := this.size, linebytes := (sw * this.bytespixel + 3) & -4
			NumPut("uint", 40, "int", this.width, "int", -sh, "ushort", 1, "ushort", this.bytespixel * 8, "uint", 0, "uint", linebytes * sh, bm)
			if linebytes != this.pitch
				NumPut("int", Integer(this.pitch / this.bytespixel), bm2 := ClipboardAll(bm2), 4), NumPut("uint", size, bm2, 20)
			return DllCall("CreateDIBitmap", "ptr", g.hdc, "ptr", bm, "uint", 4, "ptr", ptr, "ptr", bm2, "int", 0, "ptr")
		}
	}
}