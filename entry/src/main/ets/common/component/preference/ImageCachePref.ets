import { PreferenceManager } from '../../../config/UserConfig'
import { ImageCacheSizeLevel } from '../../../config/v1/default'
import { PreferenceState } from '../../../pages/NavProvider/NavigationPage'
import { FontSizeEnum } from '../../fontSize/FontSizeEnum'

export const ImageCacheSize: number[] = []
ImageCacheSize[ImageCacheSizeLevel.mb64] = 64
ImageCacheSize[ImageCacheSizeLevel.mb128] = 128
ImageCacheSize[ImageCacheSizeLevel.mb256] = 256
ImageCacheSize[ImageCacheSizeLevel.mb512] = 512

const ImageCacheSizeLevelText: string[] = []
ImageCacheSizeLevelText[ImageCacheSizeLevel.mb64] = '64 MB'
ImageCacheSizeLevelText[ImageCacheSizeLevel.mb128] = '128 MB'
ImageCacheSizeLevelText[ImageCacheSizeLevel.mb256] = '256 MB'
ImageCacheSizeLevelText[ImageCacheSizeLevel.mb512] = '512 MB'

@Component
export struct ImageCachePref {
  @Consume appState: PreferenceState
  @State @Watch('selectedChanged') imageCacheSelected: ImageCacheSizeLevel = ImageCacheSizeLevel.mb256

  selectedChanged() {
    PreferenceManager.modify(conf => {
      conf.image_cache_size = this.imageCacheSelected
    })
  }

  aboutToAppear(): void {
    PreferenceManager.readonly(conf => {
      this.imageCacheSelected = conf.image_cache_size
    })
  }

  build() {
    Select(ImageCacheSizeLevelText.map(value => {
      const option: SelectOption = {
        value
      }
      return option
    })).font({
      size: FontSizeEnum[this.appState.fontSize].vp16
    }).selected($$this.imageCacheSelected)
      .value(ImageCacheSizeLevelText[this.imageCacheSelected])
  }
}