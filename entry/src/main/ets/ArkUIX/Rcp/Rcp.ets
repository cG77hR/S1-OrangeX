import { rcp } from '@kit.RemoteCommunicationKit';
import { PlatformInfo, PlatformTypeEnum } from '../PlatformInfo';
import { RcpSessionFactoryHttpAdapter } from './RcpArkUIX';
import { RcpSessionFactoryLocal } from './RcpLocal';


export interface IRcpSession {
  get(path: string): Promise<RcpResponse>;

  post(path: string, payload: rcp.RequestContent | string): Promise<RcpResponse>;

  close(): void;
}

export interface IRcpSessionFactory {
  createSession(config: rcp.SessionConfiguration): Promise<IRcpSession>;

  closeSession(session: IRcpSession): void
}

export class Rcp {
  static factory?: IRcpSessionFactory

  static async createSession(config: rcp.SessionConfiguration): Promise<IRcpSession> {
    if (Rcp.factory) {
      return Rcp.factory.createSession(config)
    }
    let platform: PlatformTypeEnum = PlatformInfo.getPlatform();
    if (platform == PlatformTypeEnum.ANDROID || platform == PlatformTypeEnum.IOS) {
      Rcp.factory = new RcpSessionFactoryHttpAdapter()
    } else {
      // for test
      // Rcp.factory = new RcpSessionFactoryHttpAdapter()
      Rcp.factory = new RcpSessionFactoryLocal()
    }
    return Rcp.factory.createSession(config)
  }

  static closeSession(session: IRcpSession) {
    Rcp.factory!.closeSession(session)
  }
}

export class RcpResponse {
  statusCode: number;
  headers: rcp.ResponseHeaders;
  body?: ArrayBuffer;
  cookies?: rcp.ResponseCookie[];
  toString: () => string | null;
  toJSON: () => object | null;

  constructor(
    statusCode: number,
    headers: rcp.ResponseHeaders,
    body: ArrayBuffer | undefined,
    cookies: rcp.ResponseCookie[] | undefined,
    toStringFn: () => string | null,
    toJSONFn: () => object | null
  ) {
    this.statusCode = statusCode;
    this.headers = headers;
    this.body = body;
    this.cookies = cookies;
    this.toString = toStringFn;
    this.toJSON = toJSONFn;
  }
}
interface FileContent {
  content: string | ArrayBuffer;
}
export interface FormFieldFileValue {
  contentType?: string;
  remoteFileName?: string;
  contentOrPath: string | FileContent;
}
type FormFieldValue = string | number | boolean | bigint;
type MultipartFormFieldValue = FormFieldValue | FormFieldFileValue;
type MultipartFormFields = Record<string, MultipartFormFieldValue | MultipartFormFieldValue[]>
export class MultipartForm {
  constructor(fields: MultipartFormFields) {
    this.fields = fields
  };
  fields: MultipartFormFields;
}