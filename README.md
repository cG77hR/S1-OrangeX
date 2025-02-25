# S1-OrangeX (Android)
本项目为[S1-Orange](https://github.com/wly5556/S1-Orange)的分叉，尝试使用[ArkUI**X**](https://gitcode.com/arkui-x)框架进行跨平台移植。

### 项目状态：

- **ArkUIX SDK14**: 🟢整体已完成移植，逻辑代码共通 🟡跨平台框架存在缺陷，导致部分功能体验不佳

#### 跨平台框架缺陷备忘

| **功能**              | **SDK14** | **SDK16（未发布）** | **备注**                                                                     |
|---------------------|-----------|----------------|----------------------------------------------------------------------------|
| vp2px               | 🔴        |                | 并发线程内未定义，与鸿蒙平台运行时差异                                                        |
| setTimeout          | 🔴        |                | 有时不触发更新，与鸿蒙平台运行时差异                                                         |
| svg fill color      | 🔴        |                | [GitCode Issue #6](https://gitcode.com/arkui-x/arkui_for_android/issues/6) |
| setcolormode        | 🔴        | 🟢             | 支持 since API16                                                             |
| textarea 光标错误       | 🔴        |                | 光标显示异常                                                                     |
| request.agent 下载403 | 🔴        |                | 403 下载错误                                                                   |
| displaySync         | 🟡        |                | 需 Polyfill                                                                 |
| navigation          | 🟡        |                | 不支持路由表（可绕过）                                                                |
| rcp                 | 🟡        |                | 需 Polyfill                                                                 |
| segment button      | 🟡        | 🟢             | 支持 since API16                                                             |
| want                | 🟡        |                | 需 Polyfill                                                                 |
| asset               | 🟡        |                | 需 Polyfill → SQLite                                                        |
| clip board          | 🟡        |                | 需 Polyfill                                                                 |
| share               | 🟡        |                | 需 Polyfill                                                                 |
| toast               | 🟡        |                | 需 Polyfill                                                                 |
| executeSync         | 🟡        |                | 多行错误（轻微）                                                                   |
| fullscreen          | 🟡        |                | 与声称功能不一致（轻微）                                                               |

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
查看[论坛专楼](https://bbs.saraba1st.com/2b/thread-2244111-1-1.html)内的说明

## 安装使用

遵循鸿蒙Next的一般[应用开发运行步骤](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/ide-run-device-V5)：在您的设备上，开启开发者模式，将设备连接到PC端开发者套件；在开发者工具中构建并安装应用到设备上。

可以在这里[阅读更详细的步骤说明](https://bbs.saraba1st.com/2b/forum.php?mod=redirect&goto=findpost&ptid=2244111&pid=67282974)。

## 获取更新

目前应用内没有主动获取更新的功能，需要自行从最新源代码构建更新的版本。对于版本号变动，在github releases和[论坛专楼](https://bbs.saraba1st.com/2b/thread-2244111-1-1.html)内会提供版本说明。

## 协议和贡献

采用Apache License 2.0开源协议，欢迎任何反馈和贡献🥳

## 第三方开源协议

- [S1-Next](https://github.com/ykrank/S1-Next/blob/master/LICENSE.md) 特别感谢S1-Next项目，能让我免于在界面设计和对接论坛api上花费大量精力，能够在较短的时间内开发本项目

- [ImageKnife](https://gitee.com/openharmony-tpc/ImageKnife/blob/master/LICENSE)

## 界面截图

![界面截图](https://p.sda1.dev/22/ad8fdfe7c16a2d3cec953e2eca6d7970/overview.png)