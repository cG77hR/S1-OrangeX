import { OuterScroller } from '../../common/component/OuterScroller'
import { TitleBar } from '../../common/component/TitleBar'
import { AppThemeColor } from '../../common/theme/basic/basic'
import { common } from '@kit.AbilityKit'
import { PreferenceState } from '../NavProvider/NavigationPage'
import { FontSizeEnum } from '../../common/fontSize/FontSizeEnum'
import { openOrJumpTo } from '../SingletonPage'
import { PageNameEnum } from '../PageNameEnum'
import { RoundPanel, SettingGroupHeader, SettingRow } from './Preferences'
import BuildProfile from 'entry/BuildProfile'
import { openInBrowser } from '../../ArkUIX/Utils/WantUitl'
import { PropKey } from '../../common/Constants'
import { openUserGuide } from './UserGuide'
import { openThreadPost, ThreadPostParam } from './ThreadPostList'
import { CacheStrategy, ImageKnife } from '@ohos/imageknife'
import { OpacityTransition } from '../../common/Animation'
import { PlatformInfo, PlatformTypeEnum } from '../../ArkUIX/PlatformInfo'

export interface AboutAppParam {}

const RELEASE_BADGE =
  'https://raster.shields.io/github/v/release/wly5556/S1-Orange?style=for-the-badge&label=' // image暂未支持svg text标签,只能用图片版本的

@Component
export struct AboutApp {
  context = getContext(this) as common.UIAbilityContext
  @Consume(PropKey.pathStack) pathStack: NavPathStack
  @Consume appTheme: AppThemeColor
  @State pageParam: AboutAppParam = {}
  @Consume appState: PreferenceState
  @State settingRow: SettingRow = new SettingRow(FontSizeEnum[this.appState.fontSize])
  @State releaseBadge: string | PixelMap | undefined = undefined

  async aboutToAppear() {
    const knife = ImageKnife.getInstance()
    await knife.preLoadCache({
      loadSrc: RELEASE_BADGE,
      writeCacheStrategy: CacheStrategy.Memory
    })
    const badge = await knife.getCacheImage(RELEASE_BADGE, CacheStrategy.Memory)
    knife.removeMemoryCache(RELEASE_BADGE)
    if (badge) {
      this.releaseBadge = badge.source
    }
  }

  getReleasePage() {
    if (PlatformInfo.getPlatform() == PlatformTypeEnum.ANDROID) {
      return 'https://github.com/cG77hR/S1-OrangeX/releases/'
    } else {
      return 'https://github.com/wly5556/S1-Orange/releases/'
    }
  }

  @LocalBuilder
  TextPrimary(text: string) {
    Text(text).fontColor($r('sys.color.font_primary'))
      .fontWeight(FontWeight.Medium)
      .fontSize(FontSizeEnum[this.appState.fontSize].vp16)
  }

  @LocalBuilder
  TextSecondary(text: string) {
    Text(text).fontColor($r('sys.color.font_secondary'))
      .fontSize(FontSizeEnum[this.appState.fontSize].vp14)
  }

  @LocalBuilder
  ShareIcon() {
    Image($r('app.media.share'))
      .width(FontSizeEnum[this.appState.fontSize].vp24)
      .height(FontSizeEnum[this.appState.fontSize].vp24)
      .opacity(.7)
      .fillColor(this.appTheme.fontSecondary)
  }

  build() {
    NavDestination() {
      OuterScroller() {
        TitleBar({
          titleContent: '关于',
          useRightMenu: false,
          clickLeftButton: () => {
            this.pathStack.pop()
          }
        }).backgroundColor(this.appTheme.backgroundSecondary)
        Scroll() {
          Column() {
            SettingGroupHeader({
              text: '本应用  ',
              fontSizeIndex: this.appState.fontSize
            })
            Column() {
              Row() {
                Image($r('app.media.app_icon_center'))
                  .width(80)
                  .height(80)
                Column({ space: 6 }) {
                  Text($r('app.string.app_name'))
                    .fontSize(FontSizeEnum[this.appState.fontSize].vp20)
                    .fontWeight(FontWeight.Bold)
                  Text() {
                    Span('当前版本 ')
                    Span(BuildProfile.VERSION_NAME).fontWeight(FontWeight.Bold)
                  }.fontSize(FontSizeEnum[this.appState.fontSize].vp16).opacity(.8)

                  Text('查看版本说明').fontSize(FontSizeEnum[this.appState.fontSize].vp14).opacity(.8)
                }.alignItems(HorizontalAlign.End)
                .height(80)
              }.width('100%')
              .padding(12)
              .constraintSize({
                maxWidth: 300
              }).justifyContent(FlexAlign.SpaceBetween)
            }.attributeModifier(new RoundPanel(this.appTheme.backgroundPrimary))
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              const param: ThreadPostParam = {
                tid: '2244111',
                jumpToPidWithHighlight: true,
                jumpToPid: '67271179'
              }
              openThreadPost(param, this.pathStack)
            })

            SettingGroupHeader({
              text: '版本',
              fontSizeIndex: this.appState.fontSize
            })
            Column() {
              Row({ space: 12 }) {
                if (this.releaseBadge) {
                  this.TextPrimary('最新版本')
                  Image(this.releaseBadge)
                    .height(FontSizeEnum[this.appState.fontSize].vp32)
                    .interpolation(ImageInterpolation.High)
                    .borderRadius(12)
                  Blank()
                  Image($r('app.media.github_mark'))
                    .width(FontSizeEnum[this.appState.fontSize].vp32)
                    .height(FontSizeEnum[this.appState.fontSize].vp32)
                  this.ShareIcon()
                } else {
                  this.TextPrimary('正在获取最新版本...')
                }
              }
              .alignItems(VerticalAlign.Center)
              .justifyContent(FlexAlign.SpaceBetween)
              .attributeModifier(this.settingRow)
              .transition(OpacityTransition)
              .onClick(() => {
                openInBrowser(this.context, this.getReleasePage())
              })
            }.attributeModifier(new RoundPanel(this.appTheme.backgroundPrimary))

            SettingGroupHeader({
              text: '反馈及说明',
              fontSizeIndex: this.appState.fontSize
            })
            Column() {
              Row({ space: 12 }) {
                Image($r('app.media.app_icon_center'))
                  .width(FontSizeEnum[this.appState.fontSize].vp32)
                  .height(FontSizeEnum[this.appState.fontSize].vp32)
                Column() {
                  this.TextPrimary('论坛专楼')
                  this.TextSecondary('使用中遇到任何问题都可以到这里反馈')
                }.alignItems(HorizontalAlign.Start)

                Blank()
                this.ShareIcon()
              }.alignItems(VerticalAlign.Center)
              .attributeModifier(this.settingRow)
              .onClick(() => {
                const param: ThreadPostParam = {
                  tid: '2244111'
                }
                openThreadPost(param, this.pathStack)
              })

              Divider()
              Row({ space: 12 }) {
                Image($r('app.media.github_mark'))
                  .width(FontSizeEnum[this.appState.fontSize].vp32)
                  .height(FontSizeEnum[this.appState.fontSize].vp32)
                this.TextPrimary('github issues')
                Blank()
                this.ShareIcon()
              }.alignItems(VerticalAlign.Center)
              .attributeModifier(this.settingRow)
              .onClick(() => {
                openInBrowser(this.context, 'https://github.com/wly5556/S1-Orange/issues')
              })

              Divider()
              Row({ space: 12 }) {
                Image($r('app.media.gitee'))
                  .width(FontSizeEnum[this.appState.fontSize].vp32)
                  .height(FontSizeEnum[this.appState.fontSize].vp32)
                this.TextPrimary('gitee issues')
                Blank()
                this.ShareIcon()
              }.alignItems(VerticalAlign.Center)
              .attributeModifier(this.settingRow)
              .onClick(() => {
                openInBrowser(this.context, 'https://gitee.com/rI6tL9/S1-Orange/issues')
              })

              Divider()
              Row({ space: 12 }) {
                Image($r('app.media.app_icon_center'))
                  .width(FontSizeEnum[this.appState.fontSize].vp32)
                  .height(FontSizeEnum[this.appState.fontSize].vp32)
                Column() {
                  this.TextPrimary('使用手册')
                }.alignItems(HorizontalAlign.Start)

                Blank()
                this.ShareIcon()
              }.alignItems(VerticalAlign.Center)
              .attributeModifier(this.settingRow)
              .onClick(() => {
                openUserGuide(this.pathStack)
              })

            }.attributeModifier(new RoundPanel(this.appTheme.backgroundPrimary))


            // SettingGroupHeader({
            //   text: '构建',
            //   fontSizeIndex: this.appState.fontSize
            // })
            // Column() {
            //   Row() {
            //     Column() {
            //       this.TextPrimary('本地最后提交哈希')
            //       Row() {
            //         this.TextSecondary(BuildProfile.gitHeadHash)
            //       }.justifyContent(FlexAlign.End)
            //       .width('100%')
            //     }.SettingColumn()
            //   }.attributeModifier(this.settingRow)
            //
            //   Row() {
            //     this.TextPrimary('本地最后提交于')
            //     this.TextSecondary(BuildProfile.gitHeadDate)
            //   }.justifyContent(FlexAlign.SpaceBetween)
            //   .attributeModifier(this.settingRow)
            //
            //   Divider()
            //   Row() {
            //     this.TextPrimary('软件包构建于')
            //     this.TextSecondary(BuildProfile.buildDate)
            //   }.justifyContent(FlexAlign.SpaceBetween)
            //   .attributeModifier(this.settingRow)
            //   .onClick(() => {
            //     ShowToast({
            //       message: '感谢你愿意动手构建并尝试本软件！   :)',
            //       duration: 5000
            //     })
            //   })
            // }.attributeModifier(new RoundPanel(this.appTheme.backgroundPrimary))

            SettingGroupHeader({
              text: '第三方开源许可',
              fontSizeIndex: this.appState.fontSize
            })
            Column() {
              Row({ space: 12 }) {
                this.TextPrimary('S1-Next')
                Blank()
                this.ShareIcon()
              }.alignItems(VerticalAlign.Center)
              .attributeModifier(this.settingRow)
              .onClick(() => openInBrowser(this.context, 'https://github.com/ykrank/S1-Next/blob/master/LICENSE.md'))

              Divider()
              Row({ space: 12 }) {
                this.TextPrimary('@ohos/imageknife')
                Blank()
                this.ShareIcon()
              }.alignItems(VerticalAlign.Center)
              .attributeModifier(this.settingRow)
              .onClick(() => openInBrowser(this.context,
                'https://gitee.com/openharmony-tpc/ImageKnife/blob/master/LICENSE'))
              .attributeModifier(this.settingRow)
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
      this.pageParam = context.pathInfo.param as AboutAppParam
    })
  }
}

export function openAboutApp(pathStack: NavPathStack) {
  openOrJumpTo(pathStack, PageNameEnum.AboutApp)
}

@Builder
export function RegisterBuilder() {
  AboutApp()
}

@Extend(Column)
function SettingColumn() {
  .flexGrow(1)
  .flexShrink(1)
  .alignItems(HorizontalAlign.Start)
}
