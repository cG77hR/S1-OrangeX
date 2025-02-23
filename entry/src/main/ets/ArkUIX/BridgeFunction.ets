import bridge from '@arkui-x.bridge';


export enum BridgeFunction {
  openInBrowser = 'openInBrowser',
  copyTextToClipboard = "copyTextToClipboard",
  showToast = "showToast",
  shareText = "shareText",
  setWindowSystemBarProperties = "setWindowSystemBarProperties",
  WindowInsetsListener = "WindowInsetsListener",
  hideSoftKeyboard = "hideSoftKeyboard",
  photoViewPicker = "photoViewPicker",
  PhotoPickerResult = "PhotoPickerResult",
  UiModeChanged = "UiModeChanged",
  moveToExternalDownload = "moveToExternalDownload"
}

let bridgeImpl: bridge.BridgeObject

export function getBridgeInstance() {
  if (!bridgeImpl) {
    bridgeImpl = bridge.createBridge('Bridge')
  }
  return bridgeImpl
}