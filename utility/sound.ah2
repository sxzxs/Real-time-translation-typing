class SoundINput
{
    __New(url, input_js := '', output_js := '', out_change_call_back := unset, ui_name := '翻译')
    {
        this.url := url
        this.input_js := input_js
        this.output_js := output_js
        this.ui_name := ui_name
        if(IsSet(out_change_call_back))
            this.out_change_call_back := out_change_call_back

        this.ui := Gui('+AlwaysOnTop -DPIScale +Caption +Border +LastFound -ToolWindow +Resize -HScroll', ui_name)
        this.ui.Show(Format("x-5000 y-5000 w{} h{}", A_ScreenWidth * 0.5, A_ScreenHeight * 0.5))
        this.wv := WebView2.create(this.ui.Hwnd)
        this.nav_sync := SyncHandler()
        this.exec_sync := SyncHandler((args) => OutputDebug(StrGet(args[2])))
        this.wv.CoreWebView2.add_NavigationCompleted(this.nav_sync)
        this.wv.CoreWebView2.Navigate(this.url )
        this.handler := CreateEventHandler(OnPermissionRequested)
        this.token := this.wv.CoreWebView2.add_PermissionRequested(this.handler)
        ;this.ui.OnEvent("Close", (*) => (this.wv.CoreWebView2.remove_PermissionRequested(this.token), ExitApp()))
        ;this.ui.OnEvent("Close", (*) => ())

        btt(ui_name ' 加载中。。。',0, 0,,OwnzztooltipStyle1,{Transparent:180,DistanceBetweenMouseXAndToolTip:-100,DistanceBetweenMouseYAndToolTip:-20})
        if(!this.nav_sync.wait(10000))
        {
            btt(ui_name ' 加载失败',0, 0,,OwnzztooltipStyle1,{Transparent:180,DistanceBetweenMouseXAndToolTip:-100,DistanceBetweenMouseYAndToolTip:-20})
            sleep(200)
        }
        this.wv.CoreWebView2.AddHostObjectToScript('ahk', {str:'str from ahk',func:this.on_result_change.Bind(this)})
        this.ui.OnEvent('Size', this.gui_size.Bind(this))
        this.ui.Hide()
    }
    __Delete() 
    {
        this.ui := ''
    }

    set_out_change_call_back(fc)
    {
        this.out_change_call_back := fc
    }

    on_result_change(out_text)
    {
        logger.info(out_text)
        p := this.out_change_call_back
        if(IsSet(p))
            (this.out_change_call_back)(this.ui_name, out_text)
    }
    show(x := 0, y := 0, w := 200, h := 200)
    {
        this.ui.Show(Format("x{} y{} w{} h{}", x, y, w, h))
    }
    gui_size(GuiObj, MinMax, Width, Height) 
    {
        if (MinMax != -1) 
            this.wv.Fill()
    }
    exec_js_script(js)
    {
        rtn := this.wv.CoreWebView2.ExecuteScript(js, 0)
    }
    start()
    {
        js := "
        (
            document.querySelector("#final").innerHTML = '';
            speechRecognition.start();
        )"
        logger.info(js)
        return rtn := this.exec_js_script(js)
    }
    stop()
    {
        js := "
        (
            speechRecognition.stop();
            location.reload();
        )"
        logger.info(js)
        return rtn := this.exec_js_script(js)
    }
}

OnPermissionRequested(_, sender, args) {
    args := WebView2.PermissionRequestedEventArgs(args)
    args.State := WebView2.PERMISSION_STATE.ALLOW
    return 0
}

CreateEventHandler(function) {
    vtable := Buffer(5 * A_PtrSize)
    NumPut("ptr", vtable.Ptr + A_PtrSize,
    "ptr", queryInterface := CallbackCreate(() => 0x80004001),
    "ptr", addOrRelease := CallbackCreate(() => 0),
    "ptr", addOrRelease,
    "ptr", invoke := CallbackCreate(function),
    vtable)
    return {Ptr: vtable.Ptr, __Delete: (_) => (CallbackFree(queryInterface), CallbackFree(addOrRelease), CallbackFree(invoke)), _: vtable}
}