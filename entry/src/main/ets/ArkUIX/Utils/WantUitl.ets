import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { openUserSpaceByLink } from '../../pages/NavDest/UserSpace';
import { openThreadPostByLink } from '../../pages/NavDest/ThreadPostList';
import { PlatformInfo, PlatformTypeEnum } from '../PlatformInfo';
import bridge from '@arkui-x.bridge';
import { BridgeFunction, getBridgeInstance } from '../BridgeFunction';
import { ShowToast } from './ShowToast';

export function openInBrowser(abilityContext: common.UIAbilityContext, url?: string) {
  if (url == undefined) {
    return
  }
  if (PlatformInfo.getPlatform() == PlatformTypeEnum.HARMONYOS) {
    let want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: url
    }
    abilityContext.startAbility(want).catch((err: BusinessError) => {
      ShowToast({
        message: '跳转失败'
      })
    })
  } else if (PlatformInfo.getPlatform() == PlatformTypeEnum.ANDROID){
    getBridgeInstance().callMethod(BridgeFunction.openInBrowser, url)
  }
}

export function openS1LinkLike(href: string, pathStack: NavPathStack, context: common.UIAbilityContext,
  subject: string = '',
  replies: string = '1', fallbackToBrowser = true) {
  openUserSpaceByLink(href, pathStack, (): void =>
  openThreadPostByLink(href, pathStack, (): void => {
    if (fallbackToBrowser) {
      openInBrowser(context, href)
    } else {
      ShowToast({
        message: '未能解析链接'
      })
    }
  }, subject, replies
  ))
}