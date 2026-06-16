import bridge from '@arkui-x.bridge'
import { PlatformBridge } from '../BridgeFunction'

export interface ProcessTextAction {
  id: string
  label: string
}

let processTextActions: ProcessTextAction[] = []
let initialized: boolean = false

function parseProcessTextActions(actionsJson: string): ProcessTextAction[] {
  try {
    const actions = JSON.parse(actionsJson) as ProcessTextAction[]
    return actions
      .filter(action => action.id.length > 0 && action.label.length > 0)
      .map(action => ({
        id: action.id,
        label: action.label
      } as ProcessTextAction))
  } catch (e) {
    return []
  }
}

function setProcessTextActions(actionsJson: string) {
  processTextActions = parseProcessTextActions(actionsJson)
}

export function getCachedProcessTextActions(): ProcessTextAction[] {
  return processTextActions.map(action => ({
    id: action.id,
    label: action.label
  } as ProcessTextAction))
}

export async function refreshProcessTextActions(): Promise<ProcessTextAction[]> {
  setProcessTextActions(await PlatformBridge.getProcessTextActions())
  return getCachedProcessTextActions()
}

export async function initProcessTextActions() {
  if (!initialized) {
    initialized = true
    await PlatformBridge.onProcessTextActions((actionsJson: string): bridge.ResultValue => {
      setProcessTextActions(actionsJson)
      return 0
    })
  }
  await refreshProcessTextActions()
}

export function processSelectedText(actionId: string, text: string) {
  PlatformBridge.processSelectedText(actionId, text)
}
