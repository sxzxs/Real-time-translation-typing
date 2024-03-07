#Requires AutoHotkey v2.0
#Requires AutoHotkey v2+
#include <Direct2DRender>
#include <zmq>
#include <log>
#include <WebView2>
#include <ComVar>
#include <btt>
#include ./utility/sound.ah2

logger.is_log_open := true
logger.is_use_editor := true

CoordMode('ToolTip', 'Screen')
CoordMode('Mouse', 'Screen')

init()
init()
{
    global g_sound := SoundINput('E:\我的AHK程序\Real-time-translation-typing\语音.html')
    g_sound.show()
}

!i::
{
    js := "
    (
        document.querySelector("#final").innerHTML = '';
        speechRecognition.start();
    )"
    logger.info(js)
    return rtn := g_sound.exec_js_script(js)
}

~*Esc::
~*Enter::
{
    js := "
    (
        speechRecognition.stop();
        location.reload();
    )"
    logger.info(js)
    return rtn := g_sound.exec_js_script(js)
}