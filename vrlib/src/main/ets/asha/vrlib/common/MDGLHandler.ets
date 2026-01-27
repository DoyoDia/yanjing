type Runnable = () => void;

export class MDGLHandler {
  private died: boolean = false;
  private addQueue: Runnable[] = [];
  private workQueue: Runnable[] = [];

  constructor() {
  }

  /**
   * 在 Android 中，主线程调用 post，把任务转移到 GL 线程，在 GL 线程循环里执行。
   * 这里用简单的队列模拟，具体在线程/TaskPool 中的使用由上层控制。
   */
  post(runnable: Runnable | undefined | null): void {
    if (this.died) {
      return;
    }
    if (!runnable) {
      return;
    }
    // 这里不区分主线程/GL 线程，由调用方在合适的线程上调用 dealMessage。
    // 行为上等价于“先放入队列，稍后在 GL 渲染循环里执行”。
    const index = this.addQueue.indexOf(runnable);
    if (index >= 0) {
      this.addQueue.splice(index, 1);
    }
    this.addQueue.push(runnable);
  }

  /**
   * 应该在渲染线程/GL 线程中周期性调用，执行队列中的任务。
   */
  dealMessage(): void {
    this.workQueue.push(...this.addQueue);
    this.addQueue = [];
    while (this.workQueue.length > 0) {
      const runnable = this.workQueue.shift();
      runnable && runnable();
    }
  }

  markAsDestroy(): void {
    this.died = true;
    // 清空所有待执行任务，避免闭包持有外部引用
    this.addQueue.length = 0;
    this.workQueue.length = 0;
  }

  /**
   * 销毁方法，清理所有引用防止内存泄漏
   * 与markAsDestroy相同功能，提供统一的destroy接口
   */
  destroy(): void {
    this.markAsDestroy();
  }
}


