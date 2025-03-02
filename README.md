# S1-OrangeX (Android)
本项目为[S1-Orange](https://github.com/wly5556/S1-Orange)的分叉，尝试使用[ArkUI**X**](https://gitcode.com/arkui-x)框架进行跨平台移植。

### 项目状态：

- **ArkUIX SDK14**: 
  - 🟢整体已完成移植，逻辑代码共通 
  - 🟡跨平台框架存在缺陷，导致部分功能体验不佳。见下文``缺陷备忘``

#### 跨平台框架缺陷备忘

| **功能或缺陷**                      | **SDK14** | **SDK16（未发布）** | **备注**                                                                                               |
|--------------------------------|-----------|----------------|------------------------------------------------------------------------------------------------------|
| 子线程中访问vp2px                    | 🔴        |                | 并发线程内未定义vp2px等全局api；hos中子线程可访问全局api<br/> - 导致需要修改依赖ImageKnife来使应用功能正常                                |
| 导入@kit.ArkTS.JSON使得JSON变为未定义   | 🔴        |                | 不导入时，JSON方法是正常可用的，与预期一致；但若import了JSON模块，则会导致JSON变为未定义                                                |
| setTimeout不传递delay时不会执行回调      | 🔴        |                | 预期应与delay为0等效                                                                                        |
| textarea点按调整输入位置失效             | 🔴        |                | 表现为点按其它输入位置后，光标显示为移动到该位置，但实际输入位置仍为原先位置<br/> - 单行、多行文本框均有该缺陷，Search输入组件无该缺陷<br/> - 输入法方向键操作可按预期移动输入光标 |
| request.agent不可下载需要header认证的资源 | 🔴        |                | ArkUI-X android桥接实现中，canMakeRequest方法会在发起下载请求前，**额外**发送一次不带header的请求，该请求响应码非200时，中止下载                |
| 组件阴影绘制                         | 🔴        |                | 当前ArkUI-X所有组件都缺失阴影，shadow()接口也不起作用                                                                   |
| Image组件svg图片的fillcolor失效       | 🔴        | 🟢             | 已在未来版本中修复[GitCode Issue #6](https://gitcode.com/arkui-x/arkui_for_android/issues/6)                  |
| setColorMode跨平台                | 🔴        | 🟢             | 处理深色模式所需。自 API16 支持                                                                                  |
| displaySync                    | 🟡        |                | Polyfill 到 Animator                                                                                  |
| navigation动态路由表                | 🟡        |                |                                                                                                      |
| RemoteCommunicationKit.rcp     | 🟡        |                | Polyfill 到 http.HttpRequest                                                                          |
| want.StartAbility              | 🟡        |                | 桥接到Android Intent                                                                                    |
| asset kit                      | 🟡        |                | Polyfill 到 SQLite                                                                                    |
| Clip Board                     | 🟡        |                | 需桥接                                                                                                  |
| systemShare.ShareController    | 🟡        |                | 需桥接                                                                                                  |
| promptAction.showToast文本背景缺失   | 🟡        |                | 桥接到Android来避免显示问题                                                                                    |
| SegmentButton组件                | 🟡        | 🟢             | 自 API16 支持                                                                                           |

具体平台差异代码见``entry/src/main/ets/ArkUIX``内

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
    <a href="https://hits.seeyoufarm.com">
      <img src="https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Fwly5556%2FS1-Orange&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits" alt="Hits" />
    </a>
  </p>


**专为鸿蒙Next开发的 [bbs.saraba1st.com](https://bbs.saraba1st.com/) 移动客户端**   
最低SDK版本: **12**

## 功能
详情查看[论坛专楼](https://bbs.saraba1st.com/2b/thread-2244111-1-1.html)内的说明

## 安装使用

遵循鸿蒙Next的一般[应用开发运行步骤](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/ide-run-device-V5)：在您的设备上，开启开发者模式，将设备连接到PC端开发者套件；在开发者工具中构建并安装应用到设备上。

可以在这里[阅读更详细的步骤说明](https://bbs.saraba1st.com/2b/forum.php?mod=redirect&goto=findpost&ptid=2244111&pid=67282974)。

## 获取更新

目前应用内没有主动获取更新的功能，需要自行从最新源代码构建更新的版本。对于版本号变动，在github releases和[论坛专楼](https://bbs.saraba1st.com/2b/thread-2244111-1-1.html)内会提供版本说明。

## 衍生项目
[S1-OrangeX](https://github.com/cG77hR/S1-OrangeX): 利用ArkUI-X让本项目跨平台到Android来使用的实验性项目

## 协议和贡献

采用Apache License 2.0开源协议，欢迎任何反馈和贡献🥳

## 第三方开源协议

- [S1-Next](https://github.com/ykrank/S1-Next/blob/master/LICENSE.md) 特别感谢S1-Next项目，能让我免于在界面设计和对接论坛api上花费大量精力，能够在较短的时间内开发本项目

- [ImageKnife](https://gitee.com/openharmony-tpc/ImageKnife/blob/master/LICENSE)

## 界面截图

![界面截图](https://p.sda1.dev/22/ad8fdfe7c16a2d3cec953e2eca6d7970/overview.png)
