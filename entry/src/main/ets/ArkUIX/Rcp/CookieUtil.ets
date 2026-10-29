import { rcp } from '@kit.RemoteCommunicationKit'

// 独立成文件：RcpArkUIX 会在 taskpool 子线程被加载，不能依赖 api/request（会带入 UI 模块导致装饰器不可用）
export function rcpCookie2string(cookie: rcp.RequestCookies): string {
  return Object.entries(cookie)
    .filter(v => v[1] !== undefined)
    .map(v => `${v[0]}=${v[1]}`)
    .join('; ')
}
