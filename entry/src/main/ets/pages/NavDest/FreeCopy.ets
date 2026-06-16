import { LengthUnit, SegmentButton, SegmentButtonIconTextItem, SegmentButtonItemTuple, SegmentButtonOptions } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { OuterScroller } from '../../common/component/OuterScroller'
import { TitleBar } from '../../common/component/TitleBar'
import { AppThemeColor } from '../../common/theme/basic/basic'
import { FontSizeEnum } from '../../common/fontSize/FontSizeEnum'
import { PreferenceState } from '../NavProvider/NavigationPage'
import { PageNameEnum } from '../PageNameEnum'
import { openOrJumpTo } from '../SingletonPage'
import { UIRootNode } from '../../common/component/ThreadPostContent'
import {
  bbCodeSerializer,
  markdownSerializer,
  plainTextSerializer
} from '../../common/ThreadPostContentSerializer'
import { CopyText, ShareText } from '../../ArkUIX/Utils/ShareKit'
import { HeavyClickEffect } from '../../common/Animation'
import { PlatformInfo, PlatformTypeEnum } from '../../ArkUIX/PlatformInfo'
import { openInBrowser } from '../../ArkUIX/Utils/WantUitl'
import {
  getCachedProcessTextActions,
  ProcessTextAction,
  processSelectedText,
  refreshProcessTextActions
} from '../../ArkUIX/Utils/ProcessTextActions'

export interface FreeCopyParam {
  node: UIRootNode[]
}

interface FreeCopyTextRange {
  start: number
  end: number
}

enum FreeCopyMode {
  PlainText,
  Markdown,
  BBCode
}

const FreeCopyModeLabel: string[] = []
FreeCopyModeLabel[FreeCopyMode.PlainText] = '纯文本'
FreeCopyModeLabel[FreeCopyMode.Markdown] = 'Markdown'
FreeCopyModeLabel[FreeCopyMode.BBCode] = 'BB code'

const ProcessTextMenuIdPrefix = 'processText:'
const OpenInBrowserMenuId = 'freeCopy:openInBrowser'
const ShareSelectedTextMenuId = 'freeCopy:shareSelectedText'

function processTextMenuId(actionId: string): string {
  return `${ProcessTextMenuIdPrefix}${actionId}`
}

function normalizeUrl(text: string): string {
  const match = text.trim().match(/^(https?:\/\/)?(www\.)?([a-z0-9-]+\.)+[a-z]{2,}([\/?#][^\s]*)?/i)
  if (!match) {
    return ''
  }
  const url = match[0].replace(/[),.;!?，。；！？）]+$/, '')
  return /^https?:\/\//i.test(url) ? url : `https://${url}`
}

function normalizeTextRange(range: TextRange): FreeCopyTextRange {
  return {
    start: range.start || 0,
    end: range.end || 0
  }
}

@Component
export struct FreeCopy {
  pathStack: NavPathStack = new NavPathStack()
  context = getContext(this) as common.UIAbilityContext
  @Consume appTheme: AppThemeColor
  @Consume appState: PreferenceState
  @State pageParam: FreeCopyParam = {
    node: []
  }
  @State plainText: string = ''
  @State markdownText: string = ''
  @State bbCodeText: string = ''
  @State markdownReady: boolean = false
  @State bbCodeReady: boolean = false
  @State processTextActions: ProcessTextAction[] = []
  @State selectedRange: FreeCopyTextRange = {
    start: 0,
    end: 0
  }
  @State selectedUrl: string = ''
  @State segmentOption: SegmentButtonOptions = SegmentButtonOptions.capsule({
    buttons: FreeCopyModeLabel.map(v => ({ text: v } as SegmentButtonIconTextItem)) as SegmentButtonItemTuple,
    multiply: false,
    fontSize: FontSizeEnum[this.appState.fontSize].vp16,
    selectedFontSize: FontSizeEnum[this.appState.fontSize].vp16,
    backgroundBlurStyle: BlurStyle.BACKGROUND_THICK
  })
  @State @Watch('selectedChanged') selectedModes: FreeCopyMode[] = [FreeCopyMode.PlainText]

  selectedChanged() {
    this.ensureSelectedContent()
  }

  currentMode(): FreeCopyMode {
    return this.selectedModes.length > 0 ? this.selectedModes[0] : FreeCopyMode.PlainText
  }

  ensureSelectedContent() {
    if (this.currentMode() == FreeCopyMode.Markdown && !this.markdownReady) {
      this.markdownText = markdownSerializer.convert(this.pageParam.node)
      this.markdownReady = true
    } else if (this.currentMode() == FreeCopyMode.BBCode && !this.bbCodeReady) {
      this.bbCodeText = bbCodeSerializer.convert(this.pageParam.node)
      this.bbCodeReady = true
    }
  }

  currentContent(): string {
    if (this.currentMode() == FreeCopyMode.Markdown) {
      return this.markdownText
    } else if (this.currentMode() == FreeCopyMode.BBCode) {
      return this.bbCodeText
    }
    return this.plainText
  }

  currentSelectedText(): string {
    const start = Math.min(this.selectedRange.start, this.selectedRange.end)
    const end = Math.max(this.selectedRange.start, this.selectedRange.end)
    return this.currentContent().slice(start, end)
  }

  updateSelectedText(start: number, end: number) {
    this.selectedRange = {
      start,
      end
    }
    this.selectedUrl = normalizeUrl(this.currentSelectedText())
  }

  isCustomMenuItem(menuItem: TextMenuItem): boolean {
    return menuItem.id.equals(TextMenuItemId.of(OpenInBrowserMenuId)) ||
      menuItem.id.equals(TextMenuItemId.of(ShareSelectedTextMenuId)) ||
      this.processTextActions.some(action => menuItem.id.equals(TextMenuItemId.of(processTextMenuId(action.id))))
  }

  customMenuItems(): TextMenuItem[] {
    const menuItems: TextMenuItem[] = []
    if (this.selectedUrl.length > 0) {
      menuItems.push({
        content: '浏览器打开',
        id: TextMenuItemId.of(OpenInBrowserMenuId)
      } as TextMenuItem)
    }
    menuItems.push({
      content: '分享',
      icon: $r('app.media.share'),
      id: TextMenuItemId.of(ShareSelectedTextMenuId)
    } as TextMenuItem)
    this.processTextActions.forEach(action => {
      menuItems.push({
        content: action.label,
        id: TextMenuItemId.of(processTextMenuId(action.id))
      } as TextMenuItem)
    })
    return menuItems
  }

  prepareMenuItems(menuItems: TextMenuItem[]): TextMenuItem[] {
    return this.customMenuItems().concat(menuItems.filter(item => !this.isCustomMenuItem(item)))
  }

  popBack() {
    this.pathStack.pop()
  }

  aboutToAppear() {
    if (PlatformInfo.getPlatform() == PlatformTypeEnum.ANDROID) {
      this.processTextActions = getCachedProcessTextActions()
      refreshProcessTextActions().then(actions => {
        this.processTextActions = actions
      })
    }
  }

  build() {
    NavDestination() {
      OuterScroller() {
        Column() {
          TitleBar({
            titleContent: '自由复制',
            useRightMenu: false,
            clickLeftButton: () => {
              this.popBack()
            }
          }) {
            Stack() {
              Image($r('app.media.rectangle_on_rectangle'))
                .width(24)
                .height(24)
                .fillColor(this.appTheme.titleBarFont)
                .rotate({
                  angle: 90
                })
            }
            .width(50)
            .height(50)
            .clickEffect(HeavyClickEffect)
            .onClick(() => {
              CopyText(this.currentContent(), '全文已复制')
            })
          }

          Column({ space: 16 }) {
            SegmentButton({
              options: this.segmentOption,
              selectedIndexes: $selectedModes
            })

            Text(this.currentContent())
              .width('100%')
              .fontSize(FontSizeEnum[this.appState.fontSize].vp16)
              .fontColor(this.appTheme.fontPrimary)
              .textAlign(TextAlign.Start)
              .copyOption(CopyOptions.LocalDevice)
              .lineSpacing({
                value: this.appState.contentLineSpace,
                unit: LengthUnit.VP
              })
              .onTextSelectionChange((start, end) => {
                this.updateSelectedText(start, end)
              })
              .editMenuOptions({
                onCreateMenu: (menuItems: Array<TextMenuItem>): TextMenuItem[] => {
                  return this.prepareMenuItems(menuItems)
                },
                onPrepareMenu: (menuItems: Array<TextMenuItem>): TextMenuItem[] => {
                  this.selectedUrl = normalizeUrl(this.currentSelectedText())
                  return this.prepareMenuItems(menuItems)
                },
                onMenuItemClick: (menuItem: TextMenuItem, range: TextRange): boolean => {
                  this.selectedRange = normalizeTextRange(range)
                  const selectedText = this.currentSelectedText()
                  if (menuItem.id.equals(TextMenuItemId.of(OpenInBrowserMenuId))) {
                    const url = normalizeUrl(selectedText)
                    if (url.length > 0) {
                      openInBrowser(this.context, url)
                    }
                    return true
                  }
                  if (menuItem.id.equals(TextMenuItemId.of(ShareSelectedTextMenuId))) {
                    if (selectedText.length > 0) {
                      ShareText(selectedText, this.context)
                    }
                    return true
                  }
                  const action = this.processTextActions.find(action =>
                    menuItem.id.equals(TextMenuItemId.of(processTextMenuId(action.id))))
                  if (!action) {
                    return false
                  }
                  if (selectedText.length > 0) {
                    processSelectedText(action.id, selectedText)
                  }
                  return true
                }
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding(16)
        }
        .width('100%')
        .constraintSize({
          minHeight: '100%'
        })
        .backgroundColor(this.appTheme.backgroundSecondary)
      }
    }.hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
      this.pageParam = context.pathInfo.param as FreeCopyParam
      this.plainText = plainTextSerializer.convert(this.pageParam.node)
    }).onBackPressed(() => {
      this.popBack()
      return true
    })
  }
}

@Builder
export function RegisterBuilder() {
  FreeCopy()
}

export function openFreeCopy(pathStack: NavPathStack, param: FreeCopyParam) {
  openOrJumpTo(pathStack, PageNameEnum.FreeCopy, param)
}
