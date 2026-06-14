import { PlatformInfo, PlatformTypeEnum } from '../PlatformInfo';
import { GITHUB_RELEASE_PAGE, GITHUB_RELEASE_PAGE_ANDROID } from '../../api/base';

export function getReleasePage(): string {
  if (PlatformInfo.getPlatform() == PlatformTypeEnum.ANDROID) {
    return GITHUB_RELEASE_PAGE_ANDROID
  } else {
    return GITHUB_RELEASE_PAGE
  }
}
