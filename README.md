# S1-OrangeX (Android)
本项目为[S1-Orange](https://github.com/wly5556/S1-Orange)的分叉，尝试使用[ArkUI**X**](https://gitcode.com/arkui-x)框架进行跨平台移植。

### 项目状态：
  - 🟢已完成移植，代码共通 
  - 🟡跨平台框架存在缺陷，导致部分功能体验不佳。见下文``缺陷备忘``

#### 跨平台框架相关备忘

| **功能或缺陷**                      | **SDK14** | **SDK16 SDK17** | **SDK19** | **备注**                                                                                               |
|--------------------------------|-----------|-----------------|-----------|------------------------------------------------------------------------------------------------------|
| 相对时间格式化功能异常                    | 🟢        | 🟢              | 🔴        | 日志：[intl_addon.cpp      (FormatRelativeTime)] Get RelativeTimeFormat object failed                   |
| Text仅包含西文内容时，字重变得极细            | 🟢        | 🟢              | 🔴        | 中西文混合的内容没有这个问题                                                                                       |
| 子线程中无法访问vp2px                  | 🔴        | 🔴              |           | 并发线程内未定义vp2px等全局api；hos中子线程可访问全局api                                                                  |
| 导入@kit.ArkTS.JSON使得JSON变为未定义   | 🔴        | 🟢              |           | 不导入时，JSON方法是正常可用的，与预期一致；但若import了JSON模块(`@kit.ArkTS`)，则会导致JSON变为未定义                                  |
| setTimeout不传递delay时不会执行回调      | 🔴        | 🔴              |           | 预期应与delay为0等效                                                                                        |
| textarea点按调整输入位置失效             | 🔴        | 🟢              |           | 表现为点按其它输入位置后，光标显示为移动到该位置，但实际输入位置仍为原先位置<br/> - 单行、多行文本框均有该缺陷，Search输入组件无该缺陷<br/> - 输入法方向键操作可按预期移动输入光标 |
| request.agent不可下载需要header认证的资源 | 🔴        | 🔴              |           | ArkUI-X android桥接实现中，canMakeRequest方法会在发起下载请求前，**额外**发送一次不带header的请求，该请求响应码非200时，中止下载                |
| 组件阴影绘制                         | 🔴        | 🟢              |           | 当前ArkUI-X所有组件都缺失阴影，shadow()接口也不起作用                                                                   |
| Text组件首字符为emoji时，数字样式怪异        | 🔴        | 🔴              | 🟢        | 数字变为emoji一般的样式（但也不是keycap-digit系列emoji），图见下文                                                         |
| Image组件svg图片的fillcolor失效       | 🔴        | 🟢              |           | 已在未来版本中修复[GitCode Issue #6](https://gitcode.com/arkui-x/arkui_for_android/issues/6)                  |
| setColorMode跨平台                | 🔴        | 🔴              |           | 不跟随系统切换深色模式所需                                                                                        |
| displaySync                    | 🟡        | 🟡              |           | Polyfill 到 Animator                                                                                  |
| navigation动态路由表                | 🟡        |                 |           | 退回到@Builder内提供子页面内容的路由模式                                                                             |
| RemoteCommunicationKit.rcp     | 🟡        | 🟡              |           | Polyfill 到 http.HttpRequest                                                                          |
| want.StartAbility              | 🟡        | 🟡              |           | 桥接到Android Intent                                                                                    |
| asset kit                      | 🟡        | 🟡              |           | Polyfill 到 SQLite                                                                                    |
| Clip Board                     | 🟡        | 🟡              |           | 需桥接                                                                                                  |
| systemShare.ShareController    | 🟡        | 🟡              |           | 需桥接                                                                                                  |
| promptAction.showToast文字背景白色缺失 | 🟡        | 🟢              |           | 桥接到Android来避免显示问题                                                                                    |
| SegmentButton组件                | 🟡        | 🟡              |           | 未被支持                                                                                                 |

🔴：问题不可绕过
🟡：问题可绕过
🟢：已解决
空白：暂未测试

具体平台差异代码见``entry/src/main/ets/ArkUIX``

##### 更新记录
- 2025/6/17 加入SDK19的初步试用结果。“Text组件首字符为emoji时，数字样式怪异”的问题得到解决，但新增了问题“Text仅包含西文内容时，字重变得极细”。由于新增“相对时间格式化功能异常”的问题，不使用该版本SDK进行打包。

##### 1. 子线程中访问vp2px
在项目依赖``ImageKnife``中发现，该图像库使用TaskPool线程加载图像，其中用了vp2px将组件vp大小换算成像素大小  
_解决方案:_ 从主线程传递vp与px的比例，具体修改见[commit/5c0a7d4](https://gitee.com/rI6tL9/ImageKnife/commit/5c0a7d4a3db947a8b3a40af0a305eba021fb9875)，故项目内没有直接使用ohpm上的``ImageKnife``，而是单独打包了修改过的库来使用。（``libs/ImageKnife3.2.0.har``）

##### 2. request.agent不可下载需要header认证的资源
对于要求``header``认证的服务端，使用``request.agent``设置``header``并创建下载任务，在hos中可正常下载，但在android arkui-x中却只能触发``task.failed``事件，对于无需认证的服务端则不会出错。    
抓包发现android arkui-x适配层中实现的``request.agent``对于一次下载任务，会发出两次请求；且第一次请求不带有被设定的header。若第一次请求响应码非200，则不会有后续请求。   
查看logcat可注意到如下的报错：
```shell
Response Code: 403
canMakeRequest failed with response code: 403
```
于是反编译并搜索``canMakeRequest``可在``ohos.ace.plugin.taskmanagerplugin.DownloadImpl``中找到``canMakeRequest``方法如下：
```java
public boolean canMakeRequest(String urlString) {
    String logMessage = new StringBuilder().append("Download: start download manager service, downloadUrl: ").append(urlString).toString();
    Log.i("RequestAndroid", logMessage);
    boolean result = false;
    try {
        URL url = new URL(urlString);
        HttpURLConnection httpConnection = (HttpURLConnection) url.openConnection();
        httpConnection.setConnectTimeout(5000);
        httpConnection.connect();
        int responseCode = httpConnection.getResponseCode();
        Log.i("RequestAndroid", new StringBuilder().append("Response Code: ").append(responseCode).toString());
        if (responseCode == 200) {
            Log.i("RequestAndroid", "canMakeRequest success");
            result = true;
            return result;
        } else {
            Log.i("RequestAndroid", new StringBuilder().append("canMakeRequest failed with response code: ").append(responseCode).toString());
        }
    } catch (Exception e) {
        e.printStackTrace();
        Log.i("RequestAndroid", "canMakeRequest failed due to exception");
    }
    return result;
}
```
可见在android arkui-x适配层，下载前有测试“能否发起请求”的逻辑。该次请求中，未附带此前向``request.agent``接口提供的header，而且一旦响应码非200，就认为“无法连接”，直接导致了无法发起需要认证的下载任务。

##### 3. Text组件首字符为emoji时，数字样式怪异
Text组件首字符为emoji时，数字变为emoji一般的样式，与emoji等宽：     
<img height="50px" src="https://p.sda1.dev/22/a54f8dcc5636efd88fc0c04d81e6fb26/abnormal.png"/>     
首字符非emoji时，则正常显示     
<img height="50px" src="https://p.sda1.dev/22/d235d952036b2d7b16d1f30f025d26bd/normal.png"/>


## （源仓库README)

  <div style="display: flex; align-items: center;">
    <img src="entry/src/main/resources/base/media/app_icon_center.png" alt="App Icon" width="64" height="64" style="margin-right: 16px;" />
    <h1 style="font-size: 2.4em; margin: 0;"><strong>S1-Orange</strong></h1>
  </div>
  <br />
  <p>
    <a href="https://github.com/wly5556/S1-Orange/releases">
      <img src="https://img.shields.io/github/v/release/wly5556/S1-Orange" alt="GitHub Release" />
    </a>
  </p>

**专为鸿蒙Next开发的 [stage1st.com](https://stage1st.com/) 移动客户端**   
最低SDK版本: **12**

## 功能
详情查看[论坛专楼](https://stage1st.com/2b/thread-2244111-1-1.html)内的说明

## 安装使用

遵循鸿蒙Next的一般[应用开发运行步骤](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/ide-run-device-V5)：在您的设备上，开启开发者模式，将设备连接到PC端开发者套件；在开发者工具中构建并安装应用到设备上。

可以在这里[阅读更详细的步骤说明](https://stage1st.com/2b/forum.php?mod=redirect&goto=findpost&ptid=2244111&pid=67282974)。

## 获取更新

应用支持启动时自动检查是否有新版本。检测到新版本时会弹窗提醒，“关于”页面可调整检查更新间隔，或关闭自动检查。也可自行从最新源代码构建更新的版本。

对于版本号变动，在github releases和[论坛专楼](https://stage1st.com/2b/thread-2244111-1-1.html)内会提供版本说明。

## 衍生项目
[S1-OrangeX](https://github.com/cG77hR/S1-OrangeX): 利用ArkUI-X让本项目跨平台到Android来使用的实验性项目

## 协议和贡献

采用Apache License 2.0开源协议，欢迎任何反馈和贡献🥳

## 第三方开源协议

- [S1-Next](https://github.com/ykrank/S1-Next/blob/master/LICENSE.md) 特别感谢S1-Next项目，能让我免于在界面设计和对接论坛api上花费大量精力，能够在较短的时间内开发本项目

- [ImageKnife](https://gitee.com/openharmony-tpc/ImageKnife/blob/master/LICENSE)

## 界面截图

![界面截图](https://p.sda1.dev/22/ad8fdfe7c16a2d3cec953e2eca6d7970/overview.png)
