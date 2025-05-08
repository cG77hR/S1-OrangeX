import { PlatformInfo, PlatformTypeEnum } from '../PlatformInfo';
import { promptAction} from '@kit.ArkUI';
import { PlatformBridge } from '../BridgeFunction';

export function ShowToast(options: promptAction.ShowToastOptions) {
  if (PlatformInfo.getPlatform() == PlatformTypeEnum.HARMONYOS) {
    promptAction.showToast(options)
  } else if (PlatformInfo.getPlatform() == PlatformTypeEnum.ANDROID) {
    PlatformBridge.showToast(String(options.message))
  }
}