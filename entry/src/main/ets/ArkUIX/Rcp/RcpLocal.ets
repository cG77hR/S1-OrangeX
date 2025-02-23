import { Queue } from '@kit.ArkTS';
import { rcp } from '@kit.RemoteCommunicationKit';
import { IRcpSession, IRcpSessionFactory, MultipartForm } from './Rcp';

class RcpSessionLocalAdapter implements IRcpSession {
  private session: rcp.Session;

  constructor(session: rcp.Session) {
  this.session = session;
}

  get(path: string): Promise<rcp.Response> {
    return this.session.get(path);
  }

  post(path: string, payload: rcp.RequestContent | string): Promise<rcp.Response> {
    let data = payload
    if (payload instanceof MultipartForm) {
      data = new rcp.MultipartForm(payload.fields)
    }
    return this.session.post(path, data);
  }

  close(): void {
    this.session.close();
  }
}

export class RcpSessionFactoryLocal implements IRcpSessionFactory {
  private waitQueue: Queue<VoidCallback> = new Queue();

  private enqueueWait(): Promise<void> {
    return new Promise<void>((res) => this.waitQueue.add(res));
  }

  async createSession(config: rcp.SessionConfiguration): Promise<IRcpSession> {
    let session: rcp.Session | undefined = undefined;

    while (session === undefined) {
      try {
        session = rcp.createSession(config);
      } catch (e) {
        await this.enqueueWait();
        // code: 1007900994 会话数达到限制，当前最多可创建16个session实例。
      }
    }

    return new RcpSessionLocalAdapter(session);
  }

 closeSession(session: IRcpSession): void {
    session.close()
    if (this.waitQueue.length > 0) {
      this.waitQueue.getFirst()();
      this.waitQueue.pop();
    }
  }
}