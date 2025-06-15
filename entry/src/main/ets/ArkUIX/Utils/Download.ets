import { common } from '@kit.AbilityKit'
import { fileUri, fileIo as fs, picker } from '@kit.CoreFileKit'
import { BusinessError, request } from '@kit.BasicServicesKit'
import { userCookieString } from '../../api/request'
import { URL } from '../../api/base'
import { ShowToast } from './ShowToast'
import { PlatformInfo, PlatformTypeEnum } from '../PlatformInfo'
import { PlatformBridge } from '../BridgeFunction'
import hilog from '@ohos.hilog'

export async function DownloadFile(context: common.UIAbilityContext, filename: string, url: string) {
  const sandboxPath = context.cacheDir + '/' + filename
  if (await fs.access(sandboxPath)) {
    await fs.unlink(sandboxPath)
  }

  const config: request.agent.Config = {
    action: request.agent.Action.DOWNLOAD,
    url,
    title: filename,
    saveas: sandboxPath,
    headers: {
      'Accept': '*/*',
      'Accept-Encoding': 'gzip, deflate, br',
      'Cookie': userCookieString,
      'Referer': URL.WEB_BASE,
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36'
    },
    overwrite: true,
  }
  request.agent.create(context, config).then((task: request.agent.Task) => {
    task.on('completed', async () => {
      if (PlatformInfo.getPlatform() == PlatformTypeEnum.HARMONYOS) {
        const documentViewPicker = new picker.DocumentViewPicker(context)
        const documentSaveOptions = new picker.DocumentSaveOptions()
        documentSaveOptions.pickerMode = picker.DocumentPickerMode.DOWNLOAD
        await documentViewPicker.save(documentSaveOptions).then(async (documentSaveResult: Array<string>) => {
          if (documentSaveResult.length > 0) {
            const publicDownloadFolder = new fileUri.FileUri(documentSaveResult[0]).path
            const publicPath = publicDownloadFolder + '/' + filename
            if (await fs.access(publicPath)) {
              await fs.unlink(publicPath)
            }
            await fs.moveFile(sandboxPath, publicPath)
            ShowToast({
              message: `${filename}下载完成，请前往系统下载管理器查看`,
              duration: 5000
            })
          } else {
            ShowToast({
              message: '获取下载目录失败'
            })
            fs.unlink(sandboxPath)
            return
          }
        }).catch((err: BusinessError) => {
          console.error(`Invoke documentViewPicker.save failed, code is ${err.code}, message is ${err.message}`)
        })
      } else if (PlatformInfo.getPlatform() == PlatformTypeEnum.ANDROID) {
        PlatformBridge.moveToExternalDownload(sandboxPath, filename)
        ShowToast({
          message: `${filename}下载完成`,
          duration: 5000
        })
      }
    })
    task.on('failed', async (err) => {
      const info = await request.agent.show(task.tid)
      hilog.warn(0x001, "download", "[download failed]" + JSON.stringify(info))
      ShowToast({
        message: '异常: ' + filename + '下载失败'
      })
    })

    task.start()
  }).catch((err: BusinessError) => {
    console.error(`Failed to request the download. Code: ${err.code}, message: ${err.message}`);
  })
}