/**
 * Created by hzqiujiadi on 16/8/7.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { Context } from '../../../google/android/apps/muzei/render/ViewTypes';
import { MD360Player } from 'libmd360player.so';

// type Context = any;

/**
 * 抽象管线类
 */
export abstract class MDAbsLinePipe {
  private mIsInit: boolean = false;
  private mTid: number = 0;
  protected mNapi: MD360Player | null = null;

  /**
   * 接管渲染
   * @param totalWidth 总宽度
   * @param totalHeight 总高度
   * @param size 大小
   */
  abstract takeOver(totalWidth: number, totalHeight: number, size: number): void;

  /**
   * 提交渲染
   * @param totalWidth 总宽度
   * @param totalHeight 总高度
   * @param size 大小
   */
  abstract commit(totalWidth: number, totalHeight: number, size: number): void;

  /**
   * 初始化（子类实现）
   * @param context 上下文
   */
  protected abstract init(context: Context): void;

  /**
   * 设置 NAPI 实例（用于调用 C++ 侧的 OpenGL 方法）
   * @param napi NAPI 实例
   */
  public setNapi(napi: MD360Player | null): void {
    this.mNapi = napi;
  }

  /**
   * 设置管线
   * @param context 上下文
   */
  public setup(context: Context): void {
    // 在鸿蒙中，可以使用不同的方式获取线程ID
    const tid = Date.now(); // 简化实现
    if (this.mTid !== tid) {
      this.mTid = tid;
      this.mIsInit = false;
    }

    if (!this.mIsInit) {
      this.init(context);
      this.mIsInit = true;
    }
  }
}

