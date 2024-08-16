```
████████╗██╗   ██╗██████╗ ██╗███╗   ██╗ ██████╗     ████████╗██████╗  █████╗ ███╗   ██╗███████╗██╗      █████╗ ████████╗██╗ ██████╗ ███╗   ██╗
╚══██╔══╝╚██╗ ██╔╝██╔══██╗██║████╗  ██║██╔════╝     ╚══██╔══╝██╔══██╗██╔══██╗████╗  ██║██╔════╝██║     ██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║
   ██║    ╚████╔╝ ██████╔╝██║██╔██╗ ██║██║  ███╗       ██║   ██████╔╝███████║██╔██╗ ██║███████╗██║     ███████║   ██║   ██║██║   ██║██╔██╗ ██║
   ██║     ╚██╔╝  ██╔═══╝ ██║██║╚██╗██║██║   ██║       ██║   ██╔══██╗██╔══██║██║╚██╗██║╚════██║██║     ██╔══██║   ██║   ██║██║   ██║██║╚██╗██║
   ██║      ██║   ██║     ██║██║ ╚████║╚██████╔╝       ██║   ██║  ██║██║  ██║██║ ╚████║███████║███████╗██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║
   ╚═╝      ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═══╝ ╚═════╝        ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
```
# Real-time-translation-typing
![图 1](images/cd51c69e870ecaf0daa9a115145ac94fc979770772a913fe31d85c015000d6ed.gif)  

![图 0](images/16771b28ffa808f0c407a1248a0c8a1775923cd97135443f8899d0adb9a668bc.png)  
## 功能
* 实时打字翻译
* 实时语音转文字并翻译
* LOL 语音转文字输入
## 快捷键
* ALT Y: 打开
* ALT ENTER:发音
* ENTER: 输出翻译文本
* CTRL ENTER: 输出原始文本
* ESC: 退出
* TAB: 切换另一个翻译API
* CTRL F7: 网页版调试
#### 网页版额外快捷键
* CTRL + C :复制结果
* CTRL + ALT + Y :翻译当前粘贴板
* CTRL + V:打开状态下，输入粘贴板内容
* ALT + I:语音输入
* xbutton1: LOL语音输入触发
* xbutton2: LOL语音输入结束

## 网页调用版本(推荐)
目前支持 搜狗、百度、有道
|环境|版本|
|-|-|
|系统|需要**win10**或者安装 **[webview2 runtime](https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/3c9f7ac6-fb0a-4eb7-b1fd-44c57613a3f5/MicrosoftEdgeWebView2RuntimeInstallerX64.exe)**|
|源码运行需要 ahk 版本| [autohotkey v2H](https://github.com/thqby/AutoHotkey_H/releases)|

## API版本(不推荐)
通过配置文件来配置 `/config/setting.json`

* 选择主翻译API
```
    "cd" : "youdao"   ## 目前支持 "baidu", "google"(需要科学上网，且美国节点), "youdao", "sougou"
```
备选API需配置 `is_open` 为 1
如果没反应，可能api在维护，可以切换另一个使用
目前免费的是有道和搜狗和谷歌， 有道是直接调用的api速度比较快，搜狗是爬虫(速度较慢),谷歌需要翻墙
百度结果很不错，但是需要注册(免费100w字符/月)


* 有道词典
```
http://fanyi.youdao.com/translate?smartresult=dict&smartresult=rule&smartresult=ugc&sessionFrom=null
{
    "is_open" : 1
}
```

```
https://fanyi.sogou.com/text?keyword=%E4%BD%A0%E5%A5%BD&transfrom=auto&transto=en&model=general
    "sougou" :
    {
        "is_open" : 1,
        "is_real_time_translate" : 1
    },
```

* 谷歌
```
{
    "is_open" : 0,
    "is_real_time_translate" : 0
}
```

* 百度翻译
需要自己注册后，把key填到配置文件
http://api.fanyi.baidu.com/api/trans/product/index

```
{
    "is_open" : 0,
    "BaiduFanyiAPPID" : "xxxxx",
    "BaiduFanyiAPPSEC": "xxxxx",
    "is_real_time_translate" : 0
}
```
因为百度使用次数有限额，因此通过  `is_baidu_real_time_translate` 来配置是否实时触发翻译
当配置 `0` 时，需要输入 `空格` 键 主动翻译, 建议输入最后键入`空格`

* 切换

按 `tab`键，从配置和打开的API切换
##  AI 超市 302.AI
**产品简介**:
[302.AI](https://302.ai/)是一个汇集全球顶级品牌的AI超市，按需付费，零月费，零门槛使用各种类型AI。  
**[手机号注册](https://dash.302.ai/register)**:立即获得1PTC免费测试额度。  
**功能全面**: 将最好用的AI集成到平台，不限于AI聊天，图片处理/生成，视频生成，全方位覆盖。  
**简单易用**: 我们提供机器人，工具和API多种使用方法，可以满足从小白到开发者多种角色的需求。  
**按需付费，零门槛**: 按需付费，全部开放，充值余额永久有效。  
**管理者和使用者分离**: 管理者一键分享，使用者无需登录。让懂AI的人来配置，简化使用流程。
