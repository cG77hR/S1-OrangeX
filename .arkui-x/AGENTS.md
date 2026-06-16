# AGENTS.md（ArkUI-X 跨平台分支）

本文件面向 AI 协作者与接手开发者，说明 **S1-OrangeX**（S1-Orange 的跨平台分叉）相对于源仓库 [S1-Orange](https://github.com/wly5556/S1-Orange)（git `upstream`）所做的**偏离**，以及开发/合并时必须遵守的跨平台约定。

> 根目录的 `AGENTS.md`（来自 upstream）描述的是源项目的业务架构；本文件描述的是跨平台分支特有的差异。业务逻辑以根目录为准，跨平台机制以本文件为准。

## 项目定位

- 本仓库 = `origin`（`cG77hR/S1-OrangeX`），用 [ArkUI-X](https://gitcode.com/arkui-x) 把 HarmonyOS 代码跨平台到 Android（iOS 为占位）。
- 源仓库 = `upstream`（`wly5556/S1-Orange`），纯 HarmonyOS Next。
- 目标：**代码共通**。同一份 `entry/src/main/ets` 源码在两端都编译运行；平台差异用运行时分支隔离。
- 当前分支已启用 **SDK26**。涉及兼容性判断时，以 **README 的 SDK26 列 + 当前代码** 为准。

## 目录结构（相对源仓库的增量）

```
.arkui-x/                         ArkUI-X 工程壳（Android/iOS 原生层）
  android/app/src/main/java/io/github/wly5556/s1orangeX/
    Bridge.java                   原生桥：剪贴板/分享/Toast/状态栏/夜间模式/键盘/选图/下载 等
    EntryEntryAbilityActivity.java Activity：窗口 insets（状态栏/导航栏/键盘）回调
    MyApplication.java
  ios/...                         iOS 占位（未完整适配）
  arkui-x-config.json5            crossplatform:true，声明跨平台模块

entry/src/main/ets/ArkUIX/        ★ 跨平台适配层（本分支独有）
  PlatformInfo.ets                PlatformInfo.getPlatform() -> HARMONYOS/ANDROID/IOS/UNKNOWN
  BridgeFunction.ets              PlatformBridge：调用原生 Bridge.java 的 TS 侧单例
  Asset/                          asset store：HOS 用系统 asset；Android polyfill 到 SQLite（工厂模式）
  DisplaySync/                    displaySync：HOS 用系统 API；Android polyfill 到 Animator（工厂模式）
  Rcp/                            网络层：HOS 用系统 rcp；Android polyfill 到 @ohos.net.http（工厂模式）
  Utils/
    ShareKit.ets / ShowToast.ets / WantUitl.ets / SetNightMode.ets / SetStatusBarColor.ets
    Download.ets / PhotoViewPicker.ets / ReleasePage.ets
```

## 合并 upstream 的标准流程

```
git fetch upstream
git merge upstream/main        # 必然会有冲突，按下方清单逐个解决
```

**不要**用 `git pull --rebase`：本仓库的历史刻意保留 merge commit，便于追溯每次同步的适配内容。

### 每次合并必须重点检查的冲突/适配点

以下几类是**反复出现**的合并冲突源与兼容隐患，逐项核对：

> ⚠️ **关键认知：git 解决冲突 ≠ 合并完成。** 有冲突标记（`<<<<<<<`）的文件只是冰山一角。upstream 的很多写法在 HOS 上正确、但 ArkUI-X 上语义不同，git 会**毫无提示地自动合入**这类代码——它们不会触发 conflict，却会导致 Android 端功能静默失效（典型表现：页面跳转正常、标题栏正常，内容区空白）。因此合并后**必须逐文件人工审查 upstream 引入的全部改动**（`git diff <merge-base> upstream/main`），重点扫 `entry/src/main/ets` 下新增/改动的 `.ets`，不能只盯着 `git status` 里的 `UU`。下面几条适配点，既适用于有冲突的文件，也适用于自动合入的文件。

#### 1. import 路径：`common/*` → `ArkUIX/Utils/*`（最高频）

源仓库把跨平台敏感的工具函数放在 `common/`（如 `common/WantUitl.ets`、`common/ShareKit.ets`、`common/theme/SetStatusBarColor.ets`）。本分支把它们的跨平台实现迁移到了 `entry/src/main/ets/ArkUIX/Utils/`，并把 `common/` 下同名文件**清空（仅留注释占位）**以防被自动合入：

```ts
// common/WantUitl.ets、common/ShareKit.ets 的全部内容
// 功能已全部迁移到 src/main/ets/ArkUIX/Utils/...
// 保留这个文件防止意外的自动合并
```

合并时如果 upstream 给某个 `common/Xxx.ets`（已被清空的）加了新内容，**不要直接采用 upstream 的版本**——而是把新逻辑/新函数移植到对应的 `ArkUIX/Utils/Xxx.ets`，再让调用方 import 自 `ArkUIX/Utils/`。

**判断原则**：凡是涉及“打开浏览器 / 复制 / 分享 / Toast / 状态栏 / 夜间模式 / 下载 / 选图 / Want 跳转”的工具函数，import 一律指向 `ArkUIX/Utils/`。`ShowToast` 必须用 `ArkUIX/Utils/ShowToast`（见下“缺陷备忘”）。

#### 2. 新增 NavDest 页面：必须同时进 `PageNameEnum` 的 @Builder 分发表

这是**本分支最关键的架构差异**。源仓库用 `resources/base/profile/route_map.json` 的**动态路由表**注册子页面；但 **ArkUI-X 不支持动态 route_map**，因此本分支退回到 `@Builder` 分发模式：

```ts
// pages/PageNameEnum.ets —— 本分支独有 buildNavDestPage()
@Builder
export function buildNavDestPage(name: string) {
  if (name == PageNameEnum.AboutApp) { AboutApp() }
  else if (...) { ... }
  // ★ upstream 新增的每个页面，都要在这里加一条 else if 分支
}
```

`NavigationPage.ets` 里用 `.navDestination(buildNavDestPage)` 挂载它。

**合并新增页面时必须三处齐全**（比 upstream 的“三处”多一处）：
1. `pages/NavDest/XxxPage.ets`（upstream 新增，自动合入）；
2. `pages/PageNameEnum.ets` 枚举值 `Xxx`（自动合入）；
3. `resources/base/profile/route_map.json`（**保留**，自动合入；ArkUI-X 虽不用，但留着以减少与 upstream 的无谓偏离）；
4. ★ **本分支额外**：`pages/PageNameEnum.ets` 顶部 import `{ XxxPage }` + `buildNavDestPage()` 内加 `else if (name == PageNameEnum.Xxx) { XxxPage() }`。

#### 3. 设置项组件：当前 SDK26 分支保持 `SegmentButton`

README 兼容性表已将 `SegmentButton` 标记为 **SDK26 可用**。因此：

- **合并 upstream 新增的设置项组件时，默认保留 upstream 的 `SegmentButton` 写法**，与根目录 `AGENTS.md` 中的设置项模式保持一致。
- 只有在当前 SDK26 环境里已经确认存在兼容问题时，才考虑改成别的控件方案。

#### 4. 网络请求：保留 `Rcp`/`IRcpSession` 抽象，不要采用 upstream 的直接 rcp 调用

源仓库的 `api/request.ets` 直接用 `@kit.RemoteCommunicationKit` 的 `rcp`；但 ArkUI-X 的 rcp 实现不可用，本分支用工厂模式 polyfill 到 `@ohos.net.http`：

```
ArkUIX/Rcp/Rcp.ets           Rcp.createSession(config) —— 按平台选择 factory
  ├─ RcpLocal.ets            HOS：rcp.Session（含会话数 16 上限的 Queue 重试）
  └─ RcpArkUIX.ets           Android：http.HttpRequest，body 为 ArrayBuffer
```

`api/request.ets` 里 `wrapper()` 用 `IRcpSession` / `RcpResponse`（本分支的抽象类型）而非 `rcp.Session` / `rcp.Response`。

**合并冲突处理**：upstream 常在 `request.ets` 里用 `rcp.createSession` / `rcp.Session` / `rcp.Response`。若改动是**逻辑性**的（如重排 if 分支、修 bug），吸收进本分支的 `wrapper`；若是**类型替换**（`IRcpSession`→`rcp.Session`），**丢弃 upstream 的改动，保留本分支的抽象**。

**新增的、独立的网络请求文件**若直接用了 `rcp.createSession`，**必须改写**为 `Rcp.createSession` + `IRcpSession`：
- `resp` 类型从 `rcp.Response` 改为 `RcpResponse`（或用 `IRcpSession` 推断）；
- `RcpResponse.body` 是 `ArrayBuffer | undefined`（Android）或 `string | ArrayBuffer`（HOS），用 `typeof body === 'string'` 判别；
- `rcpCookie2string` 仍从 `api/request.ets` 导出（本分支保留了这个 export，被 `RcpArkUIX.ets` 使用）。

##### `request` 构造器的 base/path 必须分离（极易漏，且不触发 conflict）

`new request<T>(path, base)`：`base` 默认 `URL.BASE`（mobile api），`sessionConfig.baseAddress = base`。请求时 `wrapper` 调 `session.get(path)`/`session.post(path, ...)`，最终 URL 由各平台的 session 实现决定：

- **HOS**（`RcpLocal`）：原生 `rcp` 当 `path` 是绝对 URL（`http://...`）时**忽略** `baseAddress`，所以 `new request(URL.WEB_BASE + URL.XXX)` 这种「把完整 URL 塞进 path」的写法在 HOS 上正常工作。
- **Android**（`RcpArkUIX`）：`send` 里是朴素的字符串拼接 `url = (baseAddress ?? '') + path`。若 path 是完整 URL，会拼出 `https://stage1st.com/2b/api/mobile/https://stage1st.com/2b/...` 这种**嵌套非法 URL**，请求失败，被业务层 `try/catch` 静默吞掉 → 页面有标题、内容空白。

**规则：请求 `WEB_BASE`/`APP_BASE` 域的接口，必须把域名作为第二参 `base` 传入，path 用相对路径。** 这也是本仓库所有既有页面的统一写法，对照即可：

```ts
// ✅ 正确：base/path 分离
new request<string>(URL.RATING_QUOTA, URL.WEB_BASE)   // PostRatingDetail
new request<string>(URL.REPORT_POST, URL.WEB_BASE)    // ReportPost

// ❌ 错误：完整 URL 塞进 path，base 仍是 URL.BASE（Android 上 URL 嵌套失效）
new request<string>(URL.WEB_BASE + URL.DARKROOM)
```

合并时若发现 upstream 新代码里有 `new request(..., )` 的第一参是完整 `http(s)://` URL（或拼接了 `URL.WEB_BASE`/`URL.APP_BASE`），**必须拆成 base + 相对 path**。这类问题 git 不会报 conflict，只能靠人工 diff 审查发现。

## 平台分支模式（运行时判断）

所有跨平台分歧统一用 `PlatformInfo.getPlatform()` 分支，**不要**用编译期条件。两种等价写法：

```ts
// 写法 A：调用处分支（用于工具函数内部，如 ShowToast / ShareKit）
import { PlatformInfo, PlatformTypeEnum } from '../ArkUIX/PlatformInfo'
if (PlatformInfo.getPlatform() == PlatformTypeEnum.HARMONYOS) {
  // 系统 API 实现
} else if (PlatformInfo.getPlatform() == PlatformTypeEnum.ANDROID) {
  PlatformBridge.xxx(...)   // 调原生
}

// 写法 B：工厂模式（用于有会话/状态的对象，如 Rcp / DisplaySync / Asset）
// 定义 interface + Local/ArkUIX 两份实现 + 静态 factory 按平台选其一
// 见 ArkUIX/Rcp/Rcp.ets、ArkUIX/DisplaySync/DisplaySync.ets、ArkUIX/Asset/AssetStore.ets
```

**何时用工厂模式**：当实现需要持有状态/对象（如网络会话、动画控制器、数据库连接）时，用 interface + factory；当只是无状态的工具调用时，直接 `if` 分支即可。

新增跨平台能力时：能用纯 TS polyfill 的直接写在公共代码；需要原生能力的（剪贴板、分享、Toast、夜间模式、选图、下载、状态栏、键盘），走下面的 Bridge。

## Bridge（原生层）扩展

新增需要原生支持的能力时，三处同步：

1. `ArkUIX/BridgeFunction.ets`：`BridgeFunction` 枚举加一项 + `PlatformBridgeClass` 加一个 async 方法（`callMethod`）。
2. `.arkui-x/android/app/src/main/java/io/github/wly5556/s1orangeX/Bridge.java`：加 `@Method` 注解的 public 方法。
3. 若是回调型（如 `onWindowInsetsListener`、`onPhotoPickerResult`），用 `registerMethod` + `pushRegisterMethod`（见 `BridgeFunction.ets`），并在 `rebindListeners` 里能自动重绑。

**约定**：bridge 返回值用基础类型（number/string/number[]），复杂对象在 TS 侧组装。窗口 insets 回调目前传 `(statusBar, navigationBar, keyboard)` 三参。

## 安全区/键盘高度

- HOS：`EntryAbility` 用 `window.setWindowLayoutFullScreen` + `avoidAreaChange` 监听，把 `SafeArea.top/bottom/keyboard` 写入 `AppStorage`。
- Android：通过 `Bridge.onWindowInsetsListener` 回调，由 `EntryEntryAbilityActivity` 用 `WindowInsetsCompat` 计算三值后回传。
- 两端都写入同一组 `AppStorage(SafeArea.*)` key，UI 层用 `@StorageProp` 消费，无需关心平台。

## 缺陷备忘（开发与合并时易踩坑，详见 README 表）

- **`promptAction.showToast`（SDK26 🟢，但仍统一封装）** → 当前 SDK26 上 README 已标记为已解决，但业务代码仍应一律走 `ArkUIX/Utils/ShowToast`，由它在 Android 侧桥接到原生 Toast。这样可以保持平台行为一致，也避免后续回归时到处排查。
- **`Text` 首字符 emoji 时数字样式怪异（SDK14 🔴 / SDK19 🟢）**、**仅西文时字重变细（SDK19 🔴）**：UI 表现层问题，留意数字/西文渲染。
- **`setColorMode` 跨平台（SDK26 🟡）**：不要把业务逻辑直接绑到 `context.setColorMode` 上。深浅色模式在 Android 继续走 `PlatformBridge.setNightMode` + 手动维护 `AppStorage(PropKey.currentColorMode)`（见 `ArkUIX/Utils/SetNightMode.ets` 与 `EntryAbility.ets`），业务代码统一走 `SetNightMode()`。
- **`request.agent` 下载需 header 认证时失败（🔴）**：Android 桥接层 `canMakeRequest` 会额外发一次不带 header 的预请求。用 `DownloadFile`（`ArkUIX/Utils/Download.ets`）规避，**不要**直接用 `request.agent`。
- **`Image` svg `fillColor`（SDK26 🟢）**：当前可正常使用 `.fillColor(...)`。涉及 svg 图标着色时按现有写法保持即可。
- **组件阴影 `shadow()` 失效（🔴）**：避免依赖阴影做视觉区分。
- **`geometryTransition` 落点偏移**：`ThreadPostList` 里图片预览转场被临时改为 `TransitionEffect.opacity(0)`，合并 upstream 对该转场的改动时不要盲目恢复。
- **子线程内 `vp2px` 未定义（🔴）**：`ImageKnife` 用了修改过的 har（`libs/ImageKnife3.2.0.har`），从主线程传 vp/px 比例；**不要**替换成 ohpm 上的原版。
- **`setTimeout` 不传 delay 不执行回调（🔴）**：始终显式传 `delay`（哪怕是 0）。
- **ArkTS 声明式 Builder 分支里不要擅自提取局部变量**：像 `if (...) { Xxx({ prop: someCall() }) }` 这种 upstream 原写法，迁移时**不要**为了“避免重复调用”改成 `const v = someCall(); if (v !== undefined) { Xxx({ prop: v }) }` 再直接塞进 `@Builder` / `ForEach` / `if` 的 UI 分支里。ArkTS 对声明式语法比普通 TS 更严格，这类局部声明很容易直接语法错误。若确实要消除重复调用，优先提到普通方法里，或先确认该位置允许局部变量声明。
- **`getComponentSnapshot` / 界面安全区监听（SDK26 🟢）**：这两项是当前可依赖能力。长截图与 Android 安全区桥接都基于它们实现。
- **`request.agent`/相对时间格式化/JSON import 等 SDK 版本相关缺陷**：统一看 README 兼容性表的 **SDK26** 列。
- **`Image` svg 仅支持 `path` 格式**：`<Rect><Rect /><g> ... <g/>` 这类 svg 图标仍可能不受支持，替换图标资源时留意。

## 提交习惯

- 如果有重大适配问题或改动，在 merge commit 的 message 里直接写明。

## 快速自检清单（合并/新增功能后逐项过一遍）

- [ ] `git status` 无残留 `UU`（未解决冲突）。
- [ ] `findstr /s /n "<<<<<<< >>>>>>>"` 在 `entry/src/main/ets` 下无命中。
- [ ] **已审查 `git diff <merge-base> upstream/main` 的全部改动**，不只看有 conflict 的文件——auto-merged 的文件同样可能含跨平台缺陷（见上 §4「base/path 分离」）。
- [ ] 新增的 NavDest 页面是否进了 `buildNavDestPage()` 分发表 + import。
- [ ] 新增的设置项组件是否沿用了当前的 `SegmentButton` 模式。
- [ ] 新增的网络请求是否走 `Rcp`/`IRcpSession` 而非直接 `rcp`。
- [ ] **新增的网络请求是否 `new request(path, base)` 分离写法**——第一参不得是完整 `http(s)://` URL 或拼接了 `URL.WEB_BASE`/`URL.APP_BASE`。
- [ ] 所有 `ShowToast` / `openInBrowser` / `CopyText` / `ShareXxx` 是否 import 自 `ArkUIX/Utils/`。
- [ ] upstream 引入的 `promptAction.showToast` 是否已替换为 `ShowToast`。
- [ ] `setColorMode` 调用是否走 `SetNightMode()`。
- [ ] 若在 `@Builder` / `ForEach` / 声明式 `if` 分支里为了“提取重复调用”改写了 upstream 代码，是否确认该位置允许局部变量声明，未引入 ArkTS 语法错误。
- [ ] 平台相关常量/链接（如 releases）是否按平台区分。

## 环境

- Windows 环境（`cmd.exe`），无 `grep/head/tail`，用 `findstr`。
- 构建需 DevEco Studio IDE（含 ArkUI-X 插件），命令行不编译。
- Android 子工程用 Gradle（`.arkui-x/android`），版本固定见 `build.gradle` / `gradle-wrapper.properties`。
