import { OuterScroller } from '../../common/component/OuterScroller'
import { TitleBar } from '../../common/component/TitleBar'
import { ImageCachePref } from '../../common/component/preference/ImageCachePref'
import { ImageKnife } from '@ohos/imageknife'
import { clearAvatarCache } from '../../common/component/Avatar'
import { AvatarCachePref } from '../../common/component/preference/AvatarCachePref'
import { ThemeSelectPanel } from '../../common/component/preference/ThemeSelect'
import { AppThemeColor } from '../../common/theme/basic/basic'
import { PreferenceManager } from '../../config/UserConfig'
import { common, ConfigurationConstant } from '@kit.AbilityKit'
import { PreferenceState } from '../NavProvider/NavigationPage'
import { FontSize, FontSizeEnum, FontSizeSetup } from '../../common/fontSize/FontSizeEnum'
import {
  ContentFontSizeOverridePref,
  FontOverrideModeDesc
} from '../../common/component/preference/ContentFontSizeOverridePref'
import { openOrJumpTo } from '../SingletonPage'
import { PageNameEnum } from '../PageNameEnum'
import { defaultApplicationConfig, FontSizeIndex } from '../../config/v1/default'
import { HiddenPostDisplayModeDesc, HiddenPostPref } from '../../common/component/preference/HiddenPostPref'
import { openSplitModeShortcut } from './SplitModeShortcut'
import { PropKey } from '../../common/Constants'
import {
  ApiCacheState,
  CLEAN_UP_CACHE_THRESHOLD,
  clearApiCache,
  getApiCacheState
} from '../../common/dataStore/ApiCacheData'
import { PostSignature } from '../../common/PostSignature'
import { ShowToast } from '../../ArkUIX/Utils/ShowToast'
import { SetNightMode } from '../../ArkUIX/Utils/SetNightMode'
import { AnimationSetUp, AniSpeed, OpacityTransition } from '../../common/Animation'
import { FoldMenu } from '../../common/component/FoldMenu'
import BuildProfile from 'BuildProfile'
import { LengthUnit } from '@ohos.arkui.node'
import { clearSmilyImageCache } from '../../common/dataStore/SmilyCache'
import { PlatformBridge } from '../../ArkUIX/BridgeFunction'
import { PlatformInfo, PlatformTypeEnum } from '../../ArkUIX/PlatformInfo'
import { SliderReset } from '../../common/component/SliderReset'

export interface PreferenceParam {}

const SettingColumnSpace = 8

@Component
export struct PreferencePage {
  context = getContext(this) as common.UIAbilityContext
  @Consume(PropKey.pathStack) pathStack: NavPathStack
  @Consume appTheme: AppThemeColor
  @State pageParam: PreferenceParam = {}
  @State imageCacheUsage: number = 0
  @Consume @Watch('appStateChanged') appState: PreferenceState
  @State settingRow: SettingRow = new SettingRow(FontSizeEnum[this.appState.fontSize])
  @StorageProp(PropKey.currentColorMode) currentColorMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
  @State textSecondary: TextSecondary = new TextSecondary(this.appState.fontSize)
  @State darkModeFollowSys: boolean = defaultApplicationConfig.dark_mode_follow_system
  @State showTopThread: boolean = defaultApplicationConfig.show_top_thread
  @State postSignature: boolean = defaultApplicationConfig.post_signature
  @State postSignatureDeviceInfo: boolean = defaultApplicationConfig.post_signature_device_info
  @State apiCacheUsage?: ApiCacheState = undefined
  @State postSignatureDisplayText: string = PostSignature.displayText()
  @State aniSpeedRatio: number = AniSpeed.ratio
  @State warnDarkModeSwitch: boolean = false

  aboutToAppear(): void {
    this.imageCacheUsage = ImageKnife.getInstance().getFileCache()?.currentMemory ?? 0
    getApiCacheState().then(v => this.apiCacheUsage = v)
    PreferenceManager.readonly(conf => {
      this.darkModeFollowSys = conf.dark_mode_follow_system
      this.showTopThread = conf.show_top_thread
      this.postSignature = conf.post_signature
      this.postSignatureDeviceInfo = conf.post_signature_device_info
    })
    if (PlatformInfo.getPlatform() == PlatformTypeEnum.ANDROID) {
      PlatformBridge.getSdkInt().then(SDK_INT => {
        SDK_INT = SDK_INT ?? 0
        if (SDK_INT < 31) {
          this.warnDarkModeSwitch = true
        }
      })
    }
  }

  appStateChanged() {
    this.settingRow = new SettingRow(FontSizeEnum[this.appState.fontSize])
    this.textSecondary = new TextSecondary(this.appState.fontSize)
  }

  @LocalBuilder
  TextPrimary(text: string) {
    Text(text).fontColor($r('sys.color.font_primary'))
      .fontWeight(FontWeight.Medium)
      .fontSize(FontSizeEnum[this.appState.fontSize].vp16)
  }

  @LocalBuilder
  TestColumn() {
    Column()
  }

  build() {
    NavDestination() {
      OuterScroller() {
        TitleBar({
          titleContent: '设置',
          useRightMenu: false,
          clickLeftButton: () => {
            this.pathStack.pop()
          }
        }).backgroundColor(this.appTheme.backgroundSecondary)
        Scroll() {
          Column() {
            SettingGroupHeader({
              text: '主题色',
              fontSizeIndex: this.appState.fontSize
            })
            Column() {
              Row() {
                Column({ space: SettingColumnSpace }) {
                  this.TextPrimary('深浅色模式跟随系统切换')
                }.SettingColumn()

                Toggle({ type: ToggleType.Switch, isOn: this.darkModeFollowSys }).onChange(isOn => {
                  PreferenceManager.modify(conf => {
                    this.darkModeFollowSys = isOn
                    conf.dark_mode_follow_system = isOn
                    SetNightMode(conf, this.context.getApplicationContext())
                  })
                })
              }.attributeModifier(this.settingRow)

              Row() {
                Column({ space: SettingColumnSpace }) {
                  this.TextPrimary('深色模式')
                  if (this.warnDarkModeSwitch) {
                    Text('提示：在Android 11及以下版本中，由于缺少相应接口辅助，不跟随系统切换的深浅色模式，界面颜色存在异常')
                      .attributeModifier(this.textSecondary)
                  }
                }.SettingColumn()

                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.currentColorMode == ConfigurationConstant.ColorMode.COLOR_MODE_DARK
                })
                  .onClick(() => {
                    PreferenceManager.modify(conf => {
                      if (this.currentColorMode == ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
                        conf.light_dark_mode_prefer = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
                      } else {
                        conf.light_dark_mode_prefer = ConfigurationConstant.ColorMode.COLOR_MODE_DARK
                      }
                      SetNightMode(conf, this.context.getApplicationContext())
                    })
                  })
              }.attributeModifier(this.settingRow)
              .enabled(!this.darkModeFollowSys)
              .opacity(this.darkModeFollowSys ? 0.6 : 1)
              .animation({ duration: AniSpeed.ms120 })

              SettingDivider()
              Row() {
                Column({ space: SettingColumnSpace }) {
                  this.TextPrimary('浅色模式下的主题配色')
                }.SettingColumn()
              }.attributeModifier(this.settingRow)

              Row() {
                ThemeSelectPanel()
              }.attributeModifier(this.settingRow)
            }.attributeModifier(new RoundPanel(this.appTheme.backgroundPrimary))

            SettingGroupHeader({
              text: '浏览体验',
              fontSizeIndex: this.appState.fontSize
            })
            Column() {
              Row() {
                Column({ space: SettingColumnSpace }) {
                  this.TextPrimary('字体大小')
                  Text(`当前：${this.appState.fontSize}单位`).attributeModifier(this.textSecondary)
                  SliderReset({
                    value: this.appState.fontSize,
                    resetValue: defaultApplicationConfig.font_size,
                    min: 8,
                    max: 24,
                    step: 1,
                    onChange: fontSize => {
                      FontSizeSetup(fontSize)
                      PreferenceManager.modify(conf => {
                        conf.font_size = fontSize
                        this.appState.fontSize = fontSize
                      })
                    }
                  })
                }.SettingColumn()
              }.attributeModifier(this.settingRow)

              Row() {
                Column({ space: SettingColumnSpace }) {
                  this.TextPrimary('当帖文指定了字体大小')
                  ContentFontSizeOverridePref()
                  Text(FontOverrideModeDesc[this.appState.fontSizeOverride]).attributeModifier(this.textSecondary)
                }.SettingColumn()

              }.attributeModifier(this.settingRow)

              SettingDivider()

              Row() {
                Column({ space: SettingColumnSpace }) {
                  this.TextPrimary('宽屏时使用双栏界面')
                  Text('开启后，在宽屏设备上浏览时，将使用左右两侧分栏显示的界面。中心分界线可拖动，以调整界面宽度')
                    .attributeModifier(this.textSecondary)
                }.SettingColumn()

                Toggle({ type: ToggleType.Switch, isOn: this.appState.splitMode }).onChange(isOn => {
                  PreferenceManager.modify(conf => {
                    conf.split_mode = isOn
                    this.appState.splitMode = isOn
                    if (isOn) {
                      openSplitModeShortcut(this.pathStack)
                    }
                  })
                })
              }.attributeModifier(this.settingRow)

              Row() {
                Column({ space: SettingColumnSpace }) {
                  this.TextPrimary('帖子可复制')
                }.SettingColumn()

                Toggle({ type: ToggleType.Switch, isOn: this.appState.textCopyable }).onChange(isOn => {
                  PreferenceManager.modify(conf => {
                    conf.post_copyable = isOn
                    this.appState.textCopyable = isOn
                  })
                })
              }.attributeModifier(this.settingRow)

              FoldMenu({
                title: '动画时长调整'
              }) {
                Row() {
                  Column({ space: SettingColumnSpace }) {
                    Text(`调节部分动画的过渡时长，越高倍数则动画越缓慢。设为0倍将同时关闭系统默认提供的页面转场动画。需要重新进入使得配置完全生效\n当前：${this.aniSpeedRatio >
                      0 ? this.aniSpeedRatio.toPrecision(3) + 'x' : '关闭动画'}`)
                      .attributeModifier(this.textSecondary)
                  }.SettingColumn()
                }.attributeModifier(this.settingRow)
                SliderReset({
                  value: this.aniSpeedRatio,
                  min: 0,
                  step: 0.05,
                  max: 3,
                  resetValue: 1,
                  onChange: ratio => {
                    PreferenceManager.modify(conf => {
                      conf.ani_speed_ratio = ratio
                      this.aniSpeedRatio = ratio
                      AnimationSetUp(ratio)
                    })
                  }
                })
              }

              FoldMenu({
                title: '调整间距'
              }) {
                Row() {
                  Column({ space: SettingColumnSpace }) {
                    this.TextPrimary('主题帖间距')
                    Text(`调整主题帖页、收藏页、历史页，每条主题帖之间的空白大小。\n当前: ${this.appState.threadItemGap}单位`)
                      .attributeModifier(this.textSecondary)
                  }.SettingColumn()
                }.attributeModifier(this.settingRow)
                SliderReset({
                  value: this.appState.threadItemGap,
                  min: 0,
                  max: defaultApplicationConfig.thread_item_gap * 2,
                  resetValue: defaultApplicationConfig.thread_item_gap,
                  onChange: v => {
                    PreferenceManager.modify(conf => {
                      conf.thread_item_gap = v
                      this.appState.threadItemGap = v
                    })
                  }
                })
                Divider()
                Row() {
                  Column({ space: SettingColumnSpace }) {
                    this.TextPrimary('内容文字间距')
                    Text(`调整主题帖标题、内容的两行之间空白大小。\n当前: ${this.appState.contentLineSpace}单位`)
                      .attributeModifier(this.textSecondary)
                  }.SettingColumn()
                }.attributeModifier(this.settingRow)
                SliderReset({
                  value: this.appState.contentLineSpace,
                  min: 0,
                  max: defaultApplicationConfig.content_line_space * 3,
                  resetValue: defaultApplicationConfig.content_line_space,
                  onChange: v => {
                    PreferenceManager.modify(conf => {
                      conf.content_line_space = v
                      this.appState.contentLineSpace = v
                    })
                  }
                })
                Text(`内容文字间距示例文本：欢迎使用${this.context.resourceManager.getStringSync($r('app.string.app_name'))} ${BuildProfile.VERSION_NAME}\n调整内容文本间距\n来获得更符合个人习惯的浏览体验`)
                  .fontSize(FontSizeEnum[this.appState.fontSize].vp16)
                  .lineSpacing({
                    value: this.appState.contentLineSpace,
                    unit: LengthUnit.VP
                  })
                  .width('100%')
                  .margin({
                    bottom: 12
                  })
              }
            }.attributeModifier(new RoundPanel(this.appTheme.backgroundPrimary))

            SettingGroupHeader({
              text: '论坛相关',
              fontSizeIndex: this.appState.fontSize
            })
            Column() {
              Row() {
                Column({ space: SettingColumnSpace }) {
                  this.TextPrimary('尝试查看不可见内容')
                  HiddenPostPref()
                  Text(HiddenPostDisplayModeDesc[this.appState.hiddenPostDisplay]).attributeModifier(this.textSecondary)
                }.SettingColumn()

              }.attributeModifier(this.settingRow)

              SettingDivider()
              Row() {
                Column({ space: SettingColumnSpace }) {
                  this.TextPrimary('显示坛友战斗力')
                }.SettingColumn()

                Toggle({ type: ToggleType.Switch, isOn: this.appState.showCredit }).onChange(isOn => {
                  PreferenceManager.modify(conf => {
                    conf.show_credit = isOn
                    this.appState.showCredit = isOn
                  })
                })
              }.attributeModifier(this.settingRow)

              Row() {
                Column({ space: SettingColumnSpace }) {
                  this.TextPrimary('楼层快速导航')
                  Text('浏览回帖时，点击屏幕右侧的楼层号，进行快速跳转').attributeModifier(this.textSecondary)
                }.SettingColumn()

                Toggle({ type: ToggleType.Switch, isOn: this.appState.postAlphabetIndexer }).onChange(isOn => {
                  PreferenceManager.modify(conf => {
                    conf.post_alphabet_indexer = isOn
                    this.appState.postAlphabetIndexer = isOn
                  })
                })
              }.attributeModifier(this.settingRow)

              Row() {
                Column({ space: SettingColumnSpace }) {
                  this.TextPrimary('显示论坛置顶帖')
                }.SettingColumn()

                Toggle({ type: ToggleType.Switch, isOn: this.showTopThread }).onChange(isOn => {
                  PreferenceManager.modify(conf => {
                    conf.show_top_thread = isOn
                    this.showTopThread = isOn
                  })
                })
              }.attributeModifier(this.settingRow)

              Row() {
                Column({ space: SettingColumnSpace }) {
                  this.TextPrimary('回帖尾巴')
                  Text(this.postSignatureDisplayText)
                    .attributeModifier(this.textSecondary)
                    .wordBreak(WordBreak.BREAK_ALL)
                }.SettingColumn()

                Toggle({ type: ToggleType.Switch, isOn: this.postSignature }).onChange(isOn => {
                  PreferenceManager.modify(conf => {
                    conf.post_signature = isOn
                    this.postSignature = isOn
                    PostSignature.enable = isOn
                  })
                })
              }.attributeModifier(this.settingRow)

              if (this.postSignature) {
                Row() {
                  Column({ space: SettingColumnSpace }) {
                    this.TextPrimary('尾巴机型显示')
                  }.SettingColumn()

                  Toggle({ type: ToggleType.Switch, isOn: this.postSignatureDeviceInfo }).onChange(isOn => {
                    PreferenceManager.modify(conf => {
                      conf.post_signature_device_info = isOn
                      this.postSignatureDeviceInfo = isOn
                      PostSignature.device = isOn
                      this.postSignatureDisplayText = PostSignature.displayText()
                    })
                  })
                }.attributeModifier(this.settingRow).transition(OpacityTransition)
              }
            }.attributeModifier(new RoundPanel(this.appTheme.backgroundPrimary))

            SettingGroupHeader({
              text: '缓存',
              fontSizeIndex: this.appState.fontSize
            })
            Column() {
              Row() {
                Column({ space: SettingColumnSpace }) {
                  this.TextPrimary('图片缓存已使用')
                  Text(`${(this.imageCacheUsage / (1000 * 1000)).toFixed(2)}MB`).attributeModifier(this.textSecondary)
                }.SettingColumn()

                Button('清空')
                  .buttonStyle(ButtonStyleMode.NORMAL)
                  .fontSize(FontSizeEnum[this.appState.fontSize].vp16)
                  .enabled(this.imageCacheUsage > 0)
                  .opacity(this.imageCacheUsage > 0 ? 1 : 0.7)
                  .onClick(() => {
                    clearAvatarCache()
                    clearSmilyImageCache()
                    ImageKnife.getInstance()
                      .removeAllFileCache()
                      .then(() => {
                        this.imageCacheUsage =
                          ImageKnife.getInstance().getFileCache().currentMemory
                        this.getUIContext().getPromptAction().showToast({
                          message: '图片缓存已清空'
                        })
                      })
                  })
              }.attributeModifier(this.settingRow)

              Row() {
                Column({ space: SettingColumnSpace }) {
                  this.TextPrimary('允许图片缓存占用的存储空间')
                  ImageCachePref()
                }.SettingColumn()
              }.attributeModifier(this.settingRow)

              SettingDivider()
              Row() {
                Column({ space: SettingColumnSpace }) {
                  this.TextPrimary('头像缓存有效期')
                  Text('初次加载头像后，在缓存有效期间，不会再次通过网络更新头像').attributeModifier(this.textSecondary)
                  AvatarCachePref()
                }.SettingColumn()
              }.attributeModifier(this.settingRow)

              SettingDivider()
              Row() {
                Column({ space: SettingColumnSpace }) {
                  this.TextPrimary('网络数据缓存已使用')
                  if (this.apiCacheUsage) {
                    Text(`${this.apiCacheUsage.count}/${CLEAN_UP_CACHE_THRESHOLD}项`)
                      .attributeModifier(this.textSecondary)
                  }
                }.SettingColumn()

                if (this.apiCacheUsage) {
                  Button('清空')
                    .fontSize(FontSizeEnum[this.appState.fontSize].vp16)
                    .buttonStyle(ButtonStyleMode.NORMAL)
                    .enabled(this.apiCacheUsage.count > 0)
                    .opacity(this.apiCacheUsage.count > 0 ? 1 : 0.7)
                    .onClick(() => {
                      clearApiCache()
                        .then(async () => {
                          this.apiCacheUsage = await getApiCacheState()
                          ShowToast({
                            message: '网络数据缓存已清空'
                          })
                        })
                    })
                }
              }.attributeModifier(this.settingRow)
            }.attributeModifier(new RoundPanel(this.appTheme.backgroundPrimary))

          }
          .padding({
            top: 0,
            bottom: 56,
            left: 16,
            right: 16
          })
          .constraintSize({
            minHeight: '100%'
          })
        }.width('100%')
        .scrollBar(BarState.Off)
        .height('100%')
        .nestedScroll({
          scrollForward: NestedScrollMode.PARENT_FIRST,
          scrollBackward: NestedScrollMode.PARENT_FIRST
        })
      }
    }.hideTitleBar(true)
    .backgroundColor(this.appTheme.backgroundSecondary)
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
      this.pageParam = context.pathInfo.param as PreferenceParam
    })
  }
}

@Builder
function SettingDivider() {
  Divider().margin({ top: 6, bottom: 6 })
}

@Extend(Column)
function SettingColumn() {
  .flexGrow(1)
  .flexShrink(1)
  .alignItems(HorizontalAlign.Start)
}

@Builder
export function RegisterBuilder() {
  PreferencePage()
}

export class SettingRow implements AttributeModifier<CommonAttribute> {
  fontSize: FontSize

  constructor(fontSize: FontSize) {
    this.fontSize = fontSize
  }

  applyNormalAttribute(instance: CommonAttribute): void {
    instance.constraintSize({
      minHeight: this.fontSize.vp48
    })
      .padding({ top: this.fontSize.vp12, bottom: this.fontSize.vp12 })
      .width('100%')
  }
}

export class RoundPanel implements AttributeModifier<CommonAttribute> {
  color?: ResourceColor

  constructor(color?: ResourceColor) {
    this.color = color
  }

  applyNormalAttribute(instance: CommonAttribute): void {
    instance.width('100%')
      .borderRadius(20)
      .backgroundColor(this.color)
      .padding({
        left: 12,
        right: 12,
        top: 6,
        bottom: 6
      })
  }
}

export interface SettingGroupHeaderParam {
  text: string,
  fontSizeIndex: FontSizeIndex
}

@Builder
export function SettingGroupHeader(param: SettingGroupHeaderParam) {
  Column() {
    Text(param.text)
      .fontSize(FontSizeEnum[param.fontSizeIndex].vp14)
      .fontColor($r('sys.color.font_secondary'))
      .width('100%')
      .fontWeight(FontWeight.Medium)
  }.height(56)
  .padding({ right: 12, bottom: 8, left: 12 })
  .justifyContent(FlexAlign.End)
}

export function openPreferences(pathStack: NavPathStack) {
  openOrJumpTo(pathStack, PageNameEnum.Preferences)
}

class TextSecondary implements AttributeModifier<TextAttribute> {
  private fontSize: FontSizeIndex

  constructor(fontSize: FontSizeIndex) {
    this.fontSize = fontSize
  }

  applyNormalAttribute(instance: TextAttribute): void {
    instance.fontColor($r('sys.color.font_secondary'))
      .fontSize(FontSizeEnum[this.fontSize].vp14)
  }
}