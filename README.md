# Real-time-translation-typing
![Alt text](screenshots.gif)

## 快捷键
* alt + y: 打开

![图 0](images/16771b28ffa808f0c407a1248a0c8a1775923cd97135443f8899d0adb9a668bc.png)  


* alt + enter:发音
* enter: 输出文本
* ESC: 退出


## 翻译API
通过配置文件来配置 `/config/setting.json`

* 有道词典
```
{
    "cd" : "youdao",
    "BaiduFanyiAPPID" : "",
    "BaiduFanyiAPPSEC": "",
    "is_baidu_real_time_translate" : 0
}
```

* 百度翻译
需要自己注册后，把key填到配置文件
http://api.fanyi.baidu.com/api/trans/product/index

```
{
    "cd" : "baidu",
    "BaiduFanyiAPPID" : "xxxxx",
    "BaiduFanyiAPPSEC": "xxxxx",
    "is_baidu_real_time_translate" : 0
}
```
因为百度使用次数有限额，因此通过  `is_baidu_real_time_translate` 来配置是否实时触发翻译
当配置 `0` 时，需要输入 `空格` 键 主动翻译, 建议输入最后键入`空格`

* 切换
按 `tab`键，切换结果为另外一个, `空格键`切换回来