import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { PlatformBridge } from '../BridgeFunction'
import { PlatformInfo, PlatformTypeEnum } from '../PlatformInfo'
import { ShowToast } from './ShowToast'
import uri from '@ohos.uri'

export async function PhotoViewPicker(sizeLimit: number): Promise<string[]> {
  if (PlatformInfo.getPlatform() == PlatformTypeEnum.HARMONYOS) {
    const PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions()
    PhotoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE
    PhotoSelectOptions.maxSelectNumber = 10
    PhotoSelectOptions.recommendationOptions = {
      textContextInfo: {
        text: '文件最大' + sizeLimit + 'MB'
      }
    }
    const photoPicker = new photoAccessHelper.PhotoViewPicker()
    const photoSelectResult: photoAccessHelper.PhotoSelectResult = await photoPicker.select(PhotoSelectOptions)
    return photoSelectResult.photoUris
  } else {
    return new Promise((resolve): void => {
      ShowToast({
        message: '文件最大' + sizeLimit + 'MB'
      })
      PlatformBridge.photoViewPicker(uris => resolve(uris.map(u => new uri.URI(u).toString())))
    })
  }
}