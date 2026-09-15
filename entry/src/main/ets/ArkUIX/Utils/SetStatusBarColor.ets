import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { AppThemeColor } from '../../common/theme/basic/basic';
import { PropKey } from '../../common/Constants';
import { PlatformInfo, PlatformTypeEnum } from '../PlatformInfo';
import { PlatformBridge} from '../BridgeFunction';

export function SetStatusBarColor(context: common.UIAbilityContext, theme: AppThemeColor) {
  window.getLastWindow(context).then((windowClass): void => {
    windowClass.setWindowBackgroundColor(theme.titleBar?.toString())
    if (PlatformInfo.getPlatform() == PlatformTypeEnum.HARMONYOS) {
      windowClass.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        statusBarContentColor: theme.titleBarFont?.toString()
      })
    } else if (PlatformInfo.getPlatform() == PlatformTypeEnum.ANDROID) {
      PlatformBridge.setWindowSystemBarProperties(!theme.isDark)
    }
  })
}

function setSystemBarsEnabled(context: common.UIAbilityContext, visible: boolean) {
  window.getLastWindow(context).then((windowClass): void => {
    if (canIUse('SystemCapability.Window.SessionManager')) {
      windowClass.setSpecificSystemBarEnabled('status', visible, true)
      windowClass.setSpecificSystemBarEnabled('navigation', visible, true)
      windowClass.setSpecificSystemBarEnabled('navigationIndicator', visible, true)
    }
  })
}

export function ShowSystemBars(context: common.UIAbilityContext) {
  AppStorage.setOrCreate(PropKey.statusBarHiddenByApp, false)
  setSystemBarsEnabled(context, true)
}

export function HideSystemBars(context: common.UIAbilityContext) {
  AppStorage.setOrCreate(PropKey.statusBarHiddenByApp, true)
  setSystemBarsEnabled(context, false)
}