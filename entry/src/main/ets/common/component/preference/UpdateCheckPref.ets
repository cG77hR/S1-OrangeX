import { PreferenceManager } from '../../../config/UserConfig'
import { UpdateCheckInterval } from '../../../config/v1/default'
import { PreferenceState } from '../../../pages/NavProvider/NavigationPage'
import { FontSizeEnum } from '../../fontSize/FontSizeEnum'

const UpdateCheckIntervalText: string[] = []
UpdateCheckIntervalText[UpdateCheckInterval.monthly] = '每月'
UpdateCheckIntervalText[UpdateCheckInterval.weekly] = '每7天'
UpdateCheckIntervalText[UpdateCheckInterval.never] = '不检查'

export const UpdateCheckIntervalDesc: string[] = []

UpdateCheckIntervalDesc[UpdateCheckInterval.monthly] = '间隔30天检查新版本'
UpdateCheckIntervalDesc[UpdateCheckInterval.weekly] = '间隔7天检查新版本'
UpdateCheckIntervalDesc[UpdateCheckInterval.never] = '不自动检查应用更新'

@Component
export struct UpdateCheckPref {
  @Consume appState: PreferenceState
  @State @Watch('selectedChanged') updateCheckSelected: UpdateCheckInterval = UpdateCheckInterval.monthly

  selectedChanged() {
    PreferenceManager.modify(conf => {
      conf.update_check_interval = this.updateCheckSelected
      this.appState.updateCheckInterval = this.updateCheckSelected
    })
  }

  aboutToAppear(): void {
    PreferenceManager.readonly(conf => {
      this.updateCheckSelected = conf.update_check_interval
    })
  }

  build() {
    Select(UpdateCheckIntervalText.map(value => {
      const option: SelectOption = {
        value
      }
      return option
    })).font({
      size: FontSizeEnum[this.appState.fontSize].vp16
    }).selected($$this.updateCheckSelected)
      .value(UpdateCheckIntervalText[this.updateCheckSelected])
  }
}
