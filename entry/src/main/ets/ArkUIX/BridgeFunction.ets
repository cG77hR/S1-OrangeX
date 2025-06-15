import bridge from '@arkui-x.bridge';

enum BridgeFunction {
  openInBrowser = 'openInBrowser',
  copyTextToClipboard = "copyTextToClipboard",
  showToast = "showToast",
  shareText = "shareText",
  setWindowSystemBarProperties = "setWindowSystemBarProperties",
  onWindowInsetsListener = "onWindowInsetsListener",
  hideSoftKeyboard = "hideSoftKeyboard",
  photoViewPicker = "photoViewPicker",
  onPhotoPickerResult = "onPhotoPickerResult",
  onUiModeChanged = "onUiModeChanged",
  moveToExternalDownload = "moveToExternalDownload",
  copyToExternalDownload = "copyToExternalDownload"
}

type BridgeCallback = (...parameters: bridge.Message[]) => bridge.ResultValue
type WindowInsetsListener = (statusBarInset: number, navigationBarInset: number) => bridge.ResultValue
type UiModeChangeListener = (darkMode: boolean) => bridge.ResultValue

class PlatformBridgeClass {
  private bridgeImpl: bridge.BridgeObject | undefined = undefined
  private registeredMethods:
    Map<BridgeFunction, Array<BridgeCallback>> = new Map

  public release() {
    if (this.bridgeImpl) {
      this.registeredMethods.forEach((methods, functionName) => {
        this.bridgeImpl!.unRegisterMethod(functionName)
      })
      this.bridgeImpl = undefined
    }
  }

  private async getImpl(): Promise<bridge.BridgeObject> {
    if (!this.bridgeImpl) {
      this.bridgeImpl = bridge.createBridge('Bridge')
      this.rebindListeners()
    }
    return this.bridgeImpl
  }

  private rebindListeners() {
    this.registeredMethods.forEach((methods, functionName) => {
      methods.forEach(method => {
        this.bridgeImpl!.registerMethod({
          name: functionName,
          method
        })
      })
    })
  }

  async openInBrowser(url: string) {
    const impl = await this.getImpl()
    return impl.callMethod(BridgeFunction.openInBrowser, url)
  }

  async copyTextToClipboard(text: string) {
    const impl = await this.getImpl()
    return impl.callMethod(BridgeFunction.copyTextToClipboard, text)
  }

  async showToast(text: string) {
    const impl = await this.getImpl()
    return impl.callMethod(BridgeFunction.showToast, text)
  }

  async shareText(text: string) {
    const impl = await this.getImpl()
    return impl.callMethod(BridgeFunction.shareText, text)
  }

  async setWindowSystemBarProperties(isDarkFont: boolean) {
    const impl = await this.getImpl()
    return impl.callMethod(BridgeFunction.setWindowSystemBarProperties, isDarkFont)
  }

  async hideSoftKeyboard() {
    const impl = await this.getImpl()
    return impl.callMethod(BridgeFunction.hideSoftKeyboard)
  }

  async photoViewPicker(callback: (uris: string[]) => void) {
    const impl = await this.getImpl()
    const cb = (...uris: string[]) => {
      impl.unRegisterMethod(BridgeFunction.onPhotoPickerResult)
      callback(uris)
      return undefined
    }
    impl.registerMethod({
      name: BridgeFunction.onPhotoPickerResult,
      method: cb
    })
    impl.callMethod(BridgeFunction.photoViewPicker)
  }

  async moveToExternalDownload(path: string, filename: string) {
    const impl = await this.getImpl()
    return impl.callMethod(BridgeFunction.moveToExternalDownload, path, filename)
  }

  async copyToExternalDownload(path: string, filename: string) {
    const impl = await this.getImpl()
    return impl.callMethod(BridgeFunction.copyToExternalDownload, path, filename)
  }

  private async pushRegisterMethod(callback: BridgeCallback, functionName: BridgeFunction) {
    const impl = await this.getImpl()
    impl.registerMethod({
      name: functionName,
      method: callback
    })
    if (!this.registeredMethods.has(functionName)) {
      this.registeredMethods.set(functionName, [])
    }
    this.registeredMethods.get(functionName)?.push(callback)
  }

  async onWindowInsetsListener(callback: WindowInsetsListener) {
    this.pushRegisterMethod(callback as BridgeCallback, BridgeFunction.onWindowInsetsListener)
  }

  async onUiModeChanged(callback: UiModeChangeListener) {
    this.pushRegisterMethod(callback as BridgeCallback, BridgeFunction.onUiModeChanged)
  }
}

export const PlatformBridge = new PlatformBridgeClass()