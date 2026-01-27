type Runnable = () => void;

/**
 * Android 里是全局主线程 Handler。
 * 在 HarmonyOS/ETS 中，可以用 setTimeout 模拟一次性投递到主事件循环。
 */
export interface IMainHandler {
  post: (task: Runnable) => void;
}

/**
 * 主线程处理器实现类
 */
class MainHandlerImpl implements IMainHandler {
  post(task: Runnable): void {
    if (!task) {
      return;
    }
    // 将任务放到事件循环尾部执行
    setTimeout(() => task(), 0);
  }
}

export class MDMainHandler {
  private static sHandler: IMainHandler | null = null;

  static init(): void {
    // 保留方法占位，方便与原有初始化流程对齐。
  }

  /**
   * 这里返回一个简单的"Handler"对象，只支持 post。
   */
  static sharedHandler(): IMainHandler {
    if (MDMainHandler.sHandler == null) {
      MDMainHandler.sHandler = new MainHandlerImpl();
    }
    return MDMainHandler.sHandler;
  }
}


