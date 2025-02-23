/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import deviceInfo from '@ohos.deviceInfo';

export enum PlatformTypeEnum {
  HARMONYOS = 'HarmonyOS Platform',
  ANDROID = 'Android Platform',
  IOS = 'iOS Platform',
  UNKNOWN = 'Unknown Platform',
}

export class PlatformInfo {
  static platform: PlatformTypeEnum | undefined = undefined

  static getPlatform(): PlatformTypeEnum {
    if (PlatformInfo.platform) {
      return PlatformInfo.platform
    }
    let osFullNameInfo: string = deviceInfo.osFullName;
    let platformName: string = osFullNameInfo.split(' ')[0];
    if (platformName.includes("OpenHarmony")) {
      PlatformInfo.platform = PlatformTypeEnum.HARMONYOS;
    } else if (platformName.includes("Android")) {
      PlatformInfo.platform = PlatformTypeEnum.ANDROID;
    } else if (platformName.includes('iOS')) {
      PlatformInfo.platform = PlatformTypeEnum.IOS;
    } else {
      PlatformInfo.platform = PlatformTypeEnum.UNKNOWN;
    }
    return PlatformInfo.platform;
  }
}