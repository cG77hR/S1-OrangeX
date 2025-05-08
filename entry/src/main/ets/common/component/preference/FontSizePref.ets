import { PreferenceManager } from '../../../config/UserConfig'
import { FontSizeIndex } from '../../../config/v1/default'
import { PreferenceState } from '../../../pages/NavProvider/NavigationPage'
import { FontSizeEnum } from '../../fontSize/FontSizeEnum'

const FontSizeName: string[] = []
FontSizeName[FontSizeIndex.xs] = '更小'
FontSizeName[FontSizeIndex.small] = '小'
FontSizeName[FontSizeIndex.medium] = '标准'
FontSizeName[FontSizeIndex.large] = '大'
FontSizeName[FontSizeIndex.xl] = '更大'

@Component
export struct FontSizePref {
  @Consume appState: PreferenceState
  @State @Watch('selectedChanged') fontSizeSelected: FontSizeIndex = FontSizeIndex.medium

  selectedChanged() {
    PreferenceManager.modify(conf => {
      conf.font_size = this.fontSizeSelected
      this.appState.fontSize = this.fontSizeSelected
    })
  }

  aboutToAppear(): void {
    PreferenceManager.readonly(conf => {
      this.fontSizeSelected = conf.font_size
    })
  }

  build() {
    Select(FontSizeName.map(value => {
      const option: SelectOption = {
        value
      }
      return option
    })).font({
      size: FontSizeEnum[this.appState.fontSize].vp16
    }).selected($$this.fontSizeSelected)
      .value(FontSizeName[this.fontSizeSelected])
  }
}