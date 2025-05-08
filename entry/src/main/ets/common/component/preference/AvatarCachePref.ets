import { PreferenceManager } from '../../../config/UserConfig'
import { AvatarTtlLevel } from '../../../config/v1/default'
import { PreferenceState } from '../../../pages/NavProvider/NavigationPage'
import { FontSizeEnum } from '../../fontSize/FontSizeEnum'

export const AvatarTtlDay: number[] = []

AvatarTtlDay[AvatarTtlLevel.perDay] = 1
AvatarTtlDay[AvatarTtlLevel.perWeek] = 7
AvatarTtlDay[AvatarTtlLevel.perMonth] = 30

const AvatarTtlLevelText: string[] = []
AvatarTtlLevelText[AvatarTtlLevel.perDay] = '每日'
AvatarTtlLevelText[AvatarTtlLevel.perWeek] = '每周'
AvatarTtlLevelText[AvatarTtlLevel.perMonth] = '每30天'

@Component
export struct AvatarCachePref {
  @Consume appState: PreferenceState
  @State avatarCacheLevelSelected: AvatarTtlLevel = AvatarTtlLevel.perDay

  selectedChanged() {
    PreferenceManager.modify(conf => {
      conf.avatar_cache_ttl = this.avatarCacheLevelSelected
    })
  }

  aboutToAppear(): void {
    PreferenceManager.readonly(conf => {
      this.avatarCacheLevelSelected = conf.avatar_cache_ttl
    })
  }

  build() {
    Select(AvatarTtlLevelText.map(value => {
      const option: SelectOption = {
        value
      }
      return option
    })).font({
      size: FontSizeEnum[this.appState.fontSize].vp16
    }).selected($$this.avatarCacheLevelSelected)
      .value(AvatarTtlLevelText[this.avatarCacheLevelSelected])
  }
}