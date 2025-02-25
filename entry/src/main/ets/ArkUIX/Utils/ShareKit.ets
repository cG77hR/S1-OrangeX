import { systemShare } from '@kit.ShareKit'
import { unifiedDataChannel, uniformTypeDescriptor as utd } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { BusinessError, pasteboard } from '@kit.BasicServicesKit'
import { fileUri } from '@kit.CoreFileKit'
import { PlatformInfo, PlatformTypeEnum } from '../PlatformInfo'
import { BridgeFunction, getBridgeInstance } from '../BridgeFunction'
import { ShowToast } from './ShowToast'

// ------------ ShareText -----------------

export function ShareText(text: string, context: common.UIAbilityContext) {
  if (PlatformInfo.getPlatform() == PlatformTypeEnum.HARMONYOS) {
    ShareTextLocal(text, context)
  } else if (PlatformInfo.getPlatform() == PlatformTypeEnum.ANDROID) {
    ShareTextAndroid(text)
  }
}

function ShareTextAndroid(text: string) {
  getBridgeInstance().callMethod(BridgeFunction.shareText, text)
}

function ShareTextLocal(text: string, context: common.UIAbilityContext) {
  const shareData: systemShare.SharedData = new systemShare.SharedData({
    utd: utd.UniformDataType.TEXT,
    content: text,
  })
  SystemShare(shareData, context)
}

// ------------ ShareImage -----------------

export function ShareImage(path: string, ext: string, context: common.UIAbilityContext) {
  const utdTypeId = utd.getUniformDataTypeByFilenameExtension(`.${ext}`, utd.UniformDataType.IMAGE);
  const shareData: systemShare.SharedData = new systemShare.SharedData({
    utd: utdTypeId,
    uri: fileUri.getUriFromPath(path)
  })
  SystemShare(shareData, context)
}

function SystemShare(shareData: systemShare.SharedData, context: common.UIAbilityContext) {
  const controller: systemShare.ShareController = new systemShare.ShareController(shareData)
  controller.show(context, {
    selectionMode: systemShare.SelectionMode.SINGLE,
    previewMode: systemShare.SharePreviewMode.DETAIL,
  }).then(() => {
    console.info('ShareController show success.')
  }).catch((error: BusinessError) => {
    console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`)
  })
}

// ------------ CopyToClipBoard -----------------

export function CopyText(text: string, UIContext: UIContext, toast?: string) {
  if (PlatformInfo.getPlatform() == PlatformTypeEnum.HARMONYOS) {
    const plaintext = new unifiedDataChannel.PlainText()
    plaintext.textContent = text
    writeToPasteboard(plaintext, toast)
  } else if (PlatformInfo.getPlatform() == PlatformTypeEnum.ANDROID) {
    writeToPasteboardAndroid(text)
  }
}

export function CopyHyperLink(url: string, desc?: string, toast?: string) {
  if (PlatformInfo.getPlatform() == PlatformTypeEnum.HARMONYOS) {
    const link = new unifiedDataChannel.Hyperlink()
    link.url = url
    if (desc) {
      link.description = desc
    }
    writeToPasteboard(link, toast)
  } else if (PlatformInfo.getPlatform() == PlatformTypeEnum.ANDROID) {
    writeToPasteboardAndroid(url)
  }
}

function writeToPasteboard(content: unifiedDataChannel.UnifiedRecord, toast: string = '已复制') {
  const data = new unifiedDataChannel.UnifiedData()
  data.properties.shareOptions = unifiedDataChannel.ShareOptions.CROSS_APP
  data.addRecord(content)
  pasteboard.getSystemPasteboard().setUnifiedData(data).then(() => {
    ShowToast({
      message: toast
    })
  }).catch((error: BusinessError) => {

  })
}

function writeToPasteboardAndroid(text: string) {
  getBridgeInstance().callMethod(BridgeFunction.copyTextToClipboard, text)
  ShowToast({
    message: '已复制'
  })
}