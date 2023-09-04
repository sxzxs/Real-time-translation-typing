#Requires AutoHotkey v2.0

logger.is_log_open := true
logger.is_out_console := true

class Deepl_web_cd extends Web_cd
{
    __New()
    {
        url := 'https://www.deepl.com/zh/translator' 
        input_js :='
        (
            {          
                const editor = document.querySelector("#panelTranslateText > div.lmt__sides_container > div.lmt__sides_wrapper > section.lmt__side_container.lmt__side_container--source > div.lmt__textarea_container > div.lmt__inner_textarea_container > d-textarea");
                const inputbox = document.querySelector("#panelTranslateText > div.lmt__sides_container > div.lmt__sides_wrapper > section.lmt__side_container.lmt__side_container--source > div.lmt__textarea_container > div.lmt__inner_textarea_container > d-textarea > div");
                inputbox.textContent = "{1}";
                setTimeout(() => {
                    editor.dispatchEvent(new InputEvent("input"));
                }, 20);
            }
        )'
        out_put_js := '
        (
            {
                
                o = document.querySelector('#panelTranslateText > div.lmt__sides_container > div.lmt__sides_wrapper > section.lmt__side_container.lmt__side_container--target > div.lmt__textarea_container > div.lmt__inner_textarea_container > d-textarea')
                function callback3(records) {
                records.forEach(function(record) {
                    try
                    {
                        //aa = o.querySelector('[class="ordinary-output target-output clearfix"]');
                        console.log(o.textContent);
                        obj = window.chrome.webview.hostObjects.ahk;
                        obj.func(o.textContent);
                    }
                    catch
                    {
                        try
                        {
                            console.log('');
                            obj = window.chrome.webview.hostObjects.ahk;
                            obj.func('');
                        }
                        catch
                        {

                        }
                    }
                })
                }
                var ob3 = new MutationObserver(callback3)
                ob3.observe(o, {
                characterDataOldValue: true,
                attributes: true,
                childList: true,
                characterData: true,
                subtree: true
                })
            }
        )'
        super.__New(url, input_js, out_put_js,, 'deepl')
    }
    __Delete()
    {
        
    }
}

class Baidu_web_cd extends Web_cd
{
    __New()
    {
        url := 'https://fanyi.baidu.com/' 
        input_js :='
        (
            {          
                let inputbox = document.querySelector("#baidu_translate_input");
                inputbox.value = "{1}";
                let e = document.createEvent("HTMLEvents");
                e.initEvent("input");
                inputbox.dispatchEvent(e);
            }
        )'
        out_put_js := '
        (
            {
                
                o = document.querySelector(".output-wrap")
                function callback3(records) {
                records.forEach(function(record) {
                    try
                    {
                        aa = o.querySelector('[class="ordinary-output target-output clearfix"]');
                        console.log(aa.textContent);
                        obj = window.chrome.webview.hostObjects.ahk;
                        obj.func(aa.textContent);
                    }
                    catch
                    {
                        try
                        {
                            console.log('');
                            obj = window.chrome.webview.hostObjects.ahk;
                            obj.func('');
                        }
                        catch
                        {

                        }
                    }
                })
                }
                var ob3 = new MutationObserver(callback3)
                ob3.observe(o, {
                characterDataOldValue: true,
                attributes: true,
                childList: true,
                characterData: true,
                subtree: true
                })
            }
        )'
        super.__New(url, input_js, out_put_js,, 'baidu')
    }
    __Delete()
    {
        
    }
}

class Youdao_web_cd extends Web_cd
{
    __New()
    {
        url := 'https://fanyi.youdao.com/indexLLM.html#/' 
        input_js :='
        (
            {     
                let inputbox = document.getElementById("js_fanyi_input");
                inputbox.textContent = "{1}";
                let e = document.createEvent("HTMLEvents");
                e.initEvent("input");
                inputbox.dispatchEvent(e);
            }
        )'
        out_put_js := '
        (
            o = document.querySelector("#js_fanyi_output")
            function callback3(records) {
            records.forEach(function(record) {
                try
                {
                    console.log(o.textContent);
                    obj = window.chrome.webview.hostObjects.ahk;
                    obj.func(o.textContent);
                }
                catch
                {
                    try
                    {
                        obj = window.chrome.webview.hostObjects.ahk;
                        obj.func('');
                    }
                    catch
                    {

                    }
                }
            })
            }
            var ob3 = new MutationObserver(callback3)
            ob3.observe(o, {
            characterDataOldValue: true,
            attributes: true,
            childList: true,
            characterData: true,
            subtree: true
            })
        )'
        super.__New(url, input_js, out_put_js,, 'youdao')
    }
    __Delete()
    {
        
    }
}


class Sougou_web_cd extends Web_cd
{
    __New()
    {
        url := 'https://fanyi.sogou.com/text?keyword=friend&transfrom=auto&transto=zh-CHS&model=general' 
        input_js :='
        (
            {
                let inputbox = document.getElementById("trans-input");
                inputbox.value = "{1}";
                let e = document.createEvent("HTMLEvents");
                e.initEvent("input");
                inputbox.dispatchEvent(e);
                document.querySelector("#trans-result").textContent
            }
        )'
        out_put_js := '
        (
            o=document.querySelector("#trans-to > div > div.output")
            function callback3(records) {
            records.forEach(function(record) {
                try
                {
                    console.log(o.firstElementChild.textContent);
                    obj = window.chrome.webview.hostObjects.ahk;
                    obj.func(o.firstElementChild.textContent);
                }
                catch
                {
                    try
                    {
                        obj = window.chrome.webview.hostObjects.ahk;
                        obj.func(o.textContent);
                    }
                    catch
                    {

                    }
                }
            })
            }
            var ob3 = new MutationObserver(callback3)
            ob3.observe(o, {
            characterDataOldValue: true,
            attributes: true,
            childList: true,
            characterData: true,
            subtree: true
            })
        )'
        super.__New(url, input_js, out_put_js,, 'sougou')
    }
    __Delete()
    {
        
    }
}

class Web_cd
{
    __New(url, input_js, output_js, out_change_call_back := unset, ui_name := '翻译')
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
        this.nav_sync.wait()
        this.wv.CoreWebView2.AddHostObjectToScript('ahk', {str:'str from ahk',func:this.on_result_change.Bind(this)})
        this.set_change_event()
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

    set_input_box(text)
    {
        js := Format(this.input_js, text)
        return rtn := this.wv.CoreWebView2.ExecuteScript(js, 0)
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
    set_change_event()
    {
        rtn := this.wv.CoreWebView2.ExecuteScript(this.output_js, 0)
    }
}