import http from '@ohos.net.http';
import { BusinessError } from '@ohos.base';
import { FormFieldFileValue, IRcpSession, IRcpSessionFactory, MultipartForm, RcpResponse } from './Rcp';
import { rcp } from '@kit.RemoteCommunicationKit';
import { rcpCookie2string } from '../../api/request';
import { stringToArray } from '../../common/TextUtil';
import { fileIo as fs } from '@kit.CoreFileKit';
import { ShowToast } from '../Utils/ShowToast';
import { util } from '@kit.ArkTS';

class RcpSessionHttpAdapter implements IRcpSession {
  private httpRequest: http.HttpRequest;
  private config: rcp.SessionConfiguration;

  constructor(config: rcp.SessionConfiguration) {
    if (config.cookies) {
      if (!config.headers) {
        config.headers = {}
      }
      config.headers['cookie'] = rcpCookie2string(config.cookies)
    }
    this.config = config;
    this.httpRequest = http.createHttp();
  }

  /**
   * 发起 GET 请求
   * @param path - 请求路径
   * @returns Promise<rcp.Response> - 返回响应数据
   */
  async get(path: string): Promise<RcpResponse> {
    return this.send(path, http.RequestMethod.GET)
  }

  async send(path: string, method: http.RequestMethod, payload?: rcp.RequestContent | string): Promise<RcpResponse> {
    const url = (this.config.baseAddress ?? '') + path
    return new Promise<RcpResponse>((resolve, reject) => {
      if (this.config?.requestConfiguration?.transfer?.autoRedirect === false) {
        this.httpRequest.on('headersReceive', (header) => {
          this.httpRequest.destroy()
          resolve(new RcpResponse(302, JSON.parse(JSON.stringify(header)), undefined, undefined, () => null,
            () => null))
        })
      }
      this.httpRequest.request(
        url,
        {
          usingCache: false,
          method,
          extraData: payload,
          connectTimeout: this.config?.requestConfiguration?.transfer?.timeout?.connectMs,
          header: this.config.headers,
        },
        (err: BusinessError, data: http.HttpResponse) => {
          if (err) {
            reject(err);
            return;
          }
          const response: RcpResponse = new RcpResponse(
            data.responseCode,
            data.header as rcp.ResponseHeaders,
            typeof data.result === 'string' ? stringToArray(data.result) : data.result as ArrayBuffer,
            parseSetCookies(data.header['set-cookie'] ?? []),
            () => {
              if (typeof data.result === 'string') {
                return data.result
              } else {
                return null
              }
            },
            (): object | null => {
              if (typeof data.result === 'string') {
                return JSON.parse(data.result)
              } else {
                return null
              }
            },
          );
          resolve(response);
        }
      );
    });
  }

  /**
   * 发起 POST 请求
   * @param path - 请求路径
   * @param payload - 请求体内容
   * @returns Promise<rcp.Response> - 返回响应数据
   */
  async post(path: string, payload: rcp.RequestContent | string): Promise<RcpResponse> {
    let data = payload
    if (payload instanceof MultipartForm) {
      data = await buildMultipartFormData(payload, this.config)
    }
    return this.send(path, http.RequestMethod.POST, data)
  }

  /**
   * 关闭会话
   */
  close(): void {
    this.httpRequest.destroy();
  }
}

export class RcpSessionFactoryHttpAdapter implements IRcpSessionFactory {
  async createSession(config: rcp.SessionConfiguration): Promise<IRcpSession> {
    return new RcpSessionHttpAdapter(config);
  }

  closeSession(session: IRcpSession): void {
    session.close();
  }
}

function parseSetCookies(setCookies: string[]): rcp.ResponseCookie[] {
  return setCookies.map((cookieString: string): rcp.ResponseCookie => {
    const result: rcp.ResponseCookie = {
      name: ''
    };
    const parts = cookieString.split(/;\s*/);
    for (let i = 0; i < parts.length; i++) {
      const part = parts[i].trim();
      if (i === 0) {
        const kv = part.split('=');
        result.name = kv[0].trim();
        result.value = kv[1]?.trim();
      } else {
        const kv = part.split('=');
        const attrKey = kv[0].trim().toLowerCase();
        const attrValue = kv[1]?.trim();

        switch (attrKey) {
          case 'domain':
            result.domain = attrValue;
            break;
          case 'path':
            result.path = attrValue;
            break;
          case 'expires':
            result.expires = attrValue;
            break;
          case 'max-age':
            result.maxAge = parseInt(attrValue || '', 10);
            break;
          case 'secure':
            result.isSecure = true;
            break;
          case 'httponly':
            result.httpOnly = true;
            break;
          case 'samesite':
            result.sameSite = attrValue;
            break;
          default:
            break;
        }
      }
    }

    result.rawSize = cookieString.length;

    return result;
  });
}

function generateBoundary(): string {
  return `-------${util.generateRandomUUID()}`;
}

export async function buildMultipartFormData(data: MultipartForm,
  config: rcp.SessionConfiguration): Promise<ArrayBuffer> {
  const boundary = generateBoundary()
  const parts: Uint8Array[] = []
  let isFirst = true
  if (!config.headers) {
    config.headers = {}
  }
  config.headers['content-type'] = `multipart/form-data; boundary=${boundary}`
  for (const kv of Object.entries(data.fields)) {
    const name = kv[0]
    const value = kv[1]
    let boundaryLine: string
    if (isFirst) {
      boundaryLine = `--${boundary}\r\n`
      isFirst = false
    } else {
      boundaryLine = `\r\n--${boundary}\r\n`
    }

    if (typeof value === 'string') {
      const headers = `Content-Disposition: form-data; name="${name}"\r\n\r\n`
      const headerPart = stringToArray(boundaryLine + headers)
      const valuePart = stringToArray(value)
      parts.push(headerPart, valuePart)
    } else if (typeof value === 'object') {
      const file = value as FormFieldFileValue
      if (!file.contentOrPath) {
        continue
      }
      const headers = `Content-Disposition: form-data; name="${name}"; filename="${file.remoteFileName}"\r\n` +
        `Content-Type: ${file.contentType}\r\n\r\n`
      const headerPart = stringToArray(boundaryLine + headers)
      let contentPart: Uint8Array = new Uint8Array
      if (typeof file.contentOrPath === 'string') {
        try {
          const f = await fs.open(file.contentOrPath, fs.OpenMode.READ_ONLY)
          const size = fs.statSync(f.fd).size
          const buffer = new ArrayBuffer(size)
          await fs.read(f.fd, buffer)
          await fs.close(f)
          contentPart = new Uint8Array(buffer)
        } catch (e) {
          ShowToast({
            message: `读取文件异常`
          })
        }
      } else if (file.contentOrPath.content) {
        if (typeof file.contentOrPath.content === 'string') {
          contentPart = stringToArray(file.contentOrPath.content)
        } else {
          contentPart = new Uint8Array(file.contentOrPath.content)
        }
      }
      parts.push(headerPart, contentPart)
    }
  }

  const footer = stringToArray(`\r\n--${boundary}--\r\n`);
  parts.push(footer);

  const totalLength = parts.reduce((sum, part) => sum + part.length, 0);
  const result = new Uint8Array(totalLength);
  let offset = 0;
  for (const part of parts) {
    result.set(part, offset);
    offset += part.length;
  }

  return result.buffer;
}