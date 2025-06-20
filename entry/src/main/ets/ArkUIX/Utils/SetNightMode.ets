import { ApplicationConfig } from '../../config/v1/default';
import { PlatformInfo, PlatformTypeEnum } from '../PlatformInfo';
import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { PlatformBridge } from '../BridgeFunction';
import { PropKey } from '../../common/Constants';

export function SetNightMode(conf: ApplicationConfig, context: common.ApplicationContext) {
  let targetMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
  if (conf.dark_mode_follow_system) {
    targetMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
  } else {
    targetMode = conf.light_dark_mode_prefer
  }
  console.log(`${targetMode}`)
  if (PlatformInfo.getPlatform() == PlatformTypeEnum.HARMONYOS) {
    context.setColorMode(targetMode)
  } else if (PlatformInfo.getPlatform() == PlatformTypeEnum.ANDROID) {
    PlatformBridge.setNightMode(targetMode)
    if (conf.dark_mode_follow_system === false) {
      AppStorage.setOrCreate(PropKey.currentColorMode, targetMode)
    }
  }
}