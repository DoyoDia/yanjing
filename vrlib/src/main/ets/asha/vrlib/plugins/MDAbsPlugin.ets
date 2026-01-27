/**
 * Created by hzqiujiadi on 16/7/21.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDPosition } from '../model/MDPosition';
import { MD360Director } from '../MD360Director';
import { Context } from '../../../google/android/apps/muzei/render/ViewTypes';

import { MD360Player } from 'libmd360player.so';

/**
 * 抽象插件基类
 */
export abstract class MDAbsPlugin {
  private mIsInit: boolean = false;
  private mTid: number = 0;
  private mPosition: MDPosition = MDPosition.getOriginalPosition();
  protected mNapi: MD360Player | null = null;

  /**
   * 在GL线程中设置插件
   * @param context 上下文
   */
  public setupInGL(context: Context): void {
    // 在鸿蒙中，可以使用不同的方式获取线程ID
    // 这里使用一个简单的计数器来模拟线程ID
    const tid = Date.now(); // 简化实现，实际应该获取线程ID
    if (tid !== this.mTid) {
      this.mTid = tid;
      this.mIsInit = false;
    }

    if (!this.mIsInit) {
      this.initInGL(context);
      this.mIsInit = true;
    }
  }

  /**
   * 在GL线程中初始化（子类实现）
   * @param context 上下文
   */
  protected abstract initInGL(context: Context): void;

  /**
   * 在GL线程中销毁（子类实现）
   */
  abstract destroyInGL(): void;

  /**
   * 渲染前调用（子类实现）
   * @param totalWidth 总宽度
   * @param totalHeight 总高度
   */
  abstract beforeRenderer(totalWidth: number, totalHeight: number): void;

  /**
   * 渲染（子类实现）
   * @param index 索引
   * @param itemWidth 项目宽度
   * @param itemHeight 项目高度
   * @param director 导演对象
   */
  abstract renderer(index: number, itemWidth: number, itemHeight: number, director: MD360Director): void;

  /**
   * 获取模型位置
   */
  protected getModelPosition(): MDPosition {
    return this.mPosition;
  }

  /**
   * 设置模型位置
   * @param position 位置对象
   */
  public setModelPosition(position: MDPosition): void {
    this.mPosition = position;
  }

  /**
   * 设置 NAPI 实例（用于调用 C++ 侧的 OpenGL 方法）
   * @param napi NAPI 实例
   */
  public setNapi(napi: MD360Player | null): void {
    this.mNapi = napi;
  }

  /**
   * 是否可移除（子类实现）
   */
  abstract removable(): boolean;
}

