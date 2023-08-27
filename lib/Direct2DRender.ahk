;██████╗ ██╗██████╗ ███████╗ ██████╗████████╗██████╗ ██████╗ ██████╗ ███████╗███╗   ██╗██████╗ ███████╗██████╗ 
;██╔══██╗██║██╔══██╗██╔════╝██╔════╝╚══██╔══╝╚════██╗██╔══██╗██╔══██╗██╔════╝████╗  ██║██╔══██╗██╔════╝██╔══██╗
;██║  ██║██║██████╔╝█████╗  ██║        ██║    █████╔╝██║  ██║██████╔╝█████╗  ██╔██╗ ██║██║  ██║█████╗  ██████╔╝
;██║  ██║██║██╔══██╗██╔══╝  ██║        ██║   ██╔═══╝ ██║  ██║██╔══██╗██╔══╝  ██║╚██╗██║██║  ██║██╔══╝  ██╔══██╗
;██████╔╝██║██║  ██║███████╗╚██████╗   ██║   ███████╗██████╔╝██║  ██║███████╗██║ ╚████║██████╔╝███████╗██║  ██║
;╚═════╝ ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝   ╚═╝   ╚══════╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═╝
#include ./Direct2D.ahk
#Requires AutoHotkey v2+

class Direct2DRender 
{
	;x_orTitle					:		x pos of overlay OR title of window to attach to
	;y_orClient					:		y pos of overlay OR attach to client instead of window (default window)
	;width_orForeground			:		width of overlay OR overlay is only drawn when the attached window is in the foreground (default 1)
	;height						:		height of overlay
	;alwaysOnTop				:		If enabled, the window will always appear over other windows
	;vsync						:		If enabled vsync will cause the overlay to update no more than the monitors refresh rate, useful when looping without sleeps
	;clickThrough				:		If enabled, mouse clicks will pass through the window onto the window beneath
	;taskBarIcon				:		If enabled, the window will have a taskbar icon
	;guiID						:		name of the ahk gui id for the overlay window, if 0 defaults to "ShinsOverlayClass_TICKCOUNT"
	;
	;notes						:		if planning to attach to window these parameters can all be left blank
	
	__New(x_orTitle:=0,y_orClient:=1,width_orForeground:=1,height:=0,alwaysOnTop:=1,vsync:=0,clickThrough:=1,taskBarIcon:=0,guiID:=0) 
	{
		this.interpolationMode := 0 ;0 = nearestNeighbor, 1 = linear ;affects DrawImage() scaling 
		this.data := Map()			;reserved name for general data storage

		;[output variables] you can read these to get extra info, DO NOT MODIFY THESE
		this.x := x_orTitle					;overlay x position OR title of window to attach to
		this.y := y_orClient				;overlay y position OR attach to client area
		this.width := width_orForeground	;overlay width OR attached overlay only drawn when window is in foreground
		this.height := height				;overlay height
		this.x2 := (IsNumber(x_orTitle) ? x_orTitle : 0) + width_orForeground
		this.y2 := y_orClient+height
		this.attachHWND := 0				;HWND of the attached window, 0 if not attached
		this.attachClient := 0				;1 if using client space, 0 otherwise
		this.attachForeground := 0			;1 if overlay is only drawn when the attached window is the active window; 0 otherwise
		
		;Generally with windows there are invisible borders that allow
		;the window to be resized, but it makes the window larger
		;these values should contain the window x, y offset and width, height for actual postion and size
		this.realX := 0
		this.realY := 0
		this.realWidth := 0
		this.realHeight := 0
		this.realX2 := 0
		this.realY2 := 0
	
		;#############################
		;	Setup internal stuff
		;#############################
		this.bits := (a_ptrsize == 8)
		this.imageCache := Map()
		this.fonts := Map()
		this.lastPos := 0
		this.offX := -(IsNumber(x_orTitle) ? x_orTitle : 0)
		this.offY := -y_orClient
		this.lastCol := 0
		this.drawing := 0
		this.guiID := (guiID = 0 ? "ShinsOverlayClass_" a_tickcount : guiID)
		this.owned := 0
		this.lastSize := 0
		this.alwaysontop := alwaysontop
		pOut := 0
		
		this._cacheImage := this.mcode("VVdWMfZTg+wMi0QkLA+vRCQoi1QkMMHgAoXAfmSLTCQki1wkIA+26gHIiUQkCGaQD7Z5A4PDBIPBBIn4D7bwD7ZB/g+vxpn3/YkEJA+2Qf0Pr8aZ9/2JRCQED7ZB/A+vxpn3/Q+2FCSIU/wPtlQkBIhT/YhD/on4iEP/OUwkCHWvg8QMifBbXl9dw5CQkJCQ|V1ZTRTHbRItUJEBFD6/BRo0MhQAAAABFhcl+YUGD6QFFD7bSSYnQQcHpAkqNdIoERQ+2WANBD7ZAAkmDwARIg8EEQQ+vw5lB9/qJx0EPtkD9QQ+vw5lB9/pBicFBD7ZA/ECIefxEiEn9QQ+vw0SIWf+ZQff6iEH+TDnGdbNEidhbXl/DkJCQkJCQkJCQkJCQ")
		
		this.LoadLib("d2d1","dwrite","dwmapi","gdiplus")
		gsi := buffer(24,0)
		NumPut("uint", 1, gsi, 0)
		token := 0
		DllCall("gdiplus\GdiplusStartup", "Ptr*", &token, "Ptr", gsi, "Ptr*", 0)
		this.gdiplusToken := token
		
		this.gui := Gui("-DPIScale -Caption +E0x80000" (clickthrough ? " +E0x20" : "") (alwaysontop ? " +Alwaysontop" : "") (!taskBarIcon ? " +toolwindow" : ""),this.guiID)
		
		this.hwnd := hwnd := this.gui.hwnd
		;DllCall("ShowWindow","Uptr",this.hwnd,"uint",(clickThrough ? 8 : 1))
		this.gui.show()

		this.tBufferPtr := Buffer(4096,0)
		this.rect1Ptr :=  Buffer(64,0)
		this.rect2Ptr :=  Buffer(64,0)
		this.rtPtr :=  Buffer(64,0)
		this.hrtPtr :=  Buffer(64,0)
		this.matrixPtr :=  Buffer(64,0)
		this.colPtr :=  Buffer(64,0)
		this.clrPtr :=  Buffer(64,0)
		margins := Buffer(16,0)
		NumPut("int",-1,margins,0), NumPut("int",-1,margins,4), NumPut("int",-1,margins,8), NumPut("int",-1,margins,12)
		ext := DllCall("dwmapi\DwmExtendFrameIntoClientArea","Uptr",hwnd,"ptr",margins,"uint")
		if (ext != 0) 
		{
			this.Err("Problem with DwmExtendFrameIntoClientArea","overlay will not function`n`nReloading the script usually fixes this`n`nError: " DllCall("GetLastError","uint") " / " ext)
			return
		}
		DllCall("SetLayeredWindowAttributes","Uptr",hwnd,"Uint",0,"char",255,"uint",2)

    	this.factory := ID2D1Factory()
		this.wFactory := IDWriteFactory()

		this.stroke := this.factory.CreateStrokeStyle(D2D1_STROKE_STYLE_PROPERTIES([,,,, 255]), 0, 0)
		this.strokeRounded := this.factory.CreateStrokeStyle(D2D1_STROKE_STYLE_PROPERTIES([2, 2, 0, 2, 255]), 0, 0)

		hwnd_render_target_property := D2D1_HWND_RENDER_TARGET_PROPERTIES([hwnd, width_orForeground, height, D2D1_PRESENT_OPTIONS_NONE := (vsync?0:2)])
		this.renderTarget := this.factory.CreateHwndRenderTarget(D2D1_RENDER_TARGET_PROPERTIES([,,1,96,96]), hwnd_render_target_property)
    	this.brush := this.renderTarget.CreateSolidColorBrush(D2D1_COLOR_F([]), D2D1_BRUSH_PROPERTIES([1, D2D1_MATRIX_3X2_F([1, 0, 0, 1, 0, 0])]))
		
		if (x_orTitle != 0 and winexist(x_orTitle))
			this.AttachToWindow(x_orTitle,y_orClient,width_orForeground)
		 else
			this.SetPosition(x_orTitle,y_orClient)
		
		this.renderTarget.BeginDraw()
		this.renderTarget.Clear(this.clrPtr)
		this.renderTarget.EndDraw()
	}
	
	
	;####################################################################################################################################################################################################################################
	;AttachToWindow
	;
	;title				:				Title of the window (or other type of identifier such as 'ahk_exe notepad.exe' etc..
	;attachToClientArea	:				Whether or not to attach the overlay to the client area, window area is used otherwise
	;foreground			:				Whether or not to only draw the overlay if attached window is active in the foreground, otherwise always draws
	;setOwner			:				Sets the ownership of the overlay window to the target window
	;
	;return				;				Returns 1 if either attached window is active in the foreground or no window is attached; 0 otherwise
	;
	;Notes				;				Does not actually 'attach', but rather every BeginDraw() fuction will check to ensure it's 
	;									updated to the attached windows position/size
	;									Could use SetParent but it introduces other issues, I'll explore further later
	
	AttachToWindow(title,AttachToClientArea:=0,foreground:=1,setOwner:=0) 
	{
		if (title = "") {
			this.Err("AttachToWindow: Error","Expected title string, but empty variable was supplied!")
			return 0
		}
		if (!this.attachHWND := winexist(title)) {
			this.Err("AttachToWindow: Error","Could not find window - " title)
			return 0
		}
		numput("Uptr",this.attachHwnd,this.tbufferptr,0)
		this.attachHWND := numget(this.tbufferptr,0,"Ptr")
		if (!DllCall("GetWindowRect","Uptr",this.attachHWND,"ptr",this.tBufferPtr)) {
			this.Err("AttachToWindow: Error","Problem getting window rect, is window minimized?`n`nError: " DllCall("GetLastError","uint"))
			return 0
		}
		
		this.attachClient := AttachToClientArea
		this.attachForeground := foreground
		this.AdjustWindow(&x,&y,&w,&h)
		
		this.renderTarget.Resize(D2D1_SIZE_U([this.width := w, this.height := h]))

		this.SetPosition(x,y,this.width,this.height)
		if (setOwner) {
			this.alwaysontop := 0
			WinSetAlwaysOnTop(0, "ahk_id " this.hwnd)
			this.owned := 1
			dllcall("SetWindowLongPtr","Uptr",this.hwnd,"int",-8,"Uptr",this.attachHWND)
			this.SetPosition(this.x,this.y)
		} else {
			this.owned := 0
		}
	}
	
	
	;####################################################################################################################################################################################################################################
	;BeginDraw
	;
	;return				;				Returns 1 if either attached window is active in the foreground or no window is attached; 0 otherwise
	;
	;Notes				;				Must always call EndDraw to finish drawing and update the overlay
	
	BeginDraw() 
	{
		local pOut := 0
		if (this.attachHWND) 
		{
			if (!DllCall("GetWindowRect","Uptr",this.attachHWND,"ptr",this.tBufferPtr) or (this.attachForeground and DllCall("GetForegroundWindow","cdecl Ptr") != this.attachHWND)) 
			{
				if (this.drawing) 
				{
					this.renderTarget.BeginDraw()
					this.renderTarget.Clear(this.clrPtr)
					this.EndDraw()
					this.drawing := 0
				}
				return 0
			}
			x := NumGet(this.tBufferPtr,0,"int")
			y := NumGet(this.tBufferPtr,4,"int")
			w := NumGet(this.tBufferPtr,8,"int")-x
			h := NumGet(this.tBufferPtr,12,"int")-y
			if ((w<<16)+h != this.lastSize) 
			{
				this.AdjustWindow(&x,&y,&w,&h)
				this.renderTarget.Resize(D2D1_SIZE_U([this.width := w, this.height := h]))
				this.SetPosition(x,y)
			} 
			else if ((x<<16)+y != this.lastPos) 
			{
				this.AdjustWindow(&x,&y,&w,&h)
				this.SetPosition(x,y)
			}
			if (!this.drawing and this.alwaysontop) 
			{
				WinSetAlwaysOnTop(1,"ahk_id " this.hwnd)
			}
		} 
		else 
		{
			if (!DllCall("GetWindowRect","Uptr",this.hwnd,"ptr",this.tBufferPtr)) 
			{
				if (this.drawing) 
				{
					this.renderTarget.BeginDraw()
					this.renderTarget.Clear(this.clrPtr)
					this.EndDraw()
					this.drawing := 0
				}
				return 0
			}
			x := NumGet(this.tBufferPtr,0,"int")
			y := NumGet(this.tBufferPtr,4,"int")
			w := NumGet(this.tBufferPtr,8,"int")-x
			h := NumGet(this.tBufferPtr,12,"int")-y
			if ((w<<16)+h != this.lastSize) 
			{
				this.AdjustWindow(&x,&y,&w,&h)
				newSize := Buffer(16,0)
				NumPut("uint",this.width := w,newSize,0)
				NumPut("uint",this.height := h,newSize,4)
				this.renderTarget.Resize(D2D1_SIZE_U([this.width := w, this.height := h]))
				this.SetPosition(x,y)
			} 
			else if ((x<<16)+y != this.lastPos) 
			{
				this.AdjustWindow(&x,&y,&w,&h)
				this.SetPosition(x,y)
			}
		}
		this.drawing := 1
		this.renderTarget.BeginDraw()
		this.renderTarget.Clear(this.clrPtr)
		return 1
	}
	
	
	;####################################################################################################################################################################################################################################
	;EndDraw
	;
	;return				;				Void
	;
	;Notes				;				Must always call EndDraw to finish drawing and update the overlay
	
	EndDraw() 
	{
		local pOut:=0
		if (this.drawing)
		{
			this.renderTarget.EndDraw()
		}
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawImage
	;
	;dstX				:				X position to draw to
	;dstY				:				Y position to draw to
	;dstW				:				Width of image to draw to
	;dstH				:				Height of image to draw to
	;srcX				:				X position to draw from
	;srcY				:				Y position to draw from
	;srcW				:				Width of image to draw from
	;srcH				:				Height of image to draw from
	;alpha				:				Image transparency, float between 0 and 1
	;drawCentered		:				Draw the image centered on dstX/dstY, otherwise dstX/dstY will be the top left of the image
	;rotation			:				Image rotation in degrees (0-360)
	;rotationOffsetX	:				X offset to base rotations on (defaults to center x)
	;rotationOffsetY	:				Y offset to base rotations on (defaults to center y)
	;
	;return				;				Void
	
	DrawImage(image,dstX,dstY,dstW:=0,dstH:=0,srcX:=0,srcY:=0,srcW:=0,srcH:=0,alpha:=1,drawCentered:=0,rotation:=0,rotOffX:=0,rotOffY:=0) 
	{
		i := (this.imageCache.Has(image) ? this.imageCache[image] : this.cacheImage(image))
		
		if (dstW <= 0)
			dstW := i["w"]
		if (dstH <= 0)
			dstH := i["h"]
		x := dstX-(drawCentered?dstW/2:0)
		y := dstY-(drawCentered?dstH/2:0)
		NumPut("float", x, this.rect1Ptr, 0)
		NumPut("float", y, this.rect1Ptr, 4)
		NumPut("float", x + dstW, this.rect1Ptr, 8)
		NumPut("float", y + dstH, this.rect1Ptr, 12)
		NumPut("float", srcX, this.rect2Ptr, 0)
		NumPut("float", srcY,this.rect2Ptr,4)
		NumPut("float", srcX + (srcW=0?i["w"]:srcW),this.rect2Ptr,8)
		NumPut("float", srcY + (srcH=0?i["h"]:srcH),this.rect2Ptr,12)
		
		if (rotation != 0) 
		{
			if (this.bits) 
			{
				bf := Buffer(64)
				if (rotOffX or rotOffY) 
				{
					NumPut("float", dstX+rotOffX, bf, 0)
					NumPut("float", dstY+rotOffY,bf,4)
				} 
				else 
				{
					NumPut("float", dstX+(drawCentered?0:dstW/2), bf, 0)
					NumPut("float", dstY+(drawCentered?0:dstH/2), bf, 4)
				}
				DllCall("d2d1\D2D1MakeRotateMatrix","float",rotation,"double",NumGet(bf,0,"double"),"ptr",this.matrixPtr)
			} 
			else 
			{
				DllCall("d2d1\D2D1MakeRotateMatrix","float",rotation,"float",dstX+(drawCentered?0:dstW/2),"float",dstY+(drawCentered?0:dstH/2),"ptr",this.matrixPtr)
			}
			this.renderTarget.SetTransform(this.matrixPtr)
			this.renderTarget.DrawBitmap(i["p"], this.rect1Ptr, alpha, this.interpolationMode, this.rect2Ptr)
			this.renderTarget.SetTransform(D2D1_MATRIX_3X2_F([1, 0, 0, 1, 0, 0]))
		} 
		else 
		{
			this.renderTarget.DrawBitmap(i["p"], this.rect1Ptr, alpha, this.interpolationMode, this.rect2Ptr)
		}
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawText
	;
	;text				:				The text to be drawn
	;x					:				X position
	;y					:				Y position
	;size				:				Size of font
	;color				:				Color of font
	;fontName			:				Font name (must be installed)
	;extraOptions		:				Additonal options which may contain any of the following seperated by spaces:
	;									Width .............	w[number]				: Example > w200			(Default: this.width)
	;									Height ............	h[number]				: Example > h200			(Default: this.height)
	;									Alignment ......... a[Left/Right/Center]	: Example > aCenter			(Default: Left)
	;									DropShadow ........	ds[hex color]			: Example > dsFF000000		(Default: DISABLED)
	;									DropShadowXOffset . dsx[number]				: Example > dsx2			(Default: 1)
	;									DropShadowYOffset . dsy[number]				: Example > dsy2			(Default: 1)
	;									Outline ........... ol[hex color]			: Example > olFF000000		(Default: DISABLED)
	;
	;return				;				Void
	
	DrawText(text,x,y,size:=18,color:=0xFFFFFFFF,fontName:="Arial",extraOptions:="") 
	{
		local w,h,p,ds,dsx,dsy,ol
		w := (RegExMatch(extraOptions,"w([\d\.]+)",&w) ? w[1] : this.width)
		h := (RegExMatch(extraOptions,"h([\d\.]+)",&h) ? h[1] : this.height)
		
		p := (this.fonts.Has(fontName size) ? this.fonts[fontName size] : this.CacheFont(fontName,size))
		
		p.SetTextAlignment((InStr(extraOptions,"aRight") ? 1 : InStr(extraOptions,"aCenter") ? 2 : 0))
		
		if (RegExMatch(extraOptions,"ds([a-fA-F\d]+)",&ds)) 
		{
			dsx := (RegExMatch(extraOptions,"dsx([\d\.]+)",&dsx) ? dsx[1] : 1)
			dsy := (RegExMatch(extraOptions,"dsy([\d\.]+)",&dsy) ? dsy[1] : 1)
			this.DrawTextShadow(p,text,x+dsx,y+dsy,w,h,"0x" ds[1])
		} 
		else if (RegExMatch(extraOptions,"ol([a-fA-F\d]+)",&ol)) 
		{
			this.DrawTextOutline(p,text,x,y,w,h,"0x" ol[1])
		}
		
		this.SetBrushColor(color)
		this.renderTarget.DrawText(text, p, D2D1_RECT_F([x, y, x+w, y+h]), this.brush)
	}

	GetTextWidthHeight(text, size, fontName := 'Arial', extraOptions := '')
	{
		p := (this.fonts.Has(fontName size) ? this.fonts[fontName size] : this.CacheFont(fontName,size))
		p.SetTextAlignment((InStr(extraOptions,"aRight") ? 1 : InStr(extraOptions,"aCenter") ? 2 : 0))
		t := this.wFactory.CreateTextLayout(text, p, 5000, 5000)
		size := t.GetMetrics()
		return {width : size.width, height : size.height}
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawEllipse
	;
	;x					:				X position
	;y					:				Y position
	;w					:				Width of ellipse
	;h					:				Height of ellipse
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;thickness			:				Thickness of the line
	;
	;return				;				Void
	
	DrawEllipse(x, y, w, h, color, thickness:=1) 
	{
		this.SetBrushColor(color)
		this.renderTarget.DrawEllipse(D2D1_ELLIPSE([D2D1_POINT_2F([x, y]), w, h]), this.brush, thickness, this.stroke)
	}
	
	
	;####################################################################################################################################################################################################################################
	;FillEllipse
	;
	;x					:				X position
	;y					:				Y position
	;w					:				Width of ellipse
	;h					:				Height of ellipse
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;
	;return				;				Void
	
	FillEllipse(x, y, w, h, color) 
	{
		this.SetBrushColor(color)
		this.renderTarget.FillEllipse(D2D1_ELLIPSE([D2D1_POINT_2F([x, y]), w, h]), this.brush)
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawCircle
	;
	;x					:				X position
	;y					:				Y position
	;radius				:				Radius of circle
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;thickness			:				Thickness of the line
	;
	;return				;				Void
	
	DrawCircle(x, y, radius, color, thickness:=1) 
	{
		this.SetBrushColor(color)
		this.renderTarget.DrawEllipse(D2D1_ELLIPSE([D2D1_POINT_2F([x, y]), radius, radius]), this.brush, thickness, this.stroke)
	}
	
	
	;####################################################################################################################################################################################################################################
	;FillCircle
	;
	;x					:				X position
	;y					:				Y position
	;radius				:				Radius of circle
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;
	;return				;				Void
	
	FillCircle(x, y, radius, color) 
	{
		this.SetBrushColor(color)
		this.renderTarget.FillEllipse(D2D1_ELLIPSE([D2D1_POINT_2F([x, y]), radius, radius]), this.brush)
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawRectangle
	;
	;x					:				X position
	;y					:				Y position
	;w					:				Width of rectangle
	;h					:				Height of rectangle
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;thickness			:				Thickness of the line
	;
	;return				;				Void
	
	DrawRectangle(x, y, w, h, color, thickness:=1) 
	{
		this.SetBrushColor(color)
		this.renderTarget.DrawRectangle(D2D1_RECT_F([x, y, x+w, y+h]), this.brush, thickness, this.stroke)
	}
	
	
	;####################################################################################################################################################################################################################################
	;FillRectangle
	;
	;x					:				X position
	;y					:				Y position
	;w					:				Width of rectangle
	;h					:				Height of rectangle
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;
	;return				;				Void
	
	FillRectangle(x, y, w, h, color) 
	{
		this.SetBrushColor(color)
        this.renderTarget.FillRectangle(D2D1_RECT_F([x, y, x + w, y + h]), this.brush)
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawRoundedRectangle
	;
	;x					:				X position
	;y					:				Y position
	;w					:				Width of rectangle
	;h					:				Height of rectangle
	;radiusX			:				The x-radius for the quarter ellipse that is drawn to replace every corner of the rectangle.
	;radiusY			:				The y-radius for the quarter ellipse that is drawn to replace every corner of the rectangle.
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;thickness			:				Thickness of the line
	;
	;return				;				Void
	
	DrawRoundedRectangle(x, y, w, h, radiusX, radiusY, color, thickness:=1) 
	{
		this.SetBrushColor(color)
		this.renderTarget.DrawRoundedRectangle(D2D1_ROUNDED_RECT([D2D1_RECT_F([x, y, x + w, y + h]), radiusX, radiusY]), this.brush, thickness, this.stroke)
	}
	
	
	;####################################################################################################################################################################################################################################
	;FillRectangle
	;
	;x					:				X position
	;y					:				Y position
	;w					:				Width of rectangle
	;h					:				Height of rectangle
	;radiusX			:				The x-radius for the quarter ellipse that is drawn to replace every corner of the rectangle.
	;radiusY			:				The y-radius for the quarter ellipse that is drawn to replace every corner of the rectangle.
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;
	;return				;				Void
	
	FillRoundedRectangle(x, y, w, h, radiusX, radiusY, color) 
	{
		this.SetBrushColor(color)
		this.renderTarget.FillRoundedRectangle(D2D1_ROUNDED_RECT([D2D1_RECT_F([x, y, x + w, y + h]), radiusX, radiusY]) , this.brush)
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawLine
	;
	;x1					:				X position for line start
	;y1					:				Y position for line start
	;x2					:				X position for line end
	;y2					:				Y position for line end
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;thickness			:				Thickness of the line
	;
	;return				;				Void

	DrawLine(x1,y1,x2,y2,color:=0xFFFFFFFF,thickness:=1,rounded:=0) 
	{
		this.SetBrushColor(color)
		this.renderTarget.DrawLine(D2D1_POINT_2F([x1, y1]), D2D1_POINT_2F([x2, y2]), this.brush, thickness, (rounded?this.strokeRounded:this.stroke))
		
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawLines
	;
	;lines				:				An array of 2d points, example: [[0,0],[5,0],[0,5]]
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;connect			:				If 1 then connect the start and end together
	;thickness			:				Thickness of the line
	;
	;return				;				1 on success; 0 otherwise

	DrawLines(points,color,connect:=0,thickness:=1,rounded:=0) 
	{
		if (points.length < 2)
			return 0
		lx := sx := points[1][1]
		ly := sy := points[1][2]
		this.SetBrushColor(color)
		loop points.length - 1
		{
			x1 := lx
			y1 := ly
			x2 := lx := points[a_index+1][1]
			y2 := ly := points[a_index+1][2]
			this.renderTarget.DrawLine(D2D1_POINT_2F([x1, y1]), D2D1_POINT_2F([x2, y2]), this.brush, thickness, (rounded?this.strokeRounded:this.stroke))
			if(connect)
				this.renderTarget.DrawLine(D2D1_POINT_2F([sx, sy]), D2D1_POINT_2F([lx, ly]), this.brush, thickness, (rounded?this.strokeRounded:this.stroke))
		}
		return 1
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawPolygon
	;
	;points				:				An array of 2d points, example: [[0,0],[5,0],[0,5]]
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;thickness			:				Thickness of the line
	;xOffset			:				X offset to draw the polygon array
	;yOffset			:				Y offset to draw the polygon array
	;
	;return				;				1 on success; 0 otherwise

	DrawPolygon(points,color,thickness:=1,rounded:=0,xOffset:=0,yOffset:=0) 
	{
		if (points.length < 3)
			return 0
		pGeom := sink := 0
		pGeom := this.factory.CreatePathGeometry()
		sink := pGeom.Open()
		this.SetBrushColor(color)

		sink.BeginFigure(D2D1_POINT_2F([points[1][1]+xOffset, points[1][2]+yOffset]), 1)
		loop points.length - 1
			sink.AddLine(points[a_index+1][1]+xOffset, points[a_index+1][2]+yOffset)
		sink.EndFigure(D2D1_FIGURE_END_CLOSED := 1)
		sink.Close()
		this.renderTarget.DrawGeometry(pGeom, this.brush, thickness, (rounded?this.strokeRounded:this.stroke))

		return 1
	}
	
	
	;####################################################################################################################################################################################################################################
	;FillPolygon
	;
	;points				:				An array of 2d points, example: [[0,0],[5,0],[0,5]]
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;xOffset			:				X offset to draw the filled polygon array
	;yOffset			:				Y offset to draw the filled polygon array
	;
	;return				;				1 on success; 0 otherwise

	FillPolygon(points,color,xoffset:=0,yoffset:=0) 
	{
		if (points.length < 3)
			return 0
		pGeom := sink := 0
		pGeom := this.factory.CreatePathGeometry()
		sink := pGeom.Open()
		this.SetBrushColor(color)
		sink.SetFillMode(D2D1_FILL_MODE_WINDING := 1)
		sink.BeginFigure(D2D1_POINT_2F([points[1][1]+xOffset, points[1][2]+yOffset]), 0)
		loop points.length - 1
			sink.AddLine(points[a_index+1][1]+xOffset, points[a_index+1][2]+yOffset)
		sink.EndFigure(D2D1_FIGURE_END_CLOSED := 1)
		sink.Close()
		this.renderTarget.FillGeometry(pGeom, this.brush, 0)
		return 0
	}
	
	
	;####################################################################################################################################################################################################################################
	;SetPosition
	;
	;x					:				X position to move the window to (screen space)
	;y					:				Y position to move the window to (screen space)
	;w					:				New Width (only applies when not attached)
	;h					:				New Height (only applies when not attached)
	;
	;return				;				Void
	;
	;notes				:				Only used when not attached to a window
	
	SetPosition(x,y,w:=0,h:=0) 
	{
		this.x := x
		this.y := y
		if (!this.attachHWND and w != 0 and h != 0) 
		{
			this.renderTarget.Resize(D2D1_SIZE_U([this.width := w, this.height := h]))
		}
		DllCall("MoveWindow","Uptr",this.hwnd,"int",x,"int",y,"int",this.width,"int",this.height,"char",1)
	}
	
	
	;####################################################################################################################################################################################################################################
	;GetImageDimensions
	;
	;image				:				Image file name
	;&w					:				Width of image
	;&h					:				Height of image
	;
	;return				;				Void
	
	GetImageDimensions(image, &w, &h) 
	{
		local i
		i := (this.imageCache.Has(image) ? this.imageCache[image] : this.cacheImage(image))
		w := i["w"]
		h := i["h"]
	}
	
	
	;####################################################################################################################################################################################################################################
	;GetMousePos
	;
	;&x					:				X position of mouse to return
	;&y					:				Y position of mouse to return
	;realRegionOnly		:				Return 1 only if in the real region, which does not include the invisible borders, (client area does not have borders)
	;
	;return				;				Returns 1 if mouse within window/client region; 0 otherwise
	
	GetMousePos(&x, &y, realRegionOnly:=0) 
	{
		DllCall("GetCursorPos","ptr",this.tBufferPtr)
		x := NumGet(this.tBufferPtr,0,"int")
		y := NumGet(this.tBufferPtr,4,"int")
		if (!realRegionOnly) {
			inside := (x >= this.x and y >= this.y and x <= this.x2 and y <= this.y2)
			x += this.offX
			y += this.offY
			return inside
		}
		x += this.offX
		y += this.offY
		return (x >= this.realX and y >= this.realY and x <= this.realX2 and y <= this.realY2)
		
	}
	
	;####################################################################################################################################################################################################################################
	;Clear
	;
	;notes						:			Clears the overlay, essentially the same as running BegindDraw followed by EndDraw
	
	Clear() 
	{
		this.renderTarget.BeginDraw()
		this.renderTarget.Clear(this.clrPtr)
		this.renderTarget.EndDraw()
	}
	
	;########################################## 
	;  internal functions used by the class
	;########################################## 
	AdjustWindow(&x,&y,&w,&h) 
	{
		DllCall("GetWindowInfo","Uptr",(this.attachHWND ? this.attachHWND : this.hwnd),"ptr",this.tBufferPtr)
		pp := (this.attachClient ? 20 : 4)
		x1 := NumGet(this.tBufferPtr,pp,"int")
		y1 := NumGet(this.tBufferPtr,pp+4,"int")
		x2 := NumGet(this.tBufferPtr,pp+8,"int")
		y2 := NumGet(this.tBufferPtr,pp+12,"int")
		this.width := w := x2-x1
		this.height := h := y2-y1
		this.x := x := x1
		this.y := y := y1
		this.x2 := x + w
		this.y2 := y + h
		this.lastPos := (x1<<16)+y1
		this.lastSize := (w<<16)+h
		hBorders := (this.attachClient ? 0 : NumGet(this.tBufferPtr,48,"int"))
		vBorders := (this.attachClient ? 0 : NumGet(this.tBufferPtr,52,"int"))
		this.realX := hBorders
		this.realY := 0
		this.realWidth := w - (hBorders*2)
		this.realHeight := h - vBorders
		this.realX2 := this.realX + this.realWidth
		this.realY2 := this.realY + this.realHeight
		this.offX := -x1 ;- hBorders
		this.offY := -y1
	}
	SetIdentity(o:=0) 
	{
		NumPut("float", 1, this.matrixPtr, o+0)
		NumPut("float", 0, this.matrixPtr, o+4)
		NumPut("float", 0, this.matrixPtr, o+8)
		NumPut("float", 1, this.matrixPtr, o+12)
		NumPut("float", 0, this.matrixPtr, o+16)
		NumPut("float", 0, this.matrixPtr, o+20)
	}
	DrawTextShadow(p,text,x,y,w,h,color) 
	{
		this.SetBrushColor(color)
		this.renderTarget.DrawText(text, p, D2D1_RECT_F([x, y, x + w, y + h]), this.brush, 0, 0)
	}
	DrawTextOutline(p,text,x,y,w,h,color) 
	{
		static o := [[1,0],[1,1],[0,1],[-1,1],[-1,0],[-1,-1],[0,-1],[1,-1]]
		this.SetBrushColor(color)
		for k,v in o
			this.renderTarget.DrawText(text, p, D2D1_RECT_F([x + v[1], y + v[2], x + w + v[1], y + h + v[2]]), this.brush, 0, 0)
	}
	Err(str*) 
	{
		s := ""
		for k,v in str
			s .= (s = "" ? "" : "`n`n") v
		msgbox(s, "Problem!", 0x30 | 0x1000)
	}
	LoadLib(lib*) 
	{
		for k,v in lib
			if (!DllCall("GetModuleHandle", "str", v, "Ptr"))
				DllCall("LoadLibrary", "Str", v) 
	}
	SetBrushColor(col) 
	{
		if (col <= 0xFFFFFF)
			col += 0xFF000000
		if (col != this.lastCol) 
		{
			NumPut("Float",((col & 0xFF0000)>>16)/255,this.colPtr,0)
			NumPut("Float",((col & 0xFF00)>>8)/255,this.colPtr,4)
			NumPut("Float",((col & 0xFF))/255,this.colPtr,8)
			NumPut("Float",(col > 0xFFFFFF ? ((col & 0xFF000000)>>24)/255 : 1),this.colPtr,12)
			this.brush.SetColor(this.colPtr)
			this.lastCol := col
			return 1
		}
		return 0
	}
	vTable(a,p) 
	{
		return NumGet(NumGet(a+0,0,"ptr"),p*a_ptrsize,"Ptr")
	}
	_guid(guidStr,&clsid) 
	{
		clsid := buffer(16,0)
		DllCall("ole32\CLSIDFromString", "WStr", guidStr, "Ptr", clsid)
	}
	CacheImage(image) 
	{
		if (this.imageCache.has(image))
			return 1
		if (image = "") {
			this.Err("Error, expected resource image path but empty variable was supplied!")
			return 0
		}
		if (!FileExist(image)) {
			this.Err("Error finding resource image","'" image "' does not exist!")
			return 0
		}
		w := h := bm := bitmap := 0
		DllCall("gdiplus\GdipCreateBitmapFromFile", "Str", image, "Ptr*", &bm)
		DllCall("gdiplus\GdipGetImageWidth", "Ptr", bm, "Uint*", &w)
		DllCall("gdiplus\GdipGetImageHeight", "Ptr", bm, "Uint*", &h)
		r := buffer(16,0)
		NumPut("uint", w, r, 8)
		NumPut("uint", h, r, 12)
		bmdata := buffer(32,0)
		ret := DllCall("Gdiplus\GdipBitmapLockBits", "Ptr", bm, "Ptr", r, "uint", 3, "int", 0x26200A, "Ptr", bmdata)
		scan := NumGet(bmdata, 16, "Ptr")
		p := DllCall("GlobalAlloc", "uint", 0x40, "ptr", 16+((w*h)*4), "ptr")
		DllCall(this._cacheImage,"Ptr",p,"Ptr",scan,"int",w,"int",h,"uchar",255,"int")
		DllCall("Gdiplus\GdipBitmapUnlockBits", "Ptr", bm, "Ptr", bmdata)
		DllCall("gdiplus\GdipDisposeImage", "ptr", bm)
		props := D2D1_BITMAP_PROPERTIES([D2D1_PIXEL_FORMAT([28, 1]), 96 * 1, 96 * 1])
		bitmap := this.renderTarget.CreateBitmap(size := D2D1_SIZE_U([w, h]), p, 4 * w, props)
		return this.imageCache[image] := Map("p",bitmap, "w",w, "h",h)
	}
	CacheFont(name,size) 
	{
		return this.fonts[name size] := this.wFactory.CreateTextFormat(name, 0, 400, 0, 5, size, 'en-us')
	}
	__Delete() 
	{
		;DllCall("gdiplus\GdiplusShutdown", "Ptr*", this.gdiplusToken)
		;DllCall(this.vTable(this.factory,2),"ptr",this.factory)
		;DllCall(this.vTable(this.stroke,2),"ptr",this.stroke)
		;DllCall(this.vTable(this.strokeRounded,2),"ptr",this.strokeRounded)
		;DllCall(this.vTable(this.renderTarget,2),"ptr",this.renderTarget)
		;DllCall(this.vTable(this.brush,2),"ptr",this.brush)
		;DllCall(this.vTable(this.wfactory,2),"ptr",this.wfactory)
		;this.gui.destroy()
	}
	Mcode(str) 
	{
		local pp := 0, op := 0
		s := strsplit(str,"|")
		if (s.length != 2)
			return
		if (!DllCall("crypt32\CryptStringToBinary", "str", s[this.bits+1], "uint", 0, "uint", 1, "ptr", 0, "uint*", &pp, "ptr", 0, "ptr", 0))
			return
		p := DllCall("GlobalAlloc", "uint", 0, "ptr", pp, "ptr")
		if (this.bits)
			DllCall("VirtualProtect", "ptr", p, "ptr", pp, "uint", 0x40, "uint*", &op)
		if (DllCall("crypt32\CryptStringToBinary", "str", s[this.bits+1], "uint", 0, "uint", 1, "ptr", p, "uint*", &pp, "ptr", 0, "ptr", 0))
			return p
		DllCall("GlobalFree", "ptr", p)
	}
}
