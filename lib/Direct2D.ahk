/************************************************************************
 * @description Direct2D library, include d2d1.h and dwrite.h
 * @author thqby
 * @date 2023/07/27
 * @version 0.0.2
 ***********************************************************************/

#Include ./ctypes.ahk
#Requires AutoHotkey v2+

;; d2d1  https://docs.microsoft.com/zh-cn/windows/win32/api/d2d1/
class ID2D1Factory extends ID2DBase {
	static IID := '{06152247-6f50-465a-9245-118bfd3b6007}'
	__New(p := 0) {
		#DllLoad 'd2d1.dll'
		if (!p) {
			if DllCall('ole32\CLSIDFromString', 'str', '{06152247-6f50-465a-9245-118bfd3b6007}', 'ptr', buf := Buffer(16, 0))
				throw OSError()
			DllCall('d2d1\D2D1CreateFactory', 'uint', 0, 'ptr', buf, 'uint*', 0, 'ptr*', &pIFactory := 0, 'hresult')
			this.ptr := pIFactory
		} else this.ptr := p
	}

	; Forces the factory to refresh any system defaults that it might have changed since factory creation.
	; You should call this method before calling the GetDesktopDpi method, to ensure that the system DPI is current.
	ReloadSystemMetrics() {
		ComCall(3, this)
	}

	; Retrieves the current desktop dots per inch (DPI). To refresh this value, call ReloadSystemMetrics.
	; Use this method to obtain the system DPI when setting physical pixel values, such as when you specify the size of a window.
	; Example uses the GetDesktopDpi method to obtain the system DPI and set the initial size of a window. http://msdn.microsoft.com/en-us/library/windows/desktop/dd371316%28v=vs.85%29.aspx
	GetDesktopDpi(&dpiX, &dpiY) {
		ComCall(4, this, 'float*', &dpiX := 0, 'float*', &dpiY := 0, 'int')
	}

	; Creates an ID2D1RectangleGeometry.
	CreateRectangleGeometry(rectangle) {	; D2D1_RECT_F
		ComCall(5, this, 'ptr', rectangle, 'ptr*', &rectangleGeometry := 0)
		return ID2D1RectangleGeometry(rectangleGeometry)
	}

	; Creates an ID2D1RoundedRectangleGeometry.
	CreateRoundedRectangleGeometry(roundedRectangle) {	; D2D1_ROUNDED_RECT
		ComCall(6, this, 'ptr', roundedRectangle, 'ptr*', &roundedRectangleGeometry := 0)
		return ID2D1RoundedRectangleGeometry(roundedRectangleGeometry)
	}

	; Creates an ID2D1EllipseGeometry.
	; Example creates two ID2D1EllipseGeometry objects and combines them using the different geometry combine modes. http://msdn.microsoft.com/en-us/library/windows/desktop/dd371265%28v=vs.85%29.aspx
	CreateEllipseGeometry(ellipse) {	; D2D1_ELLIPSE
		ComCall(7, this, 'ptr', ellipse, 'ptr*', &ellipseGeometry := 0)
		return ID2D1EllipseGeometry(ellipseGeometry)
	}

	; Creates an ID2D1GeometryGroup, which is an object that holds other geometries.
	; Geometry groups are a convenient way to group several geometries simultaneously so all figures of several distinct geometries are concatenated into one. To create a ID2D1GeometryGroup object, call the CreateGeometryGroup method on the ID2D1Factory object, passing in the fillMode with possible values of D2D1_FILL_MODE_ALTERNATE (alternate) and D2D1_FILL_MODE_WINDING, an array of geometry objects to add to the geometry group, and the number of elements in this array.
	CreateGeometryGroup(fillMode, geometries, geometriesCount) {	; D2D1_FILL_MODE,ID2D1Geometry
		ComCall(8, this, 'int', fillMode, 'ptr', geometries, 'uint', geometriesCount, 'ptr*', &geometryGroup := 0)
		return ID2D1GeometryGroup(geometryGroup)
	}

	; Transforms the specified geometry and stores the result as an ID2D1TransformedGeometry object.
	; Like other resources, a transformed geometry inherits the resource space and threading policy of the factory that created it. This object is immutable.
	; When stroking a transformed geometry with the DrawGeometry method, the stroke width is not affected by the transform applied to the geometry. The stroke width is only affected by the world transform.
	; Example creates an ID2D1RectangleGeometry, then draws it without transforming it. It produces the output shown in the following illustration. http://msdn.microsoft.com/en-us/library/windows/desktop/dd371304%28v=vs.85%29.aspx
	CreateTransformedGeometry(sourceGeometry, transform) {	; ID2D1Geometry , D2D1_MATRIX_3X2_F
		ComCall(9, this, 'ptr', sourceGeometry, 'ptr', transform, 'ptr*', &transformedGeometry := 0)
		return ID2D1TransformedGeometry(transformedGeometry)
	}

	; Creates an empty ID2D1PathGeometry.
	CreatePathGeometry() {
		ComCall(10, this, 'ptr*', &pathGeometry := 0)
		return ID2D1PathGeometry(pathGeometry)
	}

	; Creates an ID2D1StrokeStyle that describes start cap, dash pattern, and other features of a stroke.
	; Example creates a stroke that uses a custom dash pattern. http://msdn.microsoft.com/en-us/library/windows/desktop/dd371298%28v=vs.85%29.aspx
	CreateStrokeStyle(strokeStyleProperties, dashes, dashesCount) {	; D2D1_STROKE_STYLE_PROPERTIES ,
		ComCall(11, this, 'ptr', strokeStyleProperties, 'ptr', dashes, 'uint', dashesCount, 'ptr*', &strokeStyle := 0)
		return ID2D1StrokeStyle(strokeStyle)
	}

	; Creates an ID2D1DrawingStateBlock that can be used with the SaveDrawingState and RestoreDrawingState methods of a render target.
	CreateDrawingStateBlock(drawingStateDescription, textRenderingParams) {	; D2D1_DRAWING_STATE_DESCRIPTION , IDWriteRenderingParams ,
		ComCall(12, this, 'ptr', drawingStateDescription, 'ptr', textRenderingParams, 'ptr*', &drawingStateBlock := 0)
		return ID2D1DrawingStateBlock(drawingStateBlock)
	}

	; Creates a render target that renders to a Microsoft Windows Imaging Component (WIC) bitmap.
	; You must use D2D1_FEATURE_LEVEL_DEFAULT for the minLevel member of the renderTargetProperties parameter with this method.
	; Your application should create render targets once and hold onto them for the life of the application or until the D2DERR_RECREATE_TARGET error is received. When you receive this error, you need to recreate the render target (and any resources it created).
	CreateWicBitmapRenderTarget(target, renderTargetProperties) {	; IWICBitmap , D2D1_RENDER_TARGET_PROPERTIES
		ComCall(13, this, 'ptr', target, 'ptr', renderTargetProperties, 'ptr*', &renderTarget := 0)
		return ID2D1RenderTarget(renderTarget)
	}

	; Creates an ID2D1HwndRenderTarget, a render target that renders to a window.
	; When you create a render target and hardware acceleration is available, you allocate resources on the computer's GPU. By creating a render target once and retaining it as long as possible, you gain performance benefits. Your application should create render targets once and hold onto them for the life of the application or until the D2DERR_RECREATE_TARGET error is received. When you receive this error, you need to recreate the render target (and any resources it created).
	CreateHwndRenderTarget(renderTargetProperties, hwndRenderTargetProperties) {	; D2D1_RENDER_TARGET_PROPERTIES , D2D1_HWND_RENDER_TARGET_PROPERTIES
		ComCall(14, this, 'ptr', renderTargetProperties, 'ptr', hwndRenderTargetProperties, 'ptr*', &hwndRenderTarget := 0)
		return ID2D1HwndRenderTarget(hwndRenderTarget)
	}

	; Creates a render target that draws to a DirectX Graphics Infrastructure (DXGI) surface.
	/*
	 * To write to a Direct3D surface, you obtain an IDXGISurface and pass it to the CreateDxgiSurfaceRenderTarget method to create a DXGI surface render target; you can then use the DXGI surface render target to draw 2-D content to the DXGI surface.
	 * A DXGI surface render target is a type of ID2D1RenderTarget. Like other Direct2D render targets, you can use it to create resources and issue drawing commands.
	 * The DXGI surface render target and the DXGI surface must use the same DXGI format. If you specify the DXGI_FORMAT_UNKOWN format when you create the render target, it will automatically use the surface's format.
	 * The DXGI surface render target does not perform DXGI surface synchronization.
	 * For more information about creating and using DXGI surface render targets, see the Direct2D and Direct3D Interoperability Overview.
	 * To work with Direct2D, the Direct3D device that provides the IDXGISurface must be created with the D3D10_CREATE_DEVICE_BGRA_SUPPORT flag.
	 * When you create a render target and hardware acceleration is available, you allocate resources on the computer's GPU. By creating a render target once and retaining it as long as possible, you gain performance benefits. Your application should create render targets once and hold onto them for the life of the application or until the render target's EndDraw method returns the D2DERR_RECREATE_TARGET error. When you receive this error, you need to recreate the render target (and any resources it created).
	*/
	; Example obtains a DXGI surface (pBackBuffer) from an IDXGISwapChain and uses it to create a DXGI surface render target. http://msdn.microsoft.com/en-us/library/windows/desktop/dd371264%28v=vs.85%29.aspx
	CreateDxgiSurfaceRenderTarget(dxgiSurface, renderTargetProperties) {	; IDXGISurface , D2D1_RENDER_TARGET_PROPERTIES
		ComCall(15, this, 'ptr', dxgiSurface, 'ptr', renderTargetProperties, 'ptr*', &renderTarget := 0)
		return ID2D1RenderTarget(renderTarget)
	}

	; Creates a render target that draws to a Windows Graphics Device Interface (GDI) device context.
	; Before you can render with a DC render target, you must use the render target's BindDC method to associate it with a GDI DC. Do this for each different DC and whenever there is a change in the size of the area you want to draw to.
	; To enable the DC render target to work with GDI, set the render target's DXGI format to DXGI_FORMAT_B8G8R8A8_UNORM and alpha mode to D2D1_ALPHA_MODE_PREMULTIPLIED or D2D1_ALPHA_MODE_IGNORE.
	; Your application should create render targets once and hold on to them for the life of the application or until the render target's EndDraw method returns the D2DERR_RECREATE_TARGET error. When you receive this error, recreate the render target (and any resources it created).
	; Example creates a DC render target. http://msdn.microsoft.com/en-us/library/windows/desktop/dd371248%28v=vs.85%29.aspx
	CreateDCRenderTarget(renderTargetProperties) {	; D2D1_RENDER_TARGET_PROPERTIES
		ComCall(16, this, 'ptr', renderTargetProperties, 'ptr*', &dcRenderTarget := 0)
		return ID2D1DCRenderTarget(dcRenderTarget)
	}
}
class ID2D1Resource extends ID2DBase {
	static IID := '{2cd90691-12e2-11dc-9fed-001143a055f9}'
	; Retrieves the factory associated with this resource.
	GetFactory() {
		ComCall(3, this, 'ptr*', &factory := 0, 'int')
		return ID2D1Factory(factory)
	}
}
class ID2D1RenderTarget extends ID2D1Resource {
	static IID := '{2cd90694-12e2-11dc-9fed-001143a055f9}'
	; Creates a Direct2D bitmap from a pointer to in-memory source data.
	CreateBitmap(size, srcData, pitch, bitmapProperties) {	; D2D1_SIZE_U , D2D1_BITMAP_PROPERTIES
		ComCall(4, this, 'int64', NumGet(size, 'int64'), 'ptr', srcData, 'uint', pitch, 'ptr', bitmapProperties, 'ptr*', &bitmap := 0)
		return ID2D1Bitmap(bitmap)
	}

	; Creates an ID2D1Bitmap by copying the specified Microsoft Windows Imaging Component (WIC) bitmap.
	; Before Direct2D can load a WIC image, it must be converted to a supported pixel format and alpha mode. For a list of supported pixel formats and alpha modes, see Supported Pixel Formats and Alpha Modes.
	CreateBitmapFromWicBitmap(wicBitmapSource, bitmapProperties) {	; IWICBitmapSource
		ComCall(5, this, 'ptr', wicBitmapSource, 'ptr', bitmapProperties, 'ptr*', &bitmap := 0)
		return ID2D1Bitmap(bitmap)
	}

	; Creates an ID2D1Bitmap whose data is shared with another resource.
	/*
	 * The CreateSharedBitmap method is useful for efficiently reusing bitmap data and can also be used to provide interoperability with Direct3D.
	 *
	 * Sharing an ID2D1Bitmap
	 * By passing an ID2D1Bitmap created by a render target that is resource-compatible, you can share a bitmap with that render target; both the original ID2D1Bitmap and the ID2D1Bitmap created by this method will point to the same bitmap data. For more information about when render target resources can be shared, see the Sharing Render Target Resources section of the Resources Overview.
	 * You may also use this method to reinterpret the data of an existing bitmap and specify a DPI or alpha mode. For example, in the case of a bitmap atlas, an ID2D1Bitmap may contain multiple sub-images, each of which should be rendered with a different D2D1_ALPHA_MODE (D2D1_ALPHA_MODE_PREMULTIPLIED or D2D1_ALPHA_MODE_IGNORE). You could use the CreateSharedBitmap method to reinterpret the bitmap using the desired alpha mode without having to load a separate copy of the bitmap into memory.
	 *
	 * Sharing an IDXGISurface
	 * When using a DXGI surface render target (an ID2D1RenderTarget object created by the CreateDxgiSurfaceRenderTarget method), you can pass an IDXGISurface surface to the CreateSharedBitmap method to share video memory with Direct3D and manipulate Direct3D content as an ID2D1Bitmap. As described in the Resources Overview, the render target and the IDXGISurface must be using the same Direct3D device.
	 * Note also that the IDXGISurface must use one of the supported pixel formats and alpha modes described in Supported Pixel Formats and Alpha Modes.
	 * For more information about interoperability with Direct3D, see the Direct2D and Direct3D Interoperability Overview.
	 *
	 * Sharing an IWICBitmapLock
	 * An IWICBitmapLock stores the content of a WIC bitmap and shields it from simultaneous accesses. By passing an IWICBitmapLock to the CreateSharedBitmap method, you can create an ID2D1Bitmap that points to the bitmap data already stored in the IWICBitmapLock.
	 * To use an IWICBitmapLock with the CreateSharedBitmap method, the render target must use software rendering. To force a render target to use software rendering, set to D2D1_RENDER_TARGET_TYPE_SOFTWARE the type field of the D2D1_RENDER_TARGET_PROPERTIES structure that you use to create the render target. To check whether an existing render target uses software rendering, use the IsSupported method.
	*/
	CreateSharedBitmap(riid, data, bitmapProperties) {	; D2D1_BITMAP_PROPERTIES
		ComCall(6, this, 'ptr', riid, 'ptr', data, 'ptr', bitmapProperties, 'ptr*', &bitmap := 0)
		return ID2D1Bitmap(bitmap)
	}

	; Creates an ID2D1BitmapBrush from the specified bitmap.
	CreateBitmapBrush(bitmap, bitmapBrushProperties := 0, brushProperties := 0) {	; ID2D1Bitmap , D2D1_BITMAP_BRUSH_PROPERTIES , D2D1_BRUSH_PROPERTIES
		ComCall(7, this, 'ptr', bitmap, 'ptr', bitmapBrushProperties, 'ptr', brushProperties, 'ptr*', &bitmapBrush := 0)
		return ID2D1BitmapBrush(bitmapBrush)
	}

	; Creates a ID2D1SolidColorBrush that has the specified color and opacity.
	CreateSolidColorBrush(color, brushProperties := 0) {	; D2D1_COLOR_F , D2D1_BRUSH_PROPERTIES
		ComCall(8, this, 'ptr', color, 'ptr', brushProperties, 'ptr*', &solidColorBrush := 0)
		return ID2D1SolidColorBrush(solidColorBrush)
	}

	; Creates an ID2D1GradientStopCollection from the specified gradient stops that uses the D2D1_GAMMA_2_2 color interpolation gamma and the clamp extend mode.
	CreateGradientStopCollection(gradientStops, gradientStopsCount, colorInterpolationGamma, extendMode) {	; D2D1_GRADIENT_STOP , D2D1_GAMMA , D2D1_EXTEND_MODE
		ComCall(9, this, 'ptr', gradientStops, 'uint', gradientStopsCount, 'uint', colorInterpolationGamma, 'uint', extendMode, 'ptr*', &gradientStopCollection := 0)
		return ID2D1GradientStopCollection(gradientStopCollection)
	}

	; Creates an ID2D1LinearGradientBrush that con the specified gradient stops and has the specified transform and base opacity.
	CreateLinearGradientBrush(linearGradientBrushProperties, brushProperties, gradientStopCollection) {	; D2D1_LINEAR_GRADIENT_BRUSH_PROPERTIES , D2D1_BRUSH_PROPERTIES , ID2D1GradientStopCollection
		ComCall(10, this, 'ptr', linearGradientBrushProperties, 'ptr', brushProperties, 'ptr', gradientStopCollection, 'ptr*', &linearGradientBrush := 0)
		return ID2D1LinearGradientBrush(linearGradientBrush)
	}

	; Creates an ID2D1RadialGradientBrush that con the specified gradient stops and has the specified transform and base opacity.
	CreateRadialGradientBrush(radialGradientBrushProperties, brushProperties, gradientStopCollection) {	; D2D1_RADIAL_GRADIENT_BRUSH_PROPERTIES , D2D1_BRUSH_PROPERTIES , ID2D1GradientStopCollection
		ComCall(11, this, 'ptr', radialGradientBrushProperties, 'ptr', brushProperties, 'ptr', gradientStopCollection, 'ptr*', &radialGradientBrush := 0)
		return ID2D1RadialGradientBrush(radialGradientBrush)
	}

	; Creates a bitmap render target for use during intermediate offscreen drawing that is compatible with the current render target.
	/*
	 * This method creates a render target that can be used for intermediate offscreen drawing. The intermediate render target is created in the same location (on the same adapter or in system memory) as the original render target, which allows efficient rendering of the intermediate results to the final target. The DPI, bit depth, pixel format (with the exception of alpha mode), and color space all default to those of the original render target.
	 * The pixel size and DPI of the render target can be modified by specifying values for desiredSize or desiredPixelSize:
	 * If desiredSize is specified but desiredPixelSize is not, the pixel size is computed from the desired size using the parent target DPI. If the desiredSize maps to a integer-pixel size, the DPI of the compatible render target is the same as the DPI of the parent target. If desiredSize maps to a fractional-pixel size, the pixel size is rounded up to the nearest integer and the DPI for the compatible render target is slightly higher than the DPI of the parent render target. In all cases, the coordinate (desiredSize.width, desiredSize.height) maps to the lower-right corner of the compatible render target.
	 * If the desiredPixelSize is specified and desiredSize is not, the DPI of the render target is the same as the original render target.
	 * If both desiredSize and desiredPixelSize are specified, the DPI of the render target is computed to account for the difference in scale.
	 * If neither desiredSize nor desiredPixelSize is specified, the render target size and DPI match the original render target.
	*/
	CreateCompatibleRenderTarget(desiredSize, desiredPixelSize, desiredFormat, options) {	; D2D1_SIZE_F , D2D1_SIZE_U , D2D1_PIXEL_FORMAT , D2D1_COMPATIBLE_RENDER_TARGET_OPTIONS
		ComCall(12, this, 'ptr', desiredSize, 'ptr', desiredPixelSize, 'ptr', desiredFormat, 'int', options, 'ptr*', &bitmapRenderTarget := 0)
		return ID2D1BitmapRenderTarget(bitmapRenderTarget)
	}

	; Creates a layer resource that can be used with this render target and its compatible render targets. The layer has the specified initial size.
	; Regardless of whether a size is initially specified, the layer automatically resizes as needed.
	; Example uses a layer to clip a bitmap to a geometric mask. http://msdn.microsoft.com/en-us/library/windows/desktop/dd371838%28v=vs.85%29.aspx
	CreateLayer(size) {	;D2D1_SIZE_F
		ComCall(13, this, 'ptr', size, 'ptr*', &layer := 0)
		return ID2D1Layer(layer)
	}

	; Create a mesh that uses triangles to describe a shape.
	; To populate a mesh, use its Open method to obtain an ID2D1TessellationSink. To draw the mesh, use the render target's FillMesh method.
	CreateMesh() {
		ComCall(14, this, 'ptr*', &mesh := 0)
		return ID2D1Mesh(mesh)
	}

	; When method fails, it does not return an error code. To determine whether a drawing method (such as DrawRectangle) failed, check the result returned by the ID2D1RenderTarget::EndDraw or ID2D1RenderTarget::Flush method.

	; Draws a line between the specified points using the specified stroke style.
	; Example uses the DrawLine method to create a grid that spans the width and height of the render target. The width and height information is provided by the rtSize variable.
	DrawLine(point0, point1, brush, strokeWidth, strokeStyle) {	; D2D1_POINT_2F, D2D1_POINT_2F, ID2D1Brush, ID2D1StrokeStyle
		ComCall(15, this, 'int64', NumGet(point0, 'int64'), 'int64', NumGet(point1, 'int64'), 'ptr', brush, 'float', strokeWidth, 'ptr', strokeStyle, 'int')
	}

	; Draws the outline of a rectangle that has the specified dimensions and stroke style.
	DrawRectangle(rect, brush, strokeWidth, strokeStyle) {	; D2D1_RECT_F , ID2D1Brush , ID2D1StrokeStyle
		ComCall(16, this, 'ptr', rect, 'ptr', brush, 'float', strokeWidth, 'ptr', strokeStyle, 'int')
	}

	; Paints the interior of the specified rectangle.
	FillRectangle(rect, brush) {	; D2D1_RECT_F , ID2D1Brush
		ComCall(17, this, 'ptr', rect, 'ptr', brush, 'int')
	}

	; Draws the outline of the specified rounded rectangle using the specified stroke style.
	DrawRoundedRectangle(roundedRect, brush, strokeWidth, strokeStyle) {	; D2D1_ROUNDED_RECT , ID2D1Brush , ID2D1StrokeStyle
		ComCall(18, this, 'ptr', roundedRect, 'ptr', brush, 'float', strokeWidth, 'ptr', strokeStyle, 'int')
	}

	; Paints the interior of the specified rounded rectangle.
	; Example uses the DrawRoundedRectangle and FillRoundedRectangle methods to outline and fill a rounded rectangle. This example produces the output shown in the following illustration. http://msdn.microsoft.com/en-us/library/windows/desktop/dd371959%28v=vs.85%29.aspx
	FillRoundedRectangle(roundedRect, brush) {	; D2D1_ROUNDED_RECT , ID2D1Brush
		ComCall(19, this, 'ptr', roundedRect, 'ptr', brush, 'int')
	}

	; Draws the outline of the specified ellipse using the specified stroke style.
	DrawEllipse(ellipse, brush, strokeWidth, strokeStyle) {	; D2D1_ELLIPSE , ID2D1Brush , ID2D1StrokeStyle
		ComCall(20, this, 'ptr', ellipse, 'ptr', brush, 'float', strokeWidth, 'ptr', strokeStyle, 'int')
	}

	; Paints the interior of the specified ellipse.
	FillEllipse(ellipse, brush) {	; D2D1_ELLIPSE , ID2D1Brush
		ComCall(21, this, 'ptr', ellipse, 'ptr', brush, 'int')
	}

	; Draws the outline of the specified geometry using the specified stroke style.
	DrawGeometry(geometry, brush, strokeWidth, strokeStyle) {	; ID2D1Geometry , ID2D1Brush , ID2D1StrokeStyle
		ComCall(22, this, 'ptr', geometry, 'ptr', brush, 'float', strokeWidth, 'ptr', strokeStyle, 'int')
	}

	; Paints the interior of the specified geometry.
	; If the opacityBrush parameter is not NULL, the alpha value of each pixel of the mapped opacityBrush is used to determine the resulting opacity of each corresponding pixel of the geometry. Only the alpha value of each color in the brush is used for this processing; all other color information is ignored. The alpha value specified by the brush is multiplied by the alpha value of the geometry after the geometry has been painted by brush.
	FillGeometry(geometry, brush, opacityBrush := 0) {	; ID2D1Geometry , ID2D1Brush
		ComCall(23, this, 'ptr', geometry, 'ptr', brush, 'ptr', opacityBrush, 'int')
	}

	; Paints the interior of the specified mesh.
	; The current antialias mode of the render target must be D2D1_ANTIALIAS_MODE_ALIASED when FillMesh is called. To change the render target's antialias mode, use the SetAntialiasMode method.
	; FillMesh does not expect a particular winding order for the triangles in the ID2D1Mesh; both clockwise and counter-clockwise will work.
	FillMesh(mesh, brush) {	; ID2D1Mesh , ID2D1Brush
		ComCall(24, this, 'ptr', mesh, 'ptr', brush, 'int')
	}

	; Applies the opacity mask described by the specified bitmap to a brush and uses that brush to paint a region of the render target.
	; For this method to work properly, the render target must be using the D2D1_ANTIALIAS_MODE_ALIASED antialiasing mode. You can set the antialiasing mode by calling the ID2D1RenderTarget::SetAntialiasMode method.
	FillOpacityMask(opacityMask, brush, content, destinationRectangle := 0, sourceRectangle := 0) {	; ID2D1Bitmap , ID2D1Brush , D2D1_OPACITY_MASK_CONTENT , D2D1_RECT_F
		ComCall(25, this, 'ptr', opacityMask, 'ptr', brush, 'int', content, 'ptr', destinationRectangle, 'ptr', sourceRectangle, 'int')
	}

	; Draws the specified bitmap after scaling it to the size of the specified rectangle.
	DrawBitmap(bitmap, destinationRectangle := 0, opacity := 1, interpolationMode := 1, sourceRectangle := 0) {	; ID2D1Bitmap , D2D1_RECT_F , D2D1_BITMAP_INTERPOLATION_MODE , D2D1_RECT_F
		ComCall(26, this, 'ptr', bitmap, 'ptr', destinationRectangle, 'float', opacity, 'uint', interpolationMode, 'ptr', sourceRectangle, 'int')
	}

	; Draws the specified text using the format information provided by an IDWriteTextFormat object.
	; To create an IDWriteTextFormat object, create an IDWriteFactory and call its CreateTextFormat method.
	DrawText(string, textFormat, layoutRect, defaultForegroundBrush, options := 0, measuringMode := 0) {	; IDWriteTextFormat , D2D1_RECT_F , ID2D1Brush , D2D1_DRAW_TEXT_OPTIONS , DWRITE_MEASURING_MODE
		ComCall(27, this, 'str', string, 'uint', StrLen(string), 'ptr', textFormat, 'ptr', layoutRect, 'ptr', defaultForegroundBrush, 'int', options, 'int', measuringMode, 'int')
	}

	; Draws the formatted text described by the specified IDWriteTextLayout object.
	; When drawing the same text repeatedly, using the DrawTextLayout method is more efficient than using the DrawText method because the text doesn't need to be formatted and the layout processed with each call.
	DrawTextLayout(origin, textLayout, defaultForegroundBrush, options := 0) {	; D2D1_POINT_2F , IDWriteTextLayout , ID2D1Brush , D2D1_DRAW_TEXT_OPTIONS
		ComCall(28, this, 'int64', NumGet(origin, 'int64'), 'ptr', textLayout, 'ptr', defaultForegroundBrush, 'uint', options, 'int')
	}

	; Draws the specified glyphs.
	DrawGlyphRun(baselineOrigin, glyphRun, foregroundBrush, measuringMode := 0) {	; D2D1_POINT_2F , DWRITE_GLYPH_RUN , ID2D1Brush , DWRITE_MEASURING_MODE
		ComCall(29, this, 'int64', NumGet(baselineOrigin, 'int64'), 'ptr', glyphRun, 'ptr', foregroundBrush, 'int', measuringMode, 'int')
	}

	; Applies the specified transform to the render target, replacing the existing transformation. All subsequent drawing operations occur in the transformed space.
	; Example uses the SetTransform method to apply a rotation to the render target. http://msdn.microsoft.com/en-us/library/windows/desktop/dd316901%28v=vs.85%29.aspx
	SetTransform(transform) {	; D2D1_MATRIX_3X2_F
		ComCall(30, this, 'ptr', transform, 'int')
	}

	; Gets the current transform of the render target.
	GetTransform() {	; D2D1_MATRIX_3X2_F
		ComCall(31, this, 'ptr*', &transform := 0, 'int')
		return transform
	}

	; Sets the antialiasing mode of the render target. The antialiasing mode applies to all subsequent drawing operations, excluding text and glyph drawing operations.
	; To specify the antialiasing mode for text and glyph operations, use the SetTextAntialiasMode method.
	SetAntialiasMode(antialiasMode) {	; D2D1_ANTIALIAS_MODE
		ComCall(32, this, 'uint', antialiasMode, 'int')
	}

	; Retrieves the current antialiasing mode for nontext drawing operations.
	GetAntialiasMode() {
		ComCall(33, this, 'int')	; D2D1_ANTIALIAS_MODE
	}

	; Specifies the antialiasing mode to use for subsequent text and glyph drawing operations.
	SetTextAntialiasMode(textAntialiasMode) {	; D2D1_TEXT_ANTIALIAS_MODE
		ComCall(34, this, 'uint', textAntialiasMode, 'int')
	}

	; Gets the current antialiasing mode for text and glyph drawing operations.
	GetTextAntialiasMode() {
		ComCall(35, this, 'int')	; D2D1_TEXT_ANTIALIAS_MODE
	}

	; If the settings specified by textRenderingParams are incompatible with the render target's text antialiasing mode (specified by SetTextAntialiasMode), subsequent text and glyph drawing operations will fail and put the render target into an error state.

	; Specifies text rendering options to be applied to all subsequent text and glyph drawing operations.
	SetTextRenderingParams(textRenderingParams := 0) {	; IDWriteRenderingParams
		ComCall(36, this, 'ptr', textRenderingParams, 'int')
	}

	; Retrieves the render target's current text rendering options.
	GetTextRenderingParams() {
		ComCall(37, this, 'ptr*', &textRenderingParams := 0, 'int')
		return IDWriteRenderingParams(textRenderingParams)
	}

	; Specifies a label for subsequent drawing operations.
	; The labels specified by this method are printed by debug error messages. If no tag is set, the default value for each tag is 0.
	SetTags(tag1, tag2) {	; D2D1_TAG
		ComCall(38, this, 'uint64', tag1, 'uint64', tag2, 'int')
	}

	; Gets the label for subsequent drawing operations.
	; If the same address is passed for both parameters, both parameters receive the value of the second tag.
	GetTags(&tag1, &tag2) {
		ComCall(39, this, 'uint64*', &tag1 := 0, 'uint64*', &tag2 := 0, 'int')
	}

	; Adds the specified layer to the render target so that it receives all subsequent drawing operations until PopLayer is called.
	; The PushLayer method allows a caller to begin redirecting rendering to a layer. All rendering operations are valid in a layer. The location of the layer is affected by the world transform set on the render target.
	; Each PushLayer must have a matching PopLayer call. If there are more PopLayer calls than PushLayer calls, the render target is placed into an error state. If Flush is called before all outstanding layers are popped, the render target is placed into an error state, and an error is returned. The error state can be cleared by a call to EndDraw.
	; A particular ID2D1Layer resource can be active only at one time. In other words, you cannot call a PushLayer method, and then immediately follow with another PushLayer method with the same layer resource. Instead, you must call the second PushLayer method with different layer resources.
	PushLayer(layerParameters, layer) {	; D2D1_LAYER_PARAMETERS , ID2D1Layer
		ComCall(40, this, 'ptr', layerParameters, 'ptr', layer, 'int')
	}

	; Stops redirecting drawing operations to the layer that is specified by the last PushLayer call.
	; A PopLayer must match a previous PushLayer call.
	; Example uses a layer to clip a bitmap to a geometric mask. http://msdn.microsoft.com/en-us/library/windows/desktop/dd316852%28v=vs.85%29.aspx
	PopLayer() {
		ComCall(41, this, 'int')
	}

	; Executes all pending drawing commands.
	; If the method succeeds, it returns S_OK. Otherwise, it returns an HRESULT error code and sets tag1 and tag2 to the tags that were active when the error occurred. If no error occurred, this method sets the error tag state to be (0,0).
	Flush(&tag1 := 0, &tag2 := 0) {
		ComCall(42, this, 'uint64*', &tag1 := 0, 'uint64*', &tag2 := 0)
	}

	; Saves the current drawing state to the specified ID2D1DrawingStateBlock.
	SaveDrawingState(drawingStateBlock) {	; ID2D1DrawingStateBlock
		ComCall(43, this, 'ptr', drawingStateBlock, 'int')
	}

	; Sets the render target's drawing state to that of the specified ID2D1DrawingStateBlock.
	RestoreDrawingState(drawingStateBlock) {	; ID2D1DrawingStateBlock
		ComCall(44, this, 'ptr', drawingStateBlock, 'int')
	}

	; A PushAxisAlignedClip/PopAxisAlignedClip pair can occur around or within a PushLayer/PopLayer pair, but may not overlap. For example, a PushAxisAlignedClip, PushLayer, PopLayer, PopAxisAlignedClip sequence is valid, but a PushAxisAlignedClip, PushLayer, PopAxisAlignedClip, PopLayer sequence is not.
	; PopAxisAlignedClip must be called once for every call to PushAxisAlignedClip.
	; This method doesn't return an error code if it fails. To determine whether a drawing operation (such as PopAxisAlignedClip) failed, check the result returned by the ID2D1RenderTarget::EndDraw or ID2D1RenderTarget::Flush methods.

	; Specifies a rectangle to which all subsequent drawing operations are clipped.
	; The clipRect is transformed by the current world transform set on the render target. After the transform is applied to the clipRect that is passed in, the axis-aligned bounding box for the clipRect is computed. For efficiency, the contents are clipped to this axis-aligned bounding box and not to the original clipRect that is passed in.
	; More Remarks, http://msdn.microsoft.com/en-us/library/windows/desktop/dd316856%28v=vs.85%29.aspx
	PushAxisAlignedClip(clipRect, antialiasMode) {	; D2D1_RECT_F , D2D1_ANTIALIAS_MODE
		ComCall(45, this, 'ptr', clipRect, 'uint', antialiasMode, 'int')
	}

	; Removes the last axis-aligned clip from the render target. After this method is called, the clip is no longer applied to subsequent drawing operations.
	; More Remarks, http://msdn.microsoft.com/en-us/library/windows/desktop/dd316850%28v=vs.85%29.aspx
	PopAxisAlignedClip() {
		ComCall(46, this, 'int')
	}

	; Clears the drawing area to the specified color.
	; Direct2D interprets the clearColor as straight alpha (not premultiplied). If the render target's alpha mode is D2D1_ALPHA_MODE_IGNORE, the alpha channel of clearColor is ignored and replaced with 1.0f (fully opaque).
	; If the render target has an active clip (specified by PushAxisAlignedClip), the clear command is applied only to the area within the clip region.
	Clear(clearColor := 0) {	; D2D1_COLOR_F
		ComCall(47, this, 'ptr', clearColor, 'int')
	}

	/*
	 * Drawing operations can only be issued between a BeginDraw and EndDraw call.
	 * BeginDraw and EndDraw are used to indicate that a render target is in use by the Direct2D system. Different implementations of ID2D1RenderTarget might behave differently when BeginDraw is called. An ID2D1BitmapRenderTarget may be locked between BeginDraw/EndDraw calls, a DXGI surface render target might be acquired on BeginDraw and released on EndDraw, while an ID2D1HwndRenderTarget may begin batching at BeginDraw and may present on EndDraw, for example.
	 * The BeginDraw method must be called before rendering operations can be called, though state-setting and state-retrieval operations can be performed even outside of BeginDraw/EndDraw.
	 * After BeginDraw is called, a render target will normally build up a batch of rendering commands, but defer processing of these commands until either an internal buffer is full, the Flush method is called, or until EndDraw is called. The EndDraw method causes any batched drawing operations to complete, and then returns an HRESULT indicating the success of the operations and, optionally, the tag state of the render target at the time the error occurred. The EndDraw method always succeeds: it should not be called twice even if a previous EndDraw resulted in a failing HRESULT.
	 * If EndDraw is called without a matched call to BeginDraw, it returns an error indicating that BeginDraw must be called before EndDraw. Calling BeginDraw twice on a render target puts the target into an error state where nothing further is drawn, and returns an appropriate HRESULT and error information when EndDraw is called.
	*/

	; Initiates drawing on this render target.
	BeginDraw() {
		ComCall(48, this, 'int')
	}

	; Ends drawing operations on the render target and indicates the current error state and associated tags.
	EndDraw(&tag1 := 0, &tag2 := 0) {
		ComCall(49, this, 'uint64*', &tag1 := 0, 'uint64*', &tag2 := 0)
	}

	; Retrieves the pixel format and alpha mode of the render target.
	GetPixelFormat() {
		ComCall(50, this, 'ptr', format := D2D1_PIXEL_FORMAT(), 'int')
		return format
	}

	; This method specifies the mapping from pixel space to device-independent space for the render target. If both dpiX and dpiY are 0, the factory-read system DPI is chosen. If one parameter is zero and the other unspecified, the DPI is not changed.
	; For ID2D1HwndRenderTarget, the DPI defaults to the most recently factory-read system DPI. The default value for all other render targets is 96 DPI.

	; Sets the dots per inch (DPI) of the render target.
	SetDpi(dpiX, dpiY) {
		ComCall(51, this, 'float', dpiX, 'float', dpiY, 'int')
	}

	; Return the render target's dots per inch (DPI).
	GetDpi(&dpiX, &dpiY) {
		ComCall(52, this, 'float*', &dpiX := 0, 'float*', &dpiY := 0, 'int')
	}

	; Returns the size of the render target in device-independent pixels.
	GetSize() {
		ComCall(53, this, 'ptr', b := Buffer(8), 'int')
		return { width: NumGet(b, 'float'), height: NumGet(b, 4, 'float') }
	}

	; Returns the size of the render target in device pixels.
	GetPixelSize() {
		ComCall(54, this, 'int64*', &a := 0, 'int')
		return { width: a & 0xfffffff, height: a >> 32 }	; uint x,uint y
	}

	; Gets the maximum size, in device-dependent units (pixels), of any one bitmap dimension supported by the render target.
	; This method returns the maximum texture size of the Direct3D device.
	; Note  The software renderer and WARP devices return the value of 16 megapixels (16*1024*1024). You can create a Direct2D texture that is this size, but not a Direct3D texture that is this size.
	GetMaximumBitmapSize() {
		return ComCall(55, this, 'uint')
	}

	; Indicates whether the render target supports the specified properties.
	; This method does not evaluate the DPI settings specified by the renderTargetProperties parameter.
	IsSupported(renderTargetProperties) {	; D2D1_RENDER_TARGET_PROPERTIES
		return ComCall(56, this, 'ptr', renderTargetProperties, 'int')
	}
}
class ID2D1BitmapRenderTarget extends ID2D1RenderTarget {
	static IID := '{2cd90695-12e2-11dc-9fed-001143a055f9}'
	; Retrieves the bitmap for this render target. The returned bitmap can be used for drawing operations.
	; The DPI for the ID2D1Bitmap obtained from GetBitmap will be the DPI of the ID2D1BitmapRenderTarget when the render target was created. Changing the DPI of the ID2D1BitmapRenderTarget by calling SetDpi doesn't affect the DPI of the bitmap, even if SetDpi is called before GetBitmap. Using SetDpi to change the DPI of the ID2D1BitmapRenderTarget does affect how contents are rendered into the bitmap: it just doesn't affect the DPI of the bitmap retrieved by GetBitmap.
	; Example uses the CreateCompatibleRenderTarget method to create an ID2D1BitmapRenderTarget and uses it to draw a grid pattern. The grid pattern is used as the source of an ID2D1BitmapBrush. http://msdn.microsoft.com/en-us/library/windows/desktop/dd371150%28v=vs.85%29.aspx
	GetBitmap() {
		ComCall(57, this, 'ptr*', &bitmap := 0)
		return ID2D1Bitmap(bitmap)
	}
}
class ID2D1HwndRenderTarget extends ID2D1RenderTarget {
	static IID := '{2cd90698-12e2-11dc-9fed-001143a055f9}'
	; Indicates whether the HWND associated with this render target is occluded.
	; Note  If the window was occluded the last time that EndDraw was called, the next time that the render target calls CheckWindowState, it will return D2D1_WINDOW_STATE_OCCLUDED regardless of the current window state. If you want to use CheckWindowState to determine the current window state, you should call CheckWindowState after every EndDraw call and ignore its return value. This call will ensure that your next call to CheckWindowState state will return the actual window state.
	CheckWindowState() {
		return ComCall(57, this, 'int')	; D2D1_WINDOW_STATE
	}

	; Changes the size of the render target to the specified pixel size.
	; After this method is called, the contents of the render target's back-buffer are not defined, even if the D2D1_PRESENT_OPTIONS_RETAIN_CONTENTS option was specified when the render target was created.
	Resize(pixelSize) {	; D2D1_SIZE_U
		ComCall(58, this, 'ptr', pixelSize)
	}

	; Returns the HWND associated with this render target.
	GetHwnd() {
		return ComCall(59, this, 'ptr')
	}
}
class ID2D1Image extends ID2D1Resource {
	IID := '{65019f75-8da2-497c-b32c-dfa34e48ede6}'
}
class ID2D1DCRenderTarget extends ID2D1RenderTarget {
	static IID := '{1c51bc64-de61-46fd-9899-63a5d8f03950}'
	; Binds the render target to the device context to which it issues drawing commands.
	; Before you can render with the DC render target, you must use its BindDC method to associate it with a GDI DC. You do this each time you use a different DC, or the size of the area you want to draw to changes.
	; Example binds a DC to the ID2D1DCRenderTarget. http://msdn.microsoft.com/en-us/library/windows/desktop/dd371214%28v=vs.85%29.aspx
	BindDC(hDC, pSubRect) {	; RECT
		ComCall(57, this, 'ptr', hDC, 'ptr', pSubRect)
	}
}
class ID2D1Brush extends ID2D1Resource {
	static IID := '{2cd906a8-12e2-11dc-9fed-001143a055f9}'
	; Sets the degree of opacity of this brush.
	SetOpacity(opacity) {	; range 0–1
		ComCall(4, this, 'float', opacity, 'int')
	}

	; Sets the transformation applied to the brush.
	SetTransform(transform) {	; D2D1_MATRIX_3X2_F
		ComCall(5, this, 'ptr', transform, 'int')
	}

	; Gets the degree of opacity of this brush.
	GetOpacity() {
		return ComCall(6, this, 'float')
	}

	; Gets the transform applied to this brush.
	GetTransform() {
		ComCall(7, this, 'ptr', transform := D2D1_MATRIX_3X2_F(), 'int')
		return transform
	}
}
class ID2D1BitmapBrush extends ID2D1Brush {
	static IID := '{2cd906aa-12e2-11dc-9fed-001143a055f9}'
	; Sometimes, the bitmap for a bitmap brush doesn't completely fill the area being painted. When this happens, Direct2D uses the brush's horizontal (SetExtendModeX) and vertical (SetExtendModeY) extend mode settings to determine how to fill the remaining area.
	; More Remarks, http://msdn.microsoft.com/en-us/library/windows/desktop/dd371139%28v=vs.85%29.aspx

	; Specifies how the brush horizontally tiles those areas that extend past its bitmap.
	SetExtendModeX(extendModeX) {	; D2D1_EXTEND_MODE
		ComCall(8, this, 'int', extendModeX, 'int')
	}

	; Specifies how the brush vertically tiles those areas that extend past its bitmap.
	SetExtendModeY(extendModeY) {
		ComCall(9, this, 'int', extendModeY, 'int')
	}

	; Specifies the interpolation mode used when the brush bitmap is scaled or rotated.
	; This method sets the interpolation mode for a bitmap, which is an enum value that is specified in the D2D1_BITMAP_INTERPOLATION_MODE enumeration type. D2D1_BITMAP_INTERPOLATION_MODE_NEAREST_NEIGHBOR represents nearest neighbor filtering. It looks up the nearest bitmap pixel to the current rendering pixel and chooses its exact color. D2D1_BITMAP_INTERPOLATION_MODE_LINEAR represents linear filtering, and interpolates a color from the four nearest bitmap pixels.
	; The interpolation mode of a bitmap also affects subpixel translations. In a subpixel translation, bilinear interpolation positions the bitmap more precisely to the application requests, but blurs the bitmap in the process.
	SetInterpolationMode(interpolationMode) {	; D2D1_BITMAP_INTERPOLATION_MODE
		ComCall(10, this, 'int', interpolationMode, 'int')
	}

	; Specifies the bitmap source that this brush uses to paint.
	; This method specifies the bitmap source that this brush uses to paint. The bitmap is not resized or rescaled automatically to fit the geometry that it fills. The bitmap stays at its native size. To resize or translate the bitmap, use the SetTransform method to apply a transform to the brush.
	; The native size of a bitmap is the width and height in bitmap pixels, divided by the bitmap DPI. This native size forms the base tile of the brush. To tile a subregion of the bitmap, you must generate a bitmap containing this subregion and use SetBitmap to apply it to the brush.
	SetBitmap(bitmap) {	; ID2D1Bitmap
		ComCall(11, this, 'ptr', bitmap, 'int')
	}

	; Like all brushes, ID2D1BitmapBrush defines an infinite plane of content. Because bitmaps are finite, it relies on an extend mode to determine how the plane is filled horizontally and vertically.

	; Gets the method by which the brush horizontally tiles those areas that extend past its bitmap.
	GetExtendModeX() {
		return ComCall(12, this, 'int')	; D2D1_EXTEND_MODE
	}

	; Gets the method by which the brush vertically tiles those areas that extend past its bitmap.
	GetExtendModeY() {
		return ComCall(13, this, 'int')	; D2D1_EXTEND_MODE
	}

	; Gets the interpolation method used when the brush bitmap is scaled or rotated.
	GetInterpolationMode() {
		return DllCall(this.vt(A_PtrSize), 'ptr', this.ptr, 'int')	; D2D1_BITMAP_INTERPOLATION_MODE
	}

	; Gets the bitmap source that this brush uses to paint.
	GetBitmap() {
		ComCall(15, this, 'ptr*', &bitmap := 0, 'int')
		return ID2D1Bitmap(bitmap)
	}
}
class ID2D1SolidColorBrush extends ID2D1Brush {
	static IID := '{2cd906a9-12e2-11dc-9fed-001143a055f9}'
	; Specifies the color of this solid color brush.
	; To help create colors, Direct2D provides the ColorF class. It offers several helper methods for creating colors and provides a set or predefined colors.
	SetColor(color) {	; D2D1_COLOR_F
		return ComCall(8, this, 'ptr', color, 'int')
	}

	; err
	; Retrieves the color of the solid color brush.
	GetColor() {
		ComCall(9, this, 'ptr', color := D2D1_COLOR_F(), 'int')
		return color
	}
}
class ID2D1LinearGradientBrush extends ID2D1Brush {
	static IID := '{2cd906ab-12e2-11dc-9fed-001143a055f9}'
	; The start point and end point are described in the brush's space and are mapped to the render target when the brush is used. If there is a non-identity brush transform or render target transform, the brush's start point and end point are also transformed.

	; Sets the starting coordinates of the linear gradient in the brush's coordinate space.
	SetStartPoint(startPoint) {	; D2D1_POINT_2F
		return ComCall(8, this, 'ptr', startPoint, 'int')
	}

	; Sets the ending coordinates of the linear gradient in the brush's coordinate space.
	SetEndPoint(endPoint) {	; D2D1_POINT_2F
		return ComCall(9, this, 'ptr', endPoint, 'int')
	}

	; Retrieves the starting coordinates of the linear gradient.
	GetStartPoint() {
		ComCall(10, this, 'ptr', point := D2D1_POINT_2F(), 'int')
		return point
	}

	; Retrieves the ending coordinates of the linear gradient.
	GetEndPoint() {
		ComCall(11, this, 'ptr', point := D2D1_POINT_2F(), 'int')
		return point
	}

	; Retrieves the ID2D1GradientStopCollection associated with this linear gradient brush.
	; ID2D1GradientStopCollection con an array of D2D1_GRADIENT_STOP structures and information, such as the extend mode and the color interpolation mode.
	GetGradientStopCollection() {
		ComCall(12, this, 'ptr*', &gradientStopCollection := 0, 'int')
		return ID2D1GradientStopCollection(gradientStopCollection)
	}
}
class ID2D1RadialGradientBrush extends ID2D1Brush {
	IID := '{2cd906ac-12e2-11dc-9fed-001143a055f9}'
	; Specifies the center of the gradient ellipse in the brush's coordinate space.
	SetCenter(center) {	; D2D1_POINT_2F
		return ComCall(8, this, 'ptr', center, 'int')
	}

	; Specifies the offset of the gradient origin relative to the gradient ellipse's center.
	SetGradientOriginOffset(gradientOriginOffset) {	; D2D1_POINT_2F
		return ComCall(9, this, 'ptr', gradientOriginOffset, 'int')
	}

	; Specifies the x-radius of the gradient ellipse, in the brush's coordinate space.
	SetRadiusX(radiusX) {
		return ComCall(10, this, 'float', radiusX, 'int')
	}

	; Specifies the y-radius of the gradient ellipse, in the brush's coordinate space.
	SetRadiusY(radiusY) {
		return ComCall(11, this, 'float', radiusY, 'int')
	}

	; Retrieves the center of the gradient ellipse.
	GetCenter() {
		ComCall(12, this, 'ptr', point := D2D1_POINT_2F(), 'int')
		return point
	}

	; Retrieves the offset of the gradient origin relative to the gradient ellipse's center.
	GetGradientOriginOffset() {
		ComCall(13, this, 'ptr', point := D2D1_POINT_2F(), 'int')
		return point
	}

	; Retrieves the x-radius of the gradient ellipse.
	GetRadiusX() {
		return ComCall(14, this, 'float')
	}

	; Retrieves the y-radius of the gradient ellipse.
	GetRadiusY() {
		return ComCall(15, this, 'float')
	}

	; Retrieves the ID2D1GradientStopCollection associated with this radial gradient brush object.
	; ID2D1GradientStopCollection con an array of D2D1_GRADIENT_STOP structures and additional information, such as the extend mode and the color interpolation mode.
	GetGradientStopCollection() {
		ComCall(16, this, 'ptr*', &gradientStopCollection := 0, 'int')
		return ID2D1GradientStopCollection(gradientStopCollection)
	}
}
class ID2D1GdiInteropRenderTarget extends ID2DBase {
	static IID := '{e0db51c3-6f77-4bae-b3d5-e47509b35838}'
	GetDC(mode) {
		ComCall(3, this, 'int', mode, 'ptr*', &hdc := 0)
		return hdc
	}
	ReleaseDC(update) {	; RECT_U
		ComCall(4, this, 'ptr', update)
	}
}
class ID2D1Geometry extends ID2D1Resource {
	static IID := '{2cd906a1-12e2-11dc-9fed-001143a055f9}'
	; Retrieves the bounds of the geometry.
	GetBounds(worldTransform := 0) {	; D2D1_MATRIX_3X2_F
		bounds := D2D1_RECT_F()
		ComCall(4, this, 'ptr', worldTransform, 'ptr', bounds)
		return bounds
	}

	; Gets the bounds of the geometry after it has been widened by the specified stroke width and style and transformed by the specified matrix.
	GetWidenedBounds(strokeWidth, strokeStyle, worldTransform, flatteningTolerance) {	; float, ID2D1StrokeStyle , D2D1_MATRIX_3X2_F, float
		bounds := D2D1_RECT_F()
		ComCall(5, this, 'float', strokeWidth, 'ptr', strokeStyle, 'ptr', worldTransform, 'float', flatteningTolerance, 'ptr', bounds)
		return bounds
	}

	; Determines whether the geometry's stroke con the specified point given the specified stroke thickness, style, and transform.
	StrokeContainsPoint(point, strokeWidth, strokeStyle, worldTransform, flatteningTolerance) {	; D2D1_POINT_2F, float, ID2D1StrokeStyle , D2D1_MATRIX_3X2_F, float
		ComCall(6, this, 'int64', NumGet(point, 'int64'), 'float', strokeWidth, 'ptr', strokeStyle, 'ptr', worldTransform, 'float', flatteningTolerance, 'int*', &con := 0)
		return con
	}

	; Indicates whether the area filled by the geometry would contain the specified point given the specified flattening tolerance.
	FillContainsPoint(point, worldTransform, flatteningTolerance) {	; D2D1_POINT_2F , D2D1_MATRIX_3X2_F, float
		ComCall(7, this, 'int64', NumGet(point, 'int64'), 'ptr', worldTransform, 'float', flatteningTolerance, 'int*', &con := 0)
		return con
	}

	; Describes the intersection between this geometry and the specified geometry. The comparison is performed by using the specified flattening tolerance.
	; When interpreting the returned relation value, it is important to remember that the member D2D1_GEOMETRY_RELATION_IS_CONTAINED of the D2D1_GEOMETRY_RELATION enumeration type means that this geometry is contained inside inputGeometry, not that this geometry con inputGeometry.
	CompareWithGeometry(inputGeometry, inputGeometryTransform, flatteningTolerance) {	; ID2D1Geometry , D2D1_MATRIX_3X2_F ,
		ComCall(8, this, 'ptr', inputGeometry, 'ptr', inputGeometryTransform, 'float', flatteningTolerance, 'int*', &relation := 0)
		return relation	; D2D1_GEOMETRY_RELATION
	}

	; Creates a simplified version of the geometry that con only lines and (optionally) cubic Bezier curves and writes the result to an ID2D1SimplifiedGeometrySink.
	Simplify(simplificationOption, worldTransform, flatteningTolerance) {	; D2D1_GEOMETRY_SIMPLIFICATION_OPTION , D2D1_MATRIX_3X2_F
		ComCall(9, this, 'int', simplificationOption, 'ptr', worldTransform, 'float', flatteningTolerance, 'ptr*', &geometrySink := 0)
		return ID2D1SimplifiedGeometrySink(geometrySink)
	}

	; Creates a set of clockwise-wound triangles that cover the geometry after it has been transformed using the specified matrix and flattened using the specified tolerance.
	Tessellate(worldTransform, flatteningTolerance) {	; D2D1_MATRIX_3X2_F
		ComCall(10, this, 'ptr', worldTransform, 'float', flatteningTolerance, 'ptr*', &tessellationSink := 0)
		return ID2D1TessellationSink(tessellationSink)
	}

	; Combines this geometry with the specified geometry and stores the result in an ID2D1SimplifiedGeometrySink.
	; Example uses each of the different combine modes to combine two ID2D1EllipseGeometry objects. http://msdn.microsoft.com/en-us/library/windows/desktop/dd316617%28v=vs.85%29.aspx
	CombineWithGeometry(inputGeometry, combineMode, inputGeometryTransform, flatteningTolerance, geometrySink) {	; ID2D1Geometry , D2D1_COMBINE_MODE , D2D1_MATRIX_3X2_F , ID2D1SimplifiedGeometrySink
		ComCall(11, this, 'ptr', inputGeometry, 'int', combineMode, 'ptr', inputGeometryTransform, 'float', flatteningTolerance, 'ptr', geometrySink)
	}

	; Computes the outline of the geometry and writes the result to an ID2D1SimplifiedGeometrySink.
	/*
	 * The Outline method allows the caller to produce a geometry with an equivalent fill to the input geometry, with the following additional properties:
	 * The output geometry con no transverse intersections; that is, segments may touch, but they never cross.
	 * The outermost figures in the output geometry are all oriented counterclockwise.
	 * The output geometry is fill-mode invariant; that is, the fill of the geometry does not depend on the choice of the fill mode. For more information about the fill mode, see D2D1_FILL_MODE.
	 * Additionally, the Outline method can be useful in removing redundant portions of said geometries to simplify complex geometries. It can also be useful in combination with ID2D1GeometryGroup to create unions among several geometries simultaneously.
	*/
	Outline(worldTransform, flatteningTolerance) {	; D2D1_MATRIX_3X2_F
		ComCall(12, this, 'ptr', worldTransform, 'float', flatteningTolerance, 'ptr*', &geometrySink := 0)
		return ID2D1SimplifiedGeometrySink(geometrySink)
	}

	; Computes the area of the geometry after it has been transformed by the specified matrix and flattened using the specified tolerance.
	ComputeArea(worldTransform, flatteningTolerance) {	; D2D1_MATRIX_3X2_F
		ComCall(13, this, 'ptr', worldTransform, 'float', flatteningTolerance, 'float*', &area := 0)
		return area
	}

	; Calculates the length of the geometry as though each segment were unrolled into a line.
	ComputeLength(worldTransform, flatteningTolerance) {	; D2D1_MATRIX_3X2_F
		ComCall(14, this, 'ptr', worldTransform, 'float', flatteningTolerance, 'float*', &length := 0)
		return length
	}

	; Calculates the point and tangent vector at the specified distance along the geometry after it has been transformed by the specified matrix and flattened using the specified tolerance.
	ComputePointAtLength(length, worldTransform, flatteningTolerance) {	; D2D1_MATRIX_3X2_F
		point := D2D1_POINT_2F()
		unitTangentVector := D2D1_POINT_2F()
		ComCall(15, this, 'float', length, 'ptr', worldTransform, 'float', flatteningTolerance, 'ptr', point, 'ptr', unitTangentVector)
		return [point, unitTangentVector]	; D2D1_POINT_2F
	}

	; Widens the geometry by the specified stroke and writes the result to an ID2D1SimplifiedGeometrySink after it has been transformed by the specified matrix and flattened using the specified tolerance.
	Widen(strokeWidth, strokeStyle, worldTransform, flatteningTolerance, geometrySink) {	; ID2D1StrokeStyle , D2D1_MATRIX_3X2_F
		ComCall(16, this, 'float', strokeWidth, 'ptr', strokeStyle, 'ptr', worldTransform, 'float', flatteningTolerance, 'ptr', geometrySink)
	}
}
class ID2D1RectangleGeometry extends ID2D1Geometry {
	static IID := '{2cd906a2-12e2-11dc-9fed-001143a055f9}'
	; Retrieves the rectangle that describes the rectangle geometry's dimensions.
	GetRect() {
		rect := D2D1_RECT_F()
		ComCall(17, this, 'ptr', rect, 'int')
		return rect
	}
}
class ID2D1RoundedRectangleGeometry extends ID2D1Geometry {
	static IID := '{2cd906a3-12e2-11dc-9fed-001143a055f9}'
	; Retrieves a rounded rectangle that describes this rounded rectangle geometry.
	GetRoundedRect() {
		roundedRect := D2D1_ROUNDED_RECT()
		ComCall(17, this, 'ptr', roundedRect, 'int')
		return roundedRect
	}
}
class ID2D1EllipseGeometry extends ID2D1Geometry {
	static IID := '{2cd906a4-12e2-11dc-9fed-001143a055f9}'
	; Gets the D2D1_ELLIPSE structure that describes this ellipse geometry.
	GetEllipse() {
		ellipse := D2D1_ELLIPSE()
		ComCall(17, this, 'ptr', ellipse, 'int')
		return ellipse
	}
}
class ID2D1GeometryGroup extends ID2D1Geometry {
	static IID := '{2cd906a6-12e2-11dc-9fed-001143a055f9}'
	; Indicates how the intersecting areas of the geometries contained in this geometry group are combined.
	GetFillMode() {
		return ComCall(17, this, 'int')	; D2D1_FILL_MODE
	}

	; Indicates the number of geometry objects in the geometry group.
	GetSourceGeometryCount() {
		return ComCall(18, this, 'uint')
	}

	; Retrieves the geometries in the geometry group.
	GetSourceGeometries(geometriesCount) {
		ComCall(19, this, 'ptr*', &geometries := 0, 'uint', geometriesCount, 'int')
		return ID2D1Geometry(geometries)
	}
}
class ID2D1TransformedGeometry extends ID2D1Geometry {
	static IID := '{2cd906bb-12e2-11dc-9fed-001143a055f9}'
	; Retrieves the source geometry of this transformed geometry object.
	GetSourceGeometry() {
		ComCall(17, this, 'ptr*', &sourceGeometry := 0, 'int')
		return ID2D1Geometry(sourceGeometry)
	}

	; Retrieves the matrix used to transform the ID2D1TransformedGeometry object's source geometry.
	GetTransform() {
		transform := D2D1_MATRIX_3X2_F()
		ComCall(18, this, 'ptr', transform, 'int')
		return transform
	}
}
class ID2D1PathGeometry extends ID2D1Geometry {
	static IID := '{2cd906a5-12e2-11dc-9fed-001143a055f9}'
	; Retrieves the geometry sink that is used to populate the path geometry with figures and segments.
	; Because path geometries are immutable and can only be populated once, it is an error to call Open on a path geometry more than once.
	; Note that the fill mode defaults to D2D1_FILL_MODE_ALTERNATE. To set the fill mode, call SetFillMode before the first call to BeginFigure. Failure to do so will put the geometry sink in an error state.
	; Example creates an ID2D1PathGeometry, retrieves a sink, and uses the sink to define an hourglass shape. http://msdn.microsoft.com/en-us/library/windows/desktop/dd371522%28v=vs.85%29.aspx
	Open() {
		ComCall(17, this, 'ptr*', &geometrySink := 0)
		return ID2D1GeometrySink(geometrySink)
	}

	; Copies the contents of the path geometry to the specified ID2D1GeometrySink.
	Stream(geometrySink) {	; ID2D1GeometrySink
		ComCall(18, this, 'ptr', geometrySink)
	}

	; Retrieves the number of segments in the path geometry.
	GetSegmentCount() {
		ComCall(19, this, 'uint*', &count := 0)
		return count
	}

	; Retrieves the number of figures in the path geometry.
	GetFigureCount() {
		ComCall(20, this, 'uint*', &count := 0)
		return count
	}
}
class ID2D1Bitmap extends ID2D1Resource {
	static IID := '{a2296057-ea42-4099-983b-539fb6505426}'
	; Returns the size, in device-independent pixels (DIPs), of the bitmap.
	; A DIP is 1/96 of an inch. To retrieve the size in device pixels, use the ID2D1Bitmap::GetPixelSize method.
	GetSize() {
		ComCall(4, this, 'ptr', b := Buffer(8), 'int')
		return { width: NumGet(b, 'float'), height: NumGet(b, 4, 'float') }
	}

	; Returns the size, in device-dependent units (pixels), of the bitmap.
	GetPixelSize() {
		ComCall(5, this, 'int64*', &a := 0, 'int')
		return { width: a & 0xfffffff, height: (a >> 32) & 0xfffffff }
	}

	; Retrieves the pixel format and alpha mode of the bitmap.
	GetPixelFormat() {
		return ComCall(6, this, 'int')	; D2D1_PIXEL_FORMAT
	}

	; Return the dots per inch (DPI) of the bitmap.
	GetDpi() {
		ComCall(7, this, 'float*', &dpiX := 0, 'float*', &dpiY := 0, 'int')
		return [dpiX, dpiY]
	}

	; This method does not update the size of the current bitmap. If the contents of the source bitmap do not fit in the current bitmap, this method fails. Also, note that this method does not perform format conversion, and will fail if the bitmap formats do not match.
	; Calling this method may cause the current batch to flush if the bitmap is active in the batch. If the batch that was flushed does not complete successfully, this method fails. However, this method does not clear the error state of the render target on which the batch was flushed. The failing HRESULT and tag state will be returned at the next call to EndDraw or Flush.

	; Copies the specified region from the specified bitmap into the current bitmap.
	CopyFromBitmap(destPoint, bitmap, srcRect := 0) {	; D2D1_POINT_2U , ID2D1Bitmap , D2D1_RECT_U
		ComCall(8, this, 'ptr', destPoint, 'ptr', bitmap, 'ptr', srcRect)
	}

	; Copies the specified region from the specified render target into the current bitmap.
	; All clips and layers must be popped off of the render target before calling this method. The method returns D2DERR_RENDER_TARGET_HAS_LAYER_OR_CLIPRECT if any clips or layers are currently applied to the render target.
	CopyFromRenderTarget(destPoint, renderTarget, srcRect := 0) {	; D2D1_POINT_2U , ID2D1RenderTarget , D2D1_RECT_U
		ComCall(9, this, 'ptr', destPoint, 'ptr', renderTarget, 'ptr', srcRect)
	}

	; Copies the specified region from memory into the current bitmap.
	; The stride, or pitch, of the source bitmap stored in srcData. The stride is the byte count of a scanline (one row of pixels in memory). The stride can be computed from the following formula: pixel width * bytes per pixel + memory padding.
	CopyFromMemory(dstRect, srcData, pitch) {	; D2D1_RECT_U
		ComCall(10, this, 'ptr', dstRect, 'ptr', srcData, 'uint', pitch)
	}
}
class ID2D1GradientStopCollection extends ID2D1Resource {
	static IID := '{2cd906a7-12e2-11dc-9fed-001143a055f9}'
	; Retrieves the number of gradient stops in the collection.
	GetGradientStopCount() {
		return ComCall(4, this, 'uint')
	}

	; Copies the gradient stops from the collection into an array of D2D1_GRADIENT_STOP structures.
	; Gradient stops are copied in order of position, starting with the gradient stop with the smallest position value and progressing to the gradient stop with the largest position value.
	GetGradientStops(gradientStopsCount) {
		gradientStops := ctypes.array(D2D1_GRADIENT_STOP, gradientStopsCount)()
		ComCall(5, this, 'ptr', gradientStops, 'uint', gradientStopsCount, 'int')
		return gradientStops	; D2D1_GRADIENT_STOP
	}

	; Indicates the gamma space in which the gradient stops are interpolated.
	GetColorInterpolationGamma() {
		return ComCall(6, this, 'int')	; D2D1_GAMMA
	}

	; Indicates the behavior of the gradient outside the normalized gradient range.
	GetExtendMode() {
		return ComCall(7, this, 'int')	; D2D1_EXTEND_MODE
	}
}
class ID2D1StrokeStyle extends ID2D1Resource {
	static IID := '{2cd9069d-12e2-11dc-9fed-001143a055f9}'
	; Retrieves the type of shape used at the beginning of a stroke.
	GetStartCap() {
		return ComCall(4, this, 'int')	; D2D1_CAP_STYLE
	}

	; Retrieves the type of shape used at the end of a stroke.
	GetEndCap() {
		return ComCall(5, this, 'int')	; D2D1_CAP_STYLE
	}

	; Gets a value that specifies how the ends of each dash are drawn.
	GetDashCap() {
		return ComCall(6, this, 'int')	; D2D1_CAP_STYLE
	}

	; Retrieves the limit on the ratio of the miter length to half the stroke's thickness.
	GetMiterLimit() {
		return ComCall(7, this, 'float')
	}

	; Retrieves the type of joint used at the vertices of a shape's outline.
	GetLineJoin() {
		return ComCall(8, this, 'int')	; D2D1_LINE_JOIN
	}

	; Retrieves a value that specifies how far in the dash sequence the stroke will start.
	GetDashOffset() {
		return ComCall(9, this, 'float')
	}

	; Gets a value that describes the stroke's dash pattern.
	; If a custom dash style is specified, the dash pattern is described by the dashes array, which can be retrieved by calling the GetDashes method.
	GetDashStyle() {
		return ComCall(10, this, 'int')	; D2D1_DASH_STYLE
	}

	; Retrieves the number of entries in the dashes array.
	GetDashesCount() {
		return ComCall(11, this, 'uint')
	}

	; Copies the dash pattern to the specified array.
	; The dashes are specified in units that are a multiple of the stroke width, with subsequent members of the array indicating the dashes and gaps between dashes: the first entry indicates a filled dash, the second a gap, and so on.
	GetDashes(dashesCount) {
		dashes := ctypes.array('float', dashesCount)()
		ComCall(12, this, 'ptr', dashes, 'uint', dashesCount, 'int')
		return dashes
	}
}
class ID2D1Mesh extends ID2D1Resource {
	static IID := '{2cd906c2-12e2-11dc-9fed-001143a055f9}'
	; Opens the mesh for population.
	Open() {
		ComCall(4, this, 'ptr*', &tessellationSink := 0)
		return ID2D1TessellationSink(tessellationSink)
	}
}
class ID2D1Layer extends ID2D1Resource {
	static IID := '{2cd9069b-12e2-11dc-9fed-001143a055f9}'
	; Gets the size of the layer in device-independent pixels.
	GetSize() {
		if ComCall(4, this, 'ptr', b := Buffer(8), 'ptr')
			return { width: NumGet(b, 'float'), height: NumGet(b, 4, 'float') }
	}
}
class ID2D1DrawingStateBlock extends ID2D1Resource {
	static IID := '{28506e39-ebf6-46a1-bb47-fd85565ab957}'
	; Retrieves the antialiasing mode, transform, and tags portion of the drawing state.
	GetDescription() {
		stateDescription := D2D1_DRAWING_STATE_DESCRIPTION()
		ComCall(4, this, 'ptr', stateDescription, 'int')
		return stateDescription
	}

	; Specifies the antialiasing mode, transform, and tags portion of the drawing state.
	SetDescription(stateDescription) {	; D2D1_DRAWING_STATE_DESCRIPTION
		ComCall(5, this, 'ptr', stateDescription, 'int')
	}

	; Specifies the text-rendering configuration of the drawing state.
	SetTextRenderingParams(textRenderingParams := 0) {	; IDWriteRenderingParams
		ComCall(6, this, 'ptr', textRenderingParams, 'int')
	}

	; Retrieves the text-rendering configuration of the drawing state.
	GetTextRenderingParams() {
		ComCall(7, this, 'ptr*', &textRenderingParams := 0, 'int')
		return IDWriteRenderingParams(textRenderingParams)
	}
}
class ID2D1SimplifiedGeometrySink extends ID2DBase {
	static IID := '{2cd9069e-12e2-11dc-9fed-001143a055f9}'
	; Specifies the method used to determine which points are inside the geometry described by this geometry sink and which points are outside.
	; The fill mode defaults to D2D1_FILL_MODE_ALTERNATE. To set the fill mode, call SetFillMode before the first call to BeginFigure. Not doing will put the geometry sink in an error state.
	SetFillMode(fillMode) {
		ComCall(3, this, 'int', fillMode, 'int')
	}

	; Specifies stroke and join options to be applied to segments added to the geometry sink.
	SetSegmentFlags(vertexFlags) {	; D2D1_PATH_SEGMENT
		ComCall(4, this, 'int', vertexFlags, 'int')
	}

	; Starts a figure at the specified point.
	; If this method is called while a figure is currently in progress, the interface is invalidated and all future methods will fail.
	BeginFigure(startPoint, figureBegin) {
		ComCall(5, this, 'int64', NumGet(startPoint, 'int64'), 'int', figureBegin, 'int')
	}

	; Creates a sequence of lines using the specified points and adds them to the geometry sink.
	AddLines(points, pointsCount) {	; D2D1_POINT_2F*
		ComCall(6, this, 'ptr', points, 'uint', pointsCount, 'int')
	}

	; Creates a sequence of cubic Bezier curves and adds them to the geometry sink.
	AddBeziers(beziers, beziersCount) {	; D2D1_BEZIER_SEGMENT*
		ComCall(7, this, 'ptr', beziers, 'uint', beziersCount, 'int')
	}

	; Ends the current figure; optionally, closes it.
	EndFigure(figureEnd) {
		ComCall(8, this, 'uint', figureEnd, 'int')
	}

	; Closes the geometry sink, indicates whether it is in an error state, and resets the sink's error state.
	Close() {
		ComCall(9, this)
	}
}
class ID2D1GeometrySink extends ID2D1SimplifiedGeometrySink {
	static IID := '{2cd9069f-12e2-11dc-9fed-001143a055f9}'
	; Creates a line segment between the current point and the specified end point and adds it to the geometry sink.
	; Example creates an ID2D1PathGeometry, retrieves a sink, and uses it to define an hourglass shape. http://msdn.microsoft.com/en-us/library/windows/desktop/dd316604%28v=vs.85%29.aspx
	AddLine(x, y) {	; D2D1_POINT_2F
		;ComCall(10, this, 'float', point0, 'float', point1, 'int')

		bf := Buffer(64)
		NumPut("float", x, bf, 0)
		NumPut("float", y, bf, 4)
		ComCall(10, this, 'int64', NumGet(bf, 'int64'))
	}

	; Creates a cubic Bezier curve between the current point and the specified endpoint.
	AddBezier(bezier) {	; D2D1_BEZIER_SEGMENT
		ComCall(11, this, 'ptr', bezier, 'int')
	}

	; Creates a quadratic Bezier curve between the current point and the specified endpoint.
	AddQuadraticBezier(bezier) {	; D2D1_QUADRATIC_BEZIER_SEGMENT
		ComCall(12, this, 'ptr', bezier, 'int')
	}

	; Adds a sequence of quadratic Bezier segments as an array in a single call.
	AddQuadraticBeziers(beziers, beziersCount) {	; D2D1_QUADRATIC_BEZIER_SEGMENT
		ComCall(13, this, 'ptr', beziers, 'uint', beziersCount, 'int')
	}

	; Adds a single arc to the path geometry.
	AddArc(arc) {	; D2D1_ARC_SEGMENT
		ComCall(14, this, 'ptr', arc, 'int')
	}
}
class ID2D1TessellationSink extends ID2DBase {
	static IID := '{2cd906c1-12e2-11dc-9fed-001143a055f9}'
	; Copies the specified triangles to the sink.
	AddTriangles(triangles, trianglesCount) {	; D2D1_TRIANGLE*
		ComCall(3, this, 'ptr', triangles, 'uint', trianglesCount, 'int')
	}

	; Closes the sink and returns its error status.
	Close() {
		ComCall(4, this)
	}
}

;; dwrite  https://docs.microsoft.com/zh-cn/windows/win32/api/dwrite/
class IDWriteFactory extends ID2DBase {
	static IID := '{b859ee5a-d838-4b5b-a2e8-1adc7d93db48}'
	__New(p := 0) {
		#DllLoad 'dwrite.dll'
		if (!p) {
			if DllCall('ole32\CLSIDFromString', 'str', '{b859ee5a-d838-4b5b-a2e8-1adc7d93db48}', 'ptr', buf := Buffer(16, 0))
				throw OSError()
			DllCall('dwrite\DWriteCreateFactory', 'uint', 0, 'ptr', buf, 'ptr*', &pIFactory := 0, 'hresult')
			this.ptr := pIFactory
		} else this.ptr := p
	}
	GetSystemFontCollection(checkForUpdates := false) {
		ComCall(3, this, 'ptr*', &fontCollection := 0, 'int', checkForUpdates)
		return IDWriteFontCollection(fontCollection)
	}
	CreateCustomFontCollection(collectionLoader, collectionKey, collectionKeySize) {
		ComCall(4, this, 'ptr', collectionLoader, 'ptr', collectionKey, 'uint', collectionKeySize, 'ptr*', &fontCollection := 0)
		return IDWriteFontCollection(fontCollection)
	}
	RegisterFontCollectionLoader(fontCollectionLoader) {
		ComCall(5, this, 'ptr', fontCollectionLoader)
	}
	UnregisterFontCollectionLoader(fontCollectionLoader) {
		ComCall(6, this, 'ptr', fontCollectionLoader)
	}
	CreateFontFileReference(filePath, lastWriteTime) {
		ComCall(7, this, 'wstr', filePath, 'ptr', lastWriteTime, 'ptr*', &fontFile := 0)
		return IDWriteFontFile(fontFile)
	}
	CreateCustomFontFileReference(fontFileReferenceKey, fontFileReferenceKeySize, fontFileLoader) {
		ComCall(8, this, 'ptr', fontFileReferenceKey, 'uint', fontFileReferenceKeySize, 'ptr', fontFileLoader, 'ptr*', &fontFile := 0)
		return IDWriteFontFile(fontFile)
	}
	CreateFontFace(fontFaceType, numberOfFiles, fontFiles, faceIndex, fontFaceSimulationFlags) {	; DWRITE_FONT_FACE_TYPE
		ComCall(9, this, 'int', fontFaceType, 'uint', numberOfFiles, 'ptr', fontFiles, 'uint', faceIndex, 'int', fontFaceSimulationFlags, 'ptr*', &fontFace := 0)
		return IDWriteFontFace(fontFace)
	}
	CreateRenderingParams() {
		ComCall(10, this, 'ptr*', &renderingParams := 0)
		return IDWriteRenderingParams(renderingParams)
	}
	CreateMonitorRenderingParams(monitor) {	; HMONITOR
		ComCall(11, this, 'ptr', monitor, 'ptr*', &renderingParams := 0)
		return IDWriteRenderingParams(renderingParams)
	}
	CreateCustomRenderingParams(gamma, enhancedContrast, clearTypeLevel, pixelGeometry, renderingMode) {	; float, float, float, DWRITE_PIXEL_GEOMETRY, DWRITE_RENDERING_MODE
		ComCall(12, this, 'float', gamma, 'float', enhancedContrast, 'float', clearTypeLevel, 'int', pixelGeometry, 'int', renderingMode, 'ptr*', &renderingParams := 0)
		return IDWriteRenderingParams(renderingParams)
	}
	RegisterFontFileLoader(fontFileLoader) {	; IDWriteFontFileLoader
		ComCall(13, this, 'ptr', fontFileLoader)
	}
	UnregisterFontFileLoader(fontFileLoader) {	; IDWriteFontFileLoader
		ComCall(14, this, 'ptr', fontFileLoader)
	}
	CreateTextFormat(fontFamilyName, fontCollection, fontWeight, fontStyle, fontStretch, fontSize, localeName) {	; wstr, IDWriteFontCollection, DWRITE_FONT_WEIGHT, DWRITE_FONT_STYLE, DWRITE_FONT_STRETCH, float, wstr
		ComCall(15, this, 'wstr', fontFamilyName, 'ptr', fontCollection, 'int', fontWeight, 'int', fontStyle, 'int', fontStretch, 'float', fontSize, 'wstr', localeName, 'ptr*', &textFormat := 0)
		return IDWriteTextFormat(textFormat)
	}
	CreateTypography() {
		ComCall(16, this, 'ptr*', &typography := 0)
	}
	GetGdiInterop() {
		ComCall(17, this, 'ptr*', &gdiInterop := 0)
	}
	CreateTextLayout(string, textFormat, maxWidth := 0, maxHeight := 0) {	; wstr, uint, IDWriteTextFormat, float, float
		ComCall(18, this, 'wstr', string, 'uint', StrLen(string), 'ptr', textFormat, 'float', maxWidth, 'float', maxHeight, 'ptr*', &textLayout := 0)
		return IDWriteTextLayout(textLayout)
	}
	CreateGdiCompatibleTextLayout(string, textFormat, layoutWidth, layoutHeight, pixelsPerDip, transform, useGdiNatural) {
		ComCall(19, this, 'wstr', string, 'uint', StrLen(string), 'ptr', textFormat, 'float', layoutWidth, 'float', layoutHeight, 'float', pixelsPerDip, 'ptr', transform, 'int', useGdiNatural, 'ptr*', &textLayout := 0)
		return IDWriteTextLayout(textLayout)
	}
	CreateEllipsisTrimmingSign(textFormat) {
		ComCall(20, this, 'ptr', textFormat, 'ptr*', &trimmingSign := 0)
		return IDWriteInlineObject(trimmingSign)
	}
	CreateTextAnalyzer() {
		ComCall(21, this, 'ptr*', &textAnalyzer := 0)
		return IDWriteTextAnalyzer(textAnalyzer)
	}
	CreateNumberSubstitution(substitutionMethod, localeName, ignoreUserOverride) {	; DWRITE_NUMBER_SUBSTITUTION_METHOD
		ComCall(22, this, 'int', substitutionMethod, 'wstr', localeName, 'int', ignoreUserOverride, 'ptr*', &numberSubstitution := 0)
		return IDWriteNumberSubstitution(numberSubstitution)
	}
	CreateGlyphRunAnalysis(glyphRun, pixelsPerDip, transform, renderingMode, measuringMode, baselineOriginX, baselineOriginY) {	; DWRITE_GLYPH_RUN
		ComCall(23, this, 'ptr', glyphRun, 'float', pixelsPerDip, 'ptr', transform, 'int', renderingMode, 'int', measuringMode, 'float', baselineOriginX, 'float', baselineOriginY, 'ptr*', &glyphRunAnalysis := 0)
		return IDWriteGlyphRunAnalysis(glyphRunAnalysis)
	}
}
class IDWriteBitmapRenderTarget extends ID2DBase {
	static IID := '{5e5a32a3-8dff-4773-9ff6-0696eab77267}'
	DrawGlyphRun(baselineOriginX, baselineOriginY, measuringMode, glyphRun, renderingParams, textColor, &blackBoxRect := 0) {
		ComCall(3, this, 'float', baselineOriginX, 'float', baselineOriginY, 'int', measuringMode, 'ptr', glyphRun, 'ptr', renderingParams, 'uint', textColor, 'ptr', &blackBoxRect)
	}
	GetMemoryDC() => ComCall(4, this, 'ptr')
	GetPixelsPerDip() => ComCall(5, this, 'float')
	SetPixelsPerDip(pixelsPerDip) {
		ComCall(6, this, 'float', pixelsPerDip)
	}
	GetCurrentTransform() {
		ComCall(7, this, 'ptr', transform := DWRITE_MATRIX())
		return transform
	}
	SetCurrentTransform(transform) {
		ComCall(8, this, 'ptr', transform)
	}
	GetSize() {
		ComCall(9, this, 'ptr', size := Buffer(8))
		return { cx: NumGet(size, 'int'), cy: NumGet(size, 4, 'int') }
	}
	Resize(width, height) {
		ComCall(10, this, 'uint', width, 'uint', height)
	}
}
class IDWriteFontFileLoader extends ID2DBase {
	static IID := '{727cad4e-d6af-4c9e-8a08-d695b11caa49}'
	CreateStreamFromKey(fontFileReferenceKey, fontFileReferenceKeySize) {
		ComCall(3, this, 'ptr', fontFileReferenceKey, 'uint', fontFileReferenceKeySize, 'ptr*', &fontFileStream := 0)
		return IDWriteFontFileStream(fontFileStream)
	}
}
class IDWriteLocalFontFileLoader extends IDWriteFontFileLoader {
	static IID := '{b2d9f3ec-c9fe-4a11-a2ec-d86208f7c0a2}'
	GetFilePathLengthFromKey(fontFileReferenceKey, fontFileReferenceKeySize) {
		ComCall(4, this, 'ptr', fontFileReferenceKey, 'uint', fontFileReferenceKeySize, 'uint*', &filePathLength := 0)
		return filePathLength
	}
	GetFilePathFromKey(fontFileReferenceKey, fontFileReferenceKeySize) {
		VarSetStrCapacity(&filePath, filePathSize := this.GetFilePathLengthFromKey(fontFileReferenceKey, fontFileReferenceKeySize) * 2)
		ComCall(5, this, 'ptr', fontFileReferenceKey, 'uint', fontFileReferenceKeySize, 'wstr*', &filePath, 'uint', filePathSize)
		return filePath
	}
	GetLastWriteTimeFromKey(fontFileReferenceKey, fontFileReferenceKeySize) {
		ComCall(6, this, 'ptr', fontFileReferenceKey, 'uint', fontFileReferenceKeySize, 'ptr', lastWriteTime := Buffer(8))
		return { dwLowDateTime: NumGet(lastWriteTime, 'uint'), dwHighDateTime: NumGet(lastWriteTime, 4, 'uint') }
	}
}
class IDWriteLocalizedStrings extends ID2DBase {
	static IID := '{08256209-099a-4b34-b86d-c22b110e7771}'
	GetCount() => ComCall(3, this, 'uint')
	FindLocaleName(localeName, &index, &exists) {
		ComCall(4, this, 'wstr', localeName, 'uint*', &index := 0, 'int*', &exists := 0)
	}
	GetLocaleNameLength(index) {
		ComCall(5, this, 'uint', index, 'uint*', &length := 0)
		return length
	}
	GetLocaleName(index) {
		VarSetStrCapacity(&localeName, size := this.GetLocaleNameLength(index) * 2)
		ComCall(6, this, 'uint', index, 'wstr*', &localeName, 'uint', size)
		return localeName
	}
	GetStringLength(index) {
		ComCall(7, this, 'uint', index, 'uint*', &length := 0)
		return length
	}
	GetString(index) {
		VarSetStrCapacity(&stringBuffer, size := this.GetStringLength(index) * 2)
		ComCall(6, this, 'uint', index, 'wstr*', &stringBuffer, 'uint', size)
		return stringBuffer
	}
}
class IDWriteFontFileStream extends ID2DBase {
	static IID := '{6d4865fe-0ab8-4d91-8f62-5dd6be34a3e0}'
	ReadFileFragment(&fragmentStart, fileOffset, fragmentSize, &fragmentContext) {
		ComCall(3, this, 'ptr*', &fragmentStart, 'int64', fileOffset, 'int64', fragmentSize, 'ptr*', &fragmentContext)
	}
	ReleaseFileFragment(fragmentContext) {
		ComCall(4, this, 'ptr', fragmentContext)
	}
	GetFileSize() {
		ComCall(5, this, 'int64', &fileSize := 0)
		return fileSize
	}
	GetLastWriteTime() {	; int64
		ComCall(6, this, 'int64', &lastWriteTime := 0)
		return lastWriteTime
	}
}
class IDWriteFontFile extends ID2DBase {
	static IID := '{739d886a-cef5-47dc-8769-1a8b41bebbb0}'
	GetReferenceKey(&fontFileReferenceKey, &fontFileReferenceKeySize) {
		ComCall(3, this, 'ptr*', &fontFileReferenceKey := 0, 'uint*', &fontFileReferenceKeySize := 0)
	}
	GetLoader() {
		ComCall(4, this, 'ptr*', &fontFileLoader := 0)
		return IDWriteFontFileLoader(fontFileLoader)
	}
	Analyze(&isSupportedFontType, &fontFileType, &fontFaceType, &numberOfFaces) {	; BOOL, DWRITE_FONT_FILE_TYPE, DWRITE_FONT_FACE_TYPE, UINT
		ComCall(5, this, 'int*', &isSupportedFontType := 0, 'int*', &fontFileType := 0, 'int*', &fontFaceType := 0, 'uint*', &numberOfFaces := 0)
	}
}
class IDWriteRenderingParams extends ID2DBase {
	static IID := '{2f0da53a-2add-47cd-82ee-d9ec34688e75}'
	GetGamma() {
		return ComCall(3, this, 'float')
	}
	GetEnhancedContrast() {
		return ComCall(4, this, 'float')
	}
	GetClearTypeLevel() {
		return ComCall(5, this, 'float')
	}
	GetPixelGeometry() {	; DWRITE_PIXEL_GEOMETRY
		return ComCall(6, this, 'int')
	}
	GetRenderingMode() {	; DWRITE_RENDERING_MODE
		return ComCall(7, this, 'int')
	}
}
class IDWriteFontFace extends ID2DBase {
	static IID := '{5f49804d-7024-4d43-bfa9-d25984f53849}'
	GetType() {	; DWRITE_FONT_FACE_TYPE
		return ComCall(3, this, 'int')
	}
	GetFiles(&numberOfFiles, fontFiles) {	; IDWriteFontFile[]
		ComCall(4, this, 'uint*', &numberOfFiles, 'ptr', fontFiles)
	}
	GetIndex() {
		return ComCall(5, this, 'uint')
	}
	GetSimulations() {	; DWRITE_FONT_SIMULATIONS
		return ComCall(6, this, 'int')
	}
	IsSymbolFont() {
		return ComCall(7, this, 'int')
	}
	GetMetrics() {
		ComCall(8, this, 'ptr', fontFaceMetrics := DWRITE_FONT_METRICS())
		return fontFaceMetrics
	}
	GetGlyphCount() {
		return ComCall(9, this, 'ushort')
	}
	GetDesignGlyphMetrics(glyphIndices, glyphCount, isSideways := false) {	; ushort[], uint, DWRITE_GLYPH_METRICS[]
		ComCall(10, this, 'ptr', glyphIndices, 'uint', glyphCount, 'ptr', glyphMetrics := ctypes.array(DWRITE_GLYPH_METRICS, glyphCount)(), 'int', isSideways)
		return glyphMetrics
	}
	GetGlyphIndices(codePoints, codePointCount) {	; uint[], uint
		ComCall(11, this, 'ptr', codePoints, 'uint', codePointCount, 'ptr', glyphIndices := ctypes.array('ushort', codePointCount)())
		return glyphIndices
	}
	TryGetFontTable(openTypeTableTag, &tableData, &tableSize, &tableContext, &exists) {	; DWRITE_MAKE_OPENTYPE_TAG
		ComCall(12, this, 'uint', openTypeTableTag, 'ptr*', &tableData := 0, 'uint*', &tableSize := 0, 'ptr*', &tableContext := 0, 'int*', &exists := 0)
	}
	ReleaseFontTable(tableContext) {
		ComCall(13, this, 'ptr', tableContext)
	}
	GetGlyphRunOutline(emSize, glyphIndices, glyphAdvances, glyphOffsets, glyphCount, isSideways, isRightToLeft, geometrySink) {	; float, UINT16[], float, DWRITE_GLYPH_OFFSET, uint, BOOL, BOOL, IDWriteGeometrySink*
		ComCall(14, this, 'float', emSize, 'ptr', glyphIndices, 'float', glyphAdvances, 'ptr', glyphOffsets, 'uint', glyphCount, 'int', isSideways, 'int', isRightToLeft, 'ptr', geometrySink)
	}
	GetRecommendedRenderingMode(emSize, pixelsPerDip, measuringMode, renderingParams) {	; float, float, DWRITE_MEASURING_MODE, IDWriteRenderingParams*
		ComCall(15, this, 'float', emSize, 'float', pixelsPerDip, 'int', measuringMode, 'ptr', renderingParams, 'int*', &renderingMode := 0)
		return renderingMode
	}
	GetGdiCompatibleMetrics(emSize, pixelsPerDip, transform) {	; float, float, DWRITE_MATRIX
		ComCall(16, this, 'float', emSize, 'float', pixelsPerDip, 'ptr', transform, 'ptr', fontFaceMetrics := DWRITE_FONT_METRICS())
		return fontFaceMetrics
	}
	GetGdiCompatibleGlyphMetrics(emSize, pixelsPerDip, transform, useGdiNatural, glyphIndices, glyphCount, isSideways := false) {	; float, float, DWRITE_MATRIX, BOOL, UINT16[], UINT, BOOL
		ComCall(17, this, 'float', emSize, 'float', pixelsPerDip, 'ptr', transform, 'int', useGdiNatural, 'ptr', glyphIndices, 'uint', glyphCount, 'ptr', glyphMetrics := DWRITE_GLYPH_METRICS(), 'int', isSideways)
		return glyphMetrics
	}
}
class IDWriteFontCollection extends ID2DBase {
	static IID := '{a84cee02-3eea-4eee-a827-87c1a02a0fcc}'
	GetFontCollection() {
		ComCall(3, this, 'ptr*', &fontCollection := 0)
		return IDWriteFontCollection(fontCollection)
	}
	GetFontCount() {
		return ComCall(4, this, 'uint')
	}
	GetFont(index) {
		ComCall(5, this, 'uint', index, 'ptr*', &font := 0)
		return IDWriteFont(font)
	}
}
class IDWriteFontCollectionLoader extends ID2DBase {
	static IID := '{cca920e4-52f0-492b-bfa8-29c72ee0a468}'
	CreateEnumeratorFromKey(factory, collectionKey, collectionKeySize) {
		ComCall(3, this, 'ptr', factory, 'ptr', collectionKey, 'uint', collectionKeySize, 'ptr*', &fontFileEnumerator := 0)
		return IDWriteFontFileEnumerator(fontFileEnumerator)
	}
}
class IDWriteFontFamily extends IDWriteFontList {
	static IID := '{da20d8ef-812a-4c43-9802-62ec4abd7add}'
	GetFamilyNames() {
		ComCall(6, this, 'ptr*', &names := 0)
		return IDWriteLocalizedStrings(names)
	}
	GetFirstMatchingFont(weight, stretch, style) {	; DWRITE_FONT_WEIGHT, DWRITE_FONT_STRETCH, DWRITE_FONT_STYLE
		ComCall(7, this, 'int', weight, 'int', stretch, 'int', style, 'ptr*', &matchingFont := 0)
		return IDWriteFont(matchingFont)
	}
	GetMatchingFonts(weight, stretch, style) {	; DWRITE_FONT_WEIGHT, DWRITE_FONT_STRETCH, DWRITE_FONT_STYLE
		ComCall(7, this, 'int', weight, 'int', stretch, 'int', style, 'ptr*', &matchingFonts := 0)
		return IDWriteFontList(matchingFonts)
	}
}
class IDWriteFontFileEnumerator extends ID2DBase {
	static IID := '{72755049-5ff7-435d-8348-4be97cfa6c7c}'
	MoveNext() {
		ComCall(3, this, 'int*', &hasCurrentFile := 0)
		return hasCurrentFile
	}
	GetCurrentFontFile() {
		ComCall(4, this, 'ptr*', &fontFile := 0)
		return IDWriteFontFile(fontFile)
	}
}
class IDWriteTextFormat extends ID2DBase {
	static IID := '{9c906818-31d7-4fd3-a151-7c5e225db55a}'
	SetTextAlignment(textAlignment) {	; DWRITE_TEXT_ALIGNMENT
		ComCall(3, this, 'int', textAlignment)
	}
	SetParagraphAlignment(paragraphAlignment) {	; DWRITE_PARAGRAPH_ALIGNMENT
		ComCall(4, this, 'int', paragraphAlignment)
	}
	SetWordWrapping(wordWrapping) {	; DWRITE_WORD_WRAPPING
		ComCall(5, this, 'int', wordWrapping)
	}
	SetReadingDirection(readingDirection) {	; DWRITE_READING_DIRECTION
		ComCall(6, this, 'int', readingDirection)
	}
	SetFlowDirection(flowDirection) {	; DWRITE_FLOW_DIRECTION
		ComCall(7, this, 'int', flowDirection)
	}
	SetIncrementalTabStop(incrementalTabStop) {	; float
		ComCall(8, this, 'float', incrementalTabStop)
	}
	SetTrimming(trimmingOptions, trimmingSign) {	; DWRITE_TRIMMING, IDWriteInlineObject
		ComCall(9, this, 'ptr', trimmingOptions, 'ptr', trimmingSign)
	}
	SetLineSpacing(lineSpacingMethod, lineSpacing, baseline) {	; DWRITE_LINE_SPACING_METHOD, float, float
		ComCall(10, this, 'int', lineSpacingMethod, 'float', lineSpacing, 'float', baseline)
	}
	GetTextAlignment() => ComCall(11, this, 'int')
	GetParagraphAlignment() => ComCall(12, this, 'int')
	GetWordWrapping() => ComCall(13, this, 'int')
	GetReadingDirection() => ComCall(14, this, 'int')
	GetFlowDirection() => ComCall(15, this, 'int')
	GetIncrementalTabStop() => ComCall(16, this, 'float')
	GetTrimming(&trimmingOptions, &trimmingSign) {
		ComCall(17, this, 'ptr', trimmingOptions := DWRITE_TRIMMING(), 'ptr*', &trimmingSign := 0)
		trimmingSign := IDWriteInlineObject(trimmingSign)
	}
	GetLineSpacing(&lineSpacingMethod, &lineSpacing, &baseline) {
		ComCall(18, this, 'int*', &lineSpacingMethod := 0, 'float*', &lineSpacing := 0.0, 'float*', &baseline := 0.0)
	}
	GetFontCollection() {
		ComCall(19, this, 'ptr*', &fontCollection := 0)
		return IDWriteFontCollection(fontCollection)
	}
	GetFontFamilyNameLength() => ComCall(20, this, 'uint')
	GetFontFamilyName() {
		VarSetStrCapacity(&fontFamilyName, nameSize := ComCall(20, this, 'uint') * 2)
		ComCall(21, this, 'wstr*', &fontFamilyName, 'uint', nameSize)
		return fontFamilyName
	}
	GetFontWeight() => ComCall(22, this, 'int')
	GetFontStyle() => ComCall(23, this, 'int')
	GetFontStretch() => ComCall(24, this, 'int')
	GetFontSize() => ComCall(25, this, 'float')
	GetLocaleNameLength() => ComCall(26, this, 'uint')
	GetLocaleName() {
		VarSetStrCapacity(&localeName, nameSize := ComCall(26, this, 'uint') * 2)
		ComCall(27, this, 'wstr*', &localeName, 'uint', nameSize)
		return localeName
	}
}
class IDWriteTextLayout extends IDWriteTextFormat {
	static IID := '{53737037-6d14-410b-9bfe-0b182bb70961}'
	SetMaxWidth(maxWidth) => ComCall(28, this, 'float', maxWidth)
	SetMaxHeight(maxHeight) => ComCall(29, this, 'float', maxHeight)
	SetFontCollection(fontCollection, textRange) {	; IDWriteFontCollection, DWRITE_TEXT_RANGE
		ComCall(30, this, 'ptr', fontCollection, 'ptr', textRange)
	}
	SetFontFamilyName(fontFamilyName, textRange) {
		ComCall(31, this, 'wstr', fontFamilyName, 'ptr', textRange)
	}
	SetFontWeight(fontWeight, textRange) {
		ComCall(32, this, 'int', fontWeight, 'ptr', textRange)
	}
	SetFontStyle(fontStyle, textRange) {
		ComCall(33, this, 'int', fontStyle, 'ptr', textRange)
	}
	SetFontStretch(fontStretch, textRange) {
		ComCall(34, this, 'int', fontStretch, 'ptr', textRange)
	}
	SetFontSize(fontSize, textRange) {
		ComCall(35, this, 'float', fontSize, 'ptr', textRange)
	}
	SetUnderline(hasUnderline, textRange) {
		ComCall(36, this, 'int', hasUnderline, 'ptr', textRange)
	}
	SetStrikethrough(hasStrikethrough, textRange) {
		ComCall(37, this, 'int', hasStrikethrough, 'ptr', textRange)
	}
	SetDrawingEffect(drawingEffect, textRange) {	; IUnknown, DWRITE_TEXT_RANGE
		ComCall(38, this, 'ptr', drawingEffect, 'ptr', textRange)
	}
	SetInlineObject(inlineObject, textRange) {	; IDWriteInlineObject, DWRITE_TEXT_RANGE
		ComCall(39, this, 'ptr', inlineObject, 'ptr', textRange)
	}
	SetTypography(typography, textRange) {	; IDWriteTypography, DWRITE_TEXT_RANGE
		ComCall(40, this, 'ptr', typography, 'ptr', textRange)
	}
	SetLocaleName(localeName, textRange) {
		ComCall(41, this, 'ptr', localeName, 'ptr', textRange)
	}
	GetMaxWidth() => ComCall(42, this, 'float')
	GetMaxHeight() => ComCall(43, this, 'float')
	GetFontCollection(currentPosition, &textRange := 0) {
		ComCall(44, this, 'uint', currentPosition, 'ptr*', &fontCollection := 0, 'ptr', textRange)
		return IDWriteFontCollection(fontCollection)
	}
	GetFontFamilyNameLength(currentPosition, &textRange := 0) {
		ComCall(45, this, 'uint', currentPosition, 'uint*', &nameLength := 0, 'ptr', textRange)
		return nameLength
	}
	GetFontFamilyName(currentPosition, &textRange := 0) {
		VarSetStrCapacity(&fontFamilyName, nameSize := this.GetFontFamilyNameLength(currentPosition) * 2)
		ComCall(46, this, 'uint', currentPosition, 'wstr*', &fontFamilyName, 'uint', nameSize, 'ptr', textRange)
		return fontFamilyName
	}
	GetFontWeight(currentPosition, &textRange := 0) {
		ComCall(47, this, 'uint', currentPosition, 'int*', &fontWeight := 0, 'ptr', textRange)
		return fontWeight
	}
	GetFontStyle(currentPosition, &textRange := 0) {
		ComCall(48, this, 'uint', currentPosition, 'int*', &fontStyle := 0, 'ptr', textRange)
		return fontStyle
	}
	GetFontStretch(currentPosition, &textRange := 0) {
		ComCall(49, this, 'uint', currentPosition, 'int*', &fontStretch := 0, 'ptr', textRange)
		return fontStretch
	}
	GetFontSize(currentPosition, &textRange := 0) {
		ComCall(50, this, 'uint', currentPosition, 'float*', &fontSize := 0, 'ptr', textRange)
		return fontSize
	}
	GetUnderline(currentPosition, &textRange := 0) {
		ComCall(51, this, 'uint', currentPosition, 'int*', &hasUnderline := 0, 'ptr', textRange)
		return hasUnderline
	}
	GetStrikethrough(currentPosition, &textRange := 0) {
		ComCall(52, this, 'uint', currentPosition, 'int*', &hasStrikethrough := 0, 'ptr', textRange)
		return hasStrikethrough
	}
	GetDrawingEffect(currentPosition, &textRange := 0) {
		ComCall(53, this, 'uint', currentPosition, 'ptr*', &drawingEffect := 0, 'ptr', textRange)
		return drawingEffect
	}
	GetInlineObject(currentPosition, &textRange := 0) {
		ComCall(54, this, 'uint', currentPosition, 'ptr*', &inlineObject := 0, 'ptr', textRange)
		return IDWriteInlineObject(inlineObject)
	}
	GetTypography(currentPosition, &textRange := 0) {
		ComCall(55, this, 'uint', currentPosition, 'ptr*', &typography := 0, 'ptr', textRange)
		return IDWriteTypography(typography)
	}
	GetLocaleNameLength(currentPosition, &textRange := 0) {
		ComCall(56, this, 'uint', currentPosition, 'uint*', &nameLength := 0, 'ptr', textRange)
		return nameLength
	}
	GetLocaleName(currentPosition, &textRange := 0) {
		VarSetStrCapacity(&localeName, nameSize := this.GetLocaleNameLength(currentPosition) * 2)
		ComCall(57, this, 'uint', currentPosition, 'wstr*', &localeName, 'uint', nameSize, 'ptr', textRange)
		return localeName
	}
	Draw(clientDrawingContext, renderer, originX, originY) {
		ComCall(58, this, 'ptr', clientDrawingContext, 'ptr', renderer, 'float', originX, 'float', originY)
	}
	GetLineMetrics(lineMetrics, maxLineCount, &actualLineCount) {
		ComCall(59, this, 'ptr', lineMetrics, 'uint', maxLineCount, 'uint*', &actualLineCount := 0)
	}
	GetMetrics() {
		ComCall(60, this, 'ptr', textMetrics := DWRITE_TEXT_METRICS())
		return textMetrics
	}
	GetOverhangMetrics() {
		ComCall(61, this, 'ptr', overhangs := DWRITE_OVERHANG_METRICS())
		return overhangs
	}
	GetBreakConditions(&breakConditionBefore, &breakConditionAfter) {
		ComCall(62, this, 'int*', &breakConditionBefore := 0, 'int*', &breakConditionAfter)
	}
}
class IDWritePixelSnapping extends ID2DBase {
	static IID := '{eaf3a2da-ecf4-4d24-b644-b34f6842024b}'
	IsPixelSnappingDisabled(clientDrawingContext) {
		ComCall(3, this, 'ptr', clientDrawingContext, 'int*', &isDisabled := 0)
		return isDisabled
	}
	GetCurrentTransform(clientDrawingContext) {
		ComCall(4, this, 'ptr', clientDrawingContext, 'ptr', transform := DWRITE_MATRIX())
		return transform
	}
	GetPixelsPerDip(clientDrawingContext) {
		ComCall(5, this, 'ptr', clientDrawingContext, 'float*', &pixelsPerDip := 0)
		return pixelsPerDip
	}
}
class IDWriteTextRenderer extends IDWritePixelSnapping {
	static IID := '{ef8a8135-5cc6-45fe-8825-c5a0724eb819}'
	DrawGlyphRun(clientDrawingContext, baselineOriginX, baselineOriginY, measuringMode, glyphRun, glyphRunDescription, clientDrawingEffect) {
		ComCall(6, this, 'ptr', clientDrawingContext, 'float', baselineOriginX, 'float', baselineOriginY, 'int', measuringMode, 'ptr', glyphRun, 'ptr', glyphRunDescription, 'ptr', clientDrawingEffect)
	}
	DrawUnderline(clientDrawingContext, baselineOriginX, baselineOriginY, measuringMode, glyphRun, glyphRunDescription, clientDrawingEffect) {
		ComCall(7, this, 'ptr', clientDrawingContext, 'float', baselineOriginX, 'float', baselineOriginY, 'int', measuringMode, 'ptr', glyphRun, 'ptr', glyphRunDescription, 'ptr', clientDrawingEffect)
	}
	DrawStrikethrough(clientDrawingContext, baselineOriginX, baselineOriginY, strikethrough, clientDrawingEffect) {	; DWRITE_STRIKETHROUGH
		ComCall(8, this, 'ptr', clientDrawingContext, 'float', baselineOriginX, 'float', baselineOriginY, 'ptr', strikethrough, 'ptr', clientDrawingEffect)
	}
	DrawInlineObject(clientDrawingContext, baselineOriginX, baselineOriginY, inlineObject, isSideways, isRightToLeft, clientDrawingEffect) {	; DWRITE_STRIKETHROUGH
		ComCall(9, this, 'ptr', clientDrawingContext, 'float', baselineOriginX, 'float', baselineOriginY, 'ptr', inlineObject, 'int', isSideways, 'int', isRightToLeft, 'ptr', clientDrawingEffect)
	}
}
class IDWriteInlineObject extends ID2DBase {
	static IID := '{8339FDE3-106F-47ab-8373-1C6295EB10B3}'
	Draw(clientDrawingContext, renderer, originX, originY, isSideways, isRightToLeft, clientDrawingEffect) {
		ComCall(3, this, 'ptr', clientDrawingContext, 'ptr', renderer, 'float', originX, 'float', originY, 'int', isSideways, 'int', isRightToLeft, 'ptr', clientDrawingEffect)
	}
	GetMetrics() {
		ComCall(4, this, 'ptr', metrics := DWRITE_INLINE_OBJECT_METRICS())
		return metrics
	}
	GetOverhangMetrics() {
		ComCall(5, this, 'ptr', overhangs := DWRITE_OVERHANG_METRICS())
		return overhangs
	}
	GetBreakConditions(&breakConditionBefore, &breakConditionAfter) {
		ComCall(6, this, 'int*', &breakConditionBefore := 0, 'int*', &breakConditionAfter)
	}
}
class IDWriteTextAnalyzer extends ID2DBase {
	static IID := '{b7e6163e-7f46-43b4-84b3-e4e6249c365d}'
	AnalyzeScript(analysisSource, textPosition, textLength, analysisSink) {	; IDWriteTextAnalysisSource, uint, uint, IDWriteTextAnalysisSink
		ComCall(3, this, 'ptr', analysisSource, 'uint', textPosition, 'uint', textLength, 'ptr', analysisSink)
	}
	AnalyzeBidi(analysisSource, textPosition, textLength, analysisSink) {	; IDWriteTextAnalysisSource, uint, uint, IDWriteTextAnalysisSink
		ComCall(4, this, 'ptr', analysisSource, 'uint', textPosition, 'uint', textLength, 'ptr', analysisSink)
	}
	AnalyzeNumberSubstitution(analysisSource, textPosition, textLength, analysisSink) {	; IDWriteTextAnalysisSource, uint, uint, IDWriteTextAnalysisSink
		ComCall(5, this, 'ptr', analysisSource, 'uint', textPosition, 'uint', textLength, 'ptr', analysisSink)
	}
	AnalyzeLineBreakpoints(analysisSource, textPosition, textLength, analysisSink) {	; IDWriteTextAnalysisSource, uint, uint, IDWriteTextAnalysisSink
		ComCall(6, this, 'ptr', analysisSource, 'uint', textPosition, 'uint', textLength, 'ptr', analysisSink)
	}
	GetGlyphs(textString, textLength, fontFace, isSideways, isRightToLeft, scriptAnalysis, localeName, numberSubstitution, features, featureRangeLengths, featureRanges, maxGlyphCount, &clusterMap, &textProps, &glyphIndices, &glyphProps, &actualGlyphCount) {
		ComCall(7, this, 'wstr', textString, 'uint', textLength, 'ptr', fontFace, 'int', isSideways, 'int', isRightToLeft, 'ptr', scriptAnalysis, 'wstr', localeName, 'ptr', numberSubstitution, 'ptr', features, 'uint*', featureRangeLengths, 'uint', featureRanges, 'uint', maxGlyphCount, 'ushort*', &clusterMap := 0, 'ptr', textProps, 'ushort*', &glyphIndices := 0, 'ptr', glyphProps, 'uint*', &actualGlyphCount := 0)
	}
	GetGlyphPlacements(textString, clusterMap, textProps, textLength, glyphIndices, glyphProps, glyphCount, fontFace, fontEmSize, isSideways, isRightToLeft, scriptAnalysis, localeName, features, featureRangeLengths, featureRanges, &glyphAdvances, glyphOffsets) {
		ComCall(8, this, 'wstr', textString, 'ushort*', clusterMap, 'ptr', textProps, 'uint', textLength, 'ushort*', glyphIndices, 'ptr', glyphProps, 'uint', glyphCount, 'ptr', fontFace, 'float', fontEmSize, 'int', isSideways, 'int', isRightToLeft, 'ptr', scriptAnalysis, 'wstr', localeName, 'ptr', features, 'uint', featureRangeLengths, 'uint', featureRanges, 'float*', &glyphAdvances := 0.0, 'ptr', glyphOffsets)
	}
	GetGdiCompatibleGlyphPlacements(textString, clusterMap, textProps, textLength, glyphIndices, glyphProps, glyphCount, fontFace, fontEmSize, pixelsPerDip, transform, useGdiNatural, isSideways, isRightToLeft, scriptAnalysis, localeName, features, featureRangeLengths, featureRanges, &glyphAdvances, glyphOffsets) {
		ComCall(9, this, 'wstr', textString, 'ushort*', clusterMap, 'ptr', textProps, 'uint', textLength, 'ushort*', glyphIndices, 'ptr', glyphProps, 'uint', glyphCount, 'ptr', fontFace, 'float', fontEmSize, 'float', pixelsPerDip, 'ptr', transform, 'int', useGdiNatural, 'int', isSideways, 'int', isRightToLeft, 'ptr', scriptAnalysis, 'wstr', localeName, 'ptr', features, 'uint', featureRangeLengths, 'uint', featureRanges, 'float*', &glyphAdvances := 0.0, 'ptr', glyphOffsets)
	}
}
class IDWriteTextAnalysisSink extends ID2DBase {
	static IID := '{5810cd44-0ca0-4701-b3fa-bec5182ae4f6}'
	SetScriptAnalysis(textPosition, textLength, scriptAnalysis) {	; uint, uint, DWRITE_SCRIPT_ANALYSIS
		ComCall(3, this, 'uint', textPosition, 'uint', textLength, 'ptr', scriptAnalysis)
	}
	SetLineBreakpoints(textPosition, textLength, lineBreakpoints) {	; uint, uint, DWRITE_LINE_BREAKPOINT
		ComCall(4, this, 'uint', textPosition, 'uint', textLength, 'ptr', lineBreakpoints)
	}
	SetBidiLevel(textPosition, textLength, explicitLevel, resolvedLevel) {
		ComCall(5, this, 'uint', textPosition, 'uint', textLength, 'uchar', explicitLevel, 'uchar', resolvedLevel)
	}
	SetNumberSubstitution(textPosition, textLength, numberSubstitution) {	; uint, uint, IDWriteNumberSubstitution
		ComCall(6, this, 'uint', textPosition, 'uint', textLength, 'ptr', numberSubstitution)
	}
}
class IDWriteTextAnalysisSource extends ID2DBase {
	static IID := '{688e1a58-5094-47c8-adc8-fbcea60ae92b}'
	GetTextAtPosition(textPosition) {
		ComCall(3, this, 'uint', textPosition, 'ptr*', &textString := 0, 'uint*', &textLength := 0)
		return StrGet(textString, textLength, 'utf-16')
	}
	GetTextBeforePosition(textPosition) {
		ComCall(4, this, 'uint', textPosition, 'ptr*', &textString := 0, 'uint*', &textLength := 0)
		return StrGet(textString, textLength, 'utf-16')
	}
	GetParagraphReadingDirection() => ComCall(5, this, 'int')	; DWRITE_READING_DIRECTION
	GetLocaleName(textPosition) {
		ComCall(6, this, 'uint', textPosition, 'uint*', &textLength := 0, 'ptr*', &localeName := 0)
		return StrGet(localeName, textLength, 'utf-16')
	}
	GetNumberSubstitution(textPosition) {
		ComCall(7, this, 'uint', textPosition, 'uint*', &textLength := 0, 'ptr*', &numberSubstitution := 0)
		return IDWriteNumberSubstitution(numberSubstitution)
	}
}
class IDWriteFont extends ID2DBase {
	static IID := '{acd16696-8c14-4f5d-877e-fe3fc1d32737}'
	GetFontFamily() {
		ComCall(3, this, 'ptr*', &fontFamily := 0)
		return IDWriteFontFamily(fontFamily)
	}
	GetWeight() => ComCall(4, this, 'int')	; DWRITE_FONT_WEIGHT
	GetStretch() => ComCall(5, this, 'int')	; DWRITE_FONT_STRETCH
	GetStyle() => ComCall(6, this, 'int')	; DWRITE_FONT_STYLE
	IsSymbolFont() => ComCall(7, this, 'int')
	GetFaceNames() {
		ComCall(8, this, 'ptr*', &names := 0)
		return IDWriteLocalizedStrings(names)
	}
	GetInformationalStrings(informationalStringID, &exists) {	; DWRITE_INFORMATIONAL_STRING_ID
		ComCall(9, this, 'int', informationalStringID, 'ptr*', &informationalStrings := 0, 'int*', &exists := 0)
		return IDWriteLocalizedStrings(informationalStrings)
	}
	GetSimulations() => ComCall(10, this, 'int')	; DWRITE_FONT_SIMULATIONS
	GetMetrics() {
		ComCall(11, this, 'ptr', &fontMetrics := DWRITE_FONT_METRICS())
		return fontMetrics
	}
	HasCharacter(unicodeValue) {
		ComCall(12, this, 'uint', unicodeValue, 'int*', &exists := 0)
		return exists
	}
	CreateFontFace() {
		ComCall(13, this, 'ptr*', &fontFace := 0)
		return IDWriteFontFace(fontFace)
	}
}
class IDWriteNumberSubstitution extends ID2DBase {
	static IID := '{14885CC9-BAB0-4f90-B6ED-5C366A2CD03D}'
}
class IDWriteFontList extends ID2DBase {
	static IID := '{1a0d8438-1d97-4ec1-aef9-a2fb86ed6acb}'
	GetFontCollection() {
		ComCall(3, this, 'ptr*', &fontCollection := 0)
		return IDWriteFontCollection(fontCollection)
	}
	GetFontCount() => ComCall(4, this, 'uint')
	GetFont(index) {
		ComCall(5, this, 'uint', index, 'ptr*', &font := 0)
		return IDWriteFont(font)
	}
}
class IDWriteGdiInterop extends ID2DBase {
	static IID := '{1edd9491-9853-4299-898f-6432983b6f3a}'
	CreateFontFromLOGFONT(logFont) {	; LOGFONTW
		ComCall(3, this, 'ptr', logFont, 'ptr*', &font := 0)
		return IDWriteFont(font)
	}
	ConvertFontToLOGFONT(font, &isSystemFont) {
		ComCall(4, this, 'ptr', font, 'ptr', logFont := LOGFONTW(), 'int*', &isSystemFont := 0)
		return logFont
	}
	ConvertFontFaceToLOGFONT(font) {
		ComCall(5, this, 'ptr', font, 'ptr', logFont := LOGFONTW())
		return logFont
	}
	CreateFontFaceFromHdc(hdc) {
		ComCall(6, this, 'ptr', hdc, 'ptr*', &fontFace := 0)
		return IDWriteFontFace(fontFace)
	}
	CreateBitmapRenderTarget(hdc, width, height) {
		ComCall(7, this, 'ptr', hdc, 'uint', width, 'uint', height, 'ptr*', &renderTarget := 0)
		return IDWriteBitmapRenderTarget(renderTarget)
	}
}
class IDWriteGlyphRunAnalysis extends ID2DBase {
	static IID := '{7d97dbf7-e085-42d4-81e3-6a883bded118}'
	GetAlphaTextureBounds(textureType) {	; DWRITE_TEXTURE_TYPE
		ComCall(3, this, 'int', textureType, 'ptr', textureBounds := D2D1_RECT_U())
		return textureBounds
	}
	CreateAlphaTexture(textureType, textureBounds, alphaValues, bufferSize) {
		ComCall(4, this, 'int', textureType, 'ptr', textureBounds, 'ptr', alphaValues, 'uint', bufferSize)
	}
	GetAlphaBlendParams(renderingParams, &blendGamma, &blendEnhancedContrast, &blendClearTypeLevel) {
		ComCall(5, this, 'ptr', renderingParams, 'float*', &blendGamma := 0.0, 'float*', &blendEnhancedContrast := 0.0, 'float*', &blendClearTypeLevel := 0.0)
	}
}
class IDWriteTypography extends ID2DBase {
	static IID := '{55f1112b-1dc2-4b3c-9541-f46894ed85b6}'
	AddFontFeature(fontFeature) {	; DWRITE_FONT_FEATURE
		ComCall(3, this, 'ptr', fontFeature)
	}
	GetFontFeatureCount() => ComCall(4, this, 'uint')
	GetFontFeature(fontFeatureIndex) {
		ComCall(5, this, 'uint', fontFeatureIndex, 'ptr', fontFeature := DWRITE_FONT_FEATURE())
		return fontFeature
	}
}
class ID2DBase {
	ptr := 0
	__New(ptr) {
		if (!ptr)
			throw ValueError('invalid ptr', -2)
		this.ptr := ptr
	}
	AddRef() => ObjAddRef(this.ptr)
	Release() => ObjRelease(this.ptr)
	Query(interface) {
		if interface is String
			interface := ID2DBase._IID2Class.Get(iid := interface, ID2DBase)
		else iid := interface.iid
		obj := ComObjQuery(this.ptr, iid)
		p := ComObjValue(obj), ObjAddRef(p)
		return interface(p)
	}
	__Delete() => this.ptr && ObjRelease(this.ptr)

	static _IID2Class := (OnExit((*) => this._IID2Class := 0), Map()), _IID2Class.CaseSense := false
	static IID {
		get => (_ := unset)
		set => (this._IID2Class[Value] := this, this.DefineProp('IID', { Value: Value }))
	}
}

class D2D1_COLOR_F extends ctypes.struct {
	static fields := [['float', 'r'], ['float', 'g'], ['float', 'b'], ['float', 'a']]
}
class D2D1_POINT_2U extends ctypes.struct {
	static fields := [['uint', 'x'], ['uint', 'y']]
}
class D2D1_POINT_2F extends ctypes.struct {
	static fields := [['float', 'x'], ['float', 'y']]
}
class D2D1_RECT_F extends ctypes.struct {
	static fields := [['float', 'left'], ['float', 'top'], ['float', 'right'], ['float', 'bottom']]
}
class D2D1_RECT_U extends ctypes.struct {
	static fields := [['uint', 'left'], ['uint', 'top'], ['uint', 'right'], ['uint', 'bottom']]
}
class D2D1_SIZE_F extends ctypes.struct {
	static fields := [['float', 'width'], ['float', 'height']]
}
class D2D1_SIZE_U extends ctypes.struct {
	static fields := [['uint', 'width'], ['uint', 'height']]
}
class D2D1_MATRIX_3X2_F extends ctypes.struct {
	static fields := [['float', '_11'], ['float', '_12'], ['float', '_21'], ['float', '_22'], ['float', '_31'], ['float', '_32']]
}
class D2D1_PIXEL_FORMAT extends ctypes.struct {
	static fields := [['int', 'format'], ['int', 'alphaMode']]
}
class D2D1_BITMAP_PROPERTIES extends ctypes.struct {
	static fields := [[D2D1_PIXEL_FORMAT, 'pixelFormat'], ['float', 'dpiX'], ['float', 'dpiY']]
}
class D2D1_GRADIENT_STOP extends ctypes.struct {
	static fields := [['float', 'position'], [D2D1_COLOR_F, 'color']]
}
class D2D1_BRUSH_PROPERTIES extends ctypes.struct {
	static fields := [['float', 'opacity'], [D2D1_MATRIX_3X2_F, 'transform']]
}
class D2D1_BITMAP_BRUSH_PROPERTIES extends ctypes.struct {
	static fields := [['int', 'extendModeX'], ['int', 'extendModeY'], ['int', 'interpolationMode']]
}
class D2D1_LINEAR_GRADIENT_BRUSH_PROPERTIES extends ctypes.struct {
	static fields := [[D2D1_POINT_2F, 'startPoint'], [D2D1_POINT_2F, 'endPoint']]
}
class D2D1_RADIAL_GRADIENT_BRUSH_PROPERTIES extends ctypes.struct {
	static fields := [[D2D1_POINT_2F, 'center'], [D2D1_POINT_2F, 'gradientOriginOffset'], ['float', 'radiusX'], ['float', 'radiusY']]
}
class D2D1_BEZIER_SEGMENT extends ctypes.struct {
	static fields := [[D2D1_POINT_2F, 'point1'], [D2D1_POINT_2F, 'point2'], [D2D1_POINT_2F, 'point3']]
}
class D2D1_TRIANGLE extends ctypes.struct {
	static fields := [[D2D1_POINT_2F, 'point1'], [D2D1_POINT_2F, 'point2'], [D2D1_POINT_2F, 'point3']]
}
class D2D1_ARC_SEGMENT extends ctypes.struct {
	static fields := [[D2D1_POINT_2F, 'point'], [D2D1_SIZE_F, 'size'], ['float', 'rotationAngle'], ['int', 'sweepDirection'], ['int', 'arcSize']]
}
class D2D1_QUADRATIC_BEZIER_SEGMENT extends ctypes.struct {
	static fields := [[D2D1_POINT_2F, 'point1'], [D2D1_POINT_2F, 'point2']]
}
class D2D1_ELLIPSE extends ctypes.struct {
	static fields := [[D2D1_POINT_2F, 'point'], ['float', 'radiusX'], ['float', 'radiusY']]
}
class D2D1_ROUNDED_RECT extends ctypes.struct {
	static fields := [[D2D1_RECT_F, 'rect'], ['float', 'radiusX'], ['float', 'radiusY']]
}
class D2D1_STROKE_STYLE_PROPERTIES extends ctypes.struct {
	static fields := [['int', 'startCap'], ['int', 'endCap'], ['int', 'dashCap'], ['int', 'lineJoin'], ['float', 'miterLimit'], ['int', 'dashStyle'], ['float', 'ashOffset']]
}
class D2D1_LAYER_PARAMETERS extends ctypes.struct {
	static fields := [[D2D1_RECT_F, 'contentBounds'], ['ptr', 'geometricMask'], ['int', 'maskAntialiasMode'], [D2D1_MATRIX_3X2_F, 'maskTransform'], ['float', 'opacity'], ['ptr', 'opacityBrush'], ['int', 'layerOptions']]
}
class D2D1_RENDER_TARGET_PROPERTIES extends ctypes.struct {
	static fields := [['int', 'type'], ['int', 'format'], ['int', 'alphaMode'], ['float', 'dpiX'], ['float', 'dpiY'], ['int', 'usage'], ['int', 'minLevel']]
}
class D2D1_HWND_RENDER_TARGET_PROPERTIES extends ctypes.struct {
	static fields := [['HWND', 'hwnd'], ['uint', 'width'], ['uint', 'height'], ['int', 'presentOptions']]
}
class D2D1_DRAWING_STATE_DESCRIPTION extends ctypes.struct {
	static fields := [['int', 'antialiasMode'], ['int', 'textAntialiasMode'], ['uint64', 'tag1'], ['uint64', 'tag2'], [D2D1_MATRIX_3X2_F, 'transform']]
}
class D2D1_FACTORY_OPTIONS extends ctypes.struct {
	static fields := [['int', 'debugLevel']]
}
class DWRITE_FONT_METRICS extends ctypes.struct {
	static fields := [['ushort', 'designUnitsPerEm'], ['ushort', 'ascent'], ['ushort', 'descent'], ['INT16', 'lineGap'], ['ushort', 'capHeight'], ['ushort', 'xHeight'], ['INT16', 'underlinePosition'], ['ushort', 'underlineThickness'], ['INT16', 'strikethroughPosition'], ['ushort', 'strikethroughThickness']]
}
class DWRITE_GLYPH_METRICS extends ctypes.struct {
	static fields := [['int', 'leftSideBearing'], ['uint', 'advanceWidth'], ['int', 'rightSideBearing'], ['int', 'topSideBearing'], ['uint', 'advanceHeight'], ['int', 'bottomSideBearing'], ['int', 'verticalOriginY']]
}
class DWRITE_MATRIX extends ctypes.struct {
	static fields := [['float', 'm11'], ['float', 'm12'], ['float', 'm21'], ['float', 'm22'], ['float', 'dx'], ['float', 'dy']]
}
class DWRITE_TRIMMING extends ctypes.struct {
	static fields := [['int', 'granularity'], ['uint', 'delimiter'], ['uint', 'delimiterCount']]
}
class DWRITE_TEXT_METRICS extends ctypes.struct {
	static fields := [['float', 'left'], ['float', 'top'], ['float', 'width'], ['float', 'widthIncludingTrailingWhitespace'], ['float', 'height'], ['float', 'layoutWidth'], ['float', 'layoutHeight'], ['uint', 'maxBidiReorderingDepth'], ['uint', 'lineCount']]
}
class DWRITE_OVERHANG_METRICS extends ctypes.struct {
	static fields := [['float', 'left'], ['float', 'top'], ['float', 'right'], ['float', 'bottom']]
}
class DWRITE_STRIKETHROUGH extends ctypes.struct {
	static fields := [['float', 'width'], ['float', 'thickness'], ['float', 'offset'], ['int', 'readingDirection'], ['int', 'flowDirection'], ['LPWSTR', 'localeName'], ['int', 'measuringMode']]
}
class DWRITE_INLINE_OBJECT_METRICS extends ctypes.struct {
	static fields := [['float', 'width'], ['float', 'height'], ['float', 'baseline'], ['int', 'supportsSideways']]
}
class DWRITE_FONT_FEATURE extends ctypes.struct {
	static fields := [['int', 'nameTag'], ['uint', 'parameter']]
}
class DWRITE_SCRIPT_ANALYSIS extends ctypes.struct {
	static fields := [['ushort', 'script'], ['int', 'shapes']]
}
class LOGFONTW extends ctypes.struct {
	static fields := [['int', 'lfHeight'], ['int', 'lfWidth'], ['int', 'lfEscapement'], ['int', 'lfOrientation'], ['int', 'lfWeight'], ['uchar', 'lfItalic'], ['uchar', 'lfUnderline'], ['uchar', 'lfStrikeOut'], ['uchar', 'lfCharSet'], ['uchar', 'lfOutPrecision'], ['uchar', 'lfClipPrecision'], ['uchar', 'lfQuality'], ['uchar', 'lfPitchAndFamily'], [this.WCHAR_32, 'lfFaceName']]
	; WCHAR[32] array as string
	class WCHAR_32 extends ctypes.array {
		static align := 2, length := 32, size := 2 * 32
		static from_ptr(ptr, *) => StrGet(ptr, 32)
		static assign(ptr, value, *) => StrPut(value, ptr, 32)
	}
}

;===============================================================================
;other function

d2d_color(color := 0xffffff)
{
    g := ((color & 0x00ff0000) >> 16) / 255
    r := ((color & 0xff000000) >> 24) / 255
    b := ((color & 0xff00) >> 8) / 255
    a := ((color & 0xff)) / 255
    color := [r, g, b, a]
    return D2D1_COLOR_F(color)
}