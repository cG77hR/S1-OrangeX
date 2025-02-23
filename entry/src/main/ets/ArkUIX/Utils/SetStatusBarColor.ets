import { common } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'
import { AppThemeColor } from '../../common/theme/basic/basic'
import { PlatformInfo, PlatformTypeEnum } from '../PlatformInfo'
import bridge from '@arkui-x.bridge';
import { BridgeFunction, getBridgeInstance } from '../BridgeFunction';

export function SetStatusBarColor(context: common.UIAbilityContext, theme: AppThemeColor) {
  window.getLastWindow(context).then((windowClass): void => {
    windowClass.setWindowBackgroundColor(theme.titleBar?.toString())
    if (PlatformInfo.getPlatform() == PlatformTypeEnum.HARMONYOS) {
      windowClass.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        statusBarContentColor: theme.titleBarFont?.toString()
      })
    } else if (PlatformInfo.getPlatform() == PlatformTypeEnum.ANDROID) {
      getBridgeInstance().callMethod(BridgeFunction.setWindowSystemBarProperties, !theme.isDark)
    }
  })
}