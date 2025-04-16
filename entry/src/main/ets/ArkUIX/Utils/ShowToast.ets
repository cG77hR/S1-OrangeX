import { PlatformInfo, PlatformTypeEnum } from '../PlatformInfo';
import { promptAction, ShowToastOptions } from '@kit.ArkUI';
import { PlatformBridge } from '../BridgeFunction';

export function ShowToast(options: ShowToastOptions) {
  if (PlatformInfo.getPlatform() == PlatformTypeEnum.HARMONYOS) {
    promptAction.showToast(options)
  } else if (PlatformInfo.getPlatform() == PlatformTypeEnum.ANDROID) {
    PlatformBridge.showToast(options.message)
  }
}