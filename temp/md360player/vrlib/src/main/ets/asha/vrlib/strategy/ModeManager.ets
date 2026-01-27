/**
 * Created by hzqiujiadi on 16/3/19.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { IModeStrategy } from './IModeStrategy';
import { MDGLHandler } from '../common/MDGLHandler';
import { MDMainHandler } from '../common/MDMainHandler';
import { VRUtil } from '../common/VRUtil';

import { Context } from '../../../google/android/apps/muzei/render/ViewTypes';

// 可销毁接口
interface IDestroyable {
  destroy?: () => void;
}

export interface INotSupportCallback {
  onNotSupport(mode: number): void;
}

/**
 * 模式管理器抽象类
 */
export abstract class ModeManager<T extends IModeStrategy> {
  private mMode: number;
  private mStrategy: T | null = null;
  private mCallback: INotSupportCallback | null = null;
  private mGLHandler: MDGLHandler;

  constructor(mode: number, handler: MDGLHandler) {
    this.mGLHandler = handler;
    this.mMode = mode;
  }

  /**
   * 必须在创建实例后调用
   * @param context 上下文
   * @param callback 不支持回调
   */
  prepare(context: Context, callback: INotSupportCallback | null): void {
    this.mCallback = callback;
    this.initMode(context, this.mMode);
  }

  /**
   * 创建策略（子类实现）
   * @param mode 模式
   */
  protected abstract createStrategy(mode: number): T;

  /**
   * 获取模式列表（子类实现）
   */
  protected abstract getModes(): number[];

  private initMode(context: Context, mode: number): void {
    // 保存旧策略对象
    const oldStrategy = this.mStrategy;
    
    if (this.mStrategy != null) {
      this.off(context);
    }
    this.mStrategy = this.createStrategy(mode);
    if (!this.mStrategy.isSupport(context)) {
      MDMainHandler.sharedHandler().post(() => {
        if (this.mCallback != null) {
          this.mCallback.onNotSupport(mode);
        }
      });
      return;
    }

    // 确保策略已设置后再调用on
    // 注意：mStrategy在这里已经更新，getVisibleSize()应该能立即返回新值
    this.on(context);
    
    // 立即销毁旧策略对象，释放资源
    if (oldStrategy != null && oldStrategy !== this.mStrategy) {
      try {
        this.destroyStrategy(oldStrategy);
      } catch (e) {
        console.warn('ModeManager: Failed to destroy old strategy', e);
      }
    }
    
    // 添加调试日志
    console.log('ModeManager.initMode: mode=', mode, 'strategy=', this.mStrategy?.constructor?.name);
  }

  /**
   * 销毁策略对象及其资源
   */
  protected destroyStrategy(strategy: T): void {
    // 子类可以覆盖此方法以释放策略特定的资源
    // 使用接口类型断言（ArkTS 兼容）
    const destroyable = strategy as IDestroyable;
    if (destroyable.destroy) {
      destroyable.destroy();
    }
  }

  /**
   * 切换模式（切换到下一个模式）
   * @param context 上下文
   */
  switchToNextMode(context: Context): void {
    const modes = this.getModes();
    const mode = this.getMode();
    const index = modes.indexOf(mode);
    const nextIndex = (index + 1) % modes.length;
    const nextMode = modes[nextIndex];

    this.switchMode(context, nextMode);
  }

  /**
   * 切换到指定模式
   * @param context 上下文
   * @param mode 模式
   */
  switchMode(context: Context, mode: number): void {
    if (mode === this.getMode()) {
      console.log('ModeManager.switchMode: mode unchanged, skipping', mode);
      return;
    }
    console.log('ModeManager.switchMode: switching from', this.getMode(), 'to', mode);
    this.mMode = mode;
    this.initMode(context, this.mMode);
  }

  /**
   * 开启策略
   * @param context 上下文
   */
  on(context: Context): void {
    VRUtil.checkMainThread("strategy on must call from main thread!");

    const tmpStrategy = this.mStrategy;
    if (tmpStrategy != null && tmpStrategy.isSupport(context)) {
      this.getGLHandler().post(() => {
        tmpStrategy.turnOnInGL(context);
      });
    }
  }

  /**
   * 关闭策略
   * @param context 上下文
   */
  off(context: Context): void {
    VRUtil.checkMainThread("strategy off must call from main thread!");

    const tmpStrategy = this.mStrategy;
    if (tmpStrategy != null && tmpStrategy.isSupport(context)) {
      // 改为同步执行而不是异步post，确保立即释放资源
      // 这样可以避免GLHandler中任务堆积导致的内存泄漏
      try {
        tmpStrategy.turnOffInGL(context);
      } catch (e) {
        console.warn('ModeManager.off: Failed to turn off strategy', e);
      }
    }
  }

  /**
   * 获取策略
   */
  protected getStrategy(): T | null {
    return this.mStrategy;
  }

  /**
   * 获取当前模式
   */
  getMode(): number {
    return this.mMode;
  }

  /**
   * 获取GL处理器
   */
  getGLHandler(): MDGLHandler {
    return this.mGLHandler;
  }

  /**
   * 销毁方法，清理所有引用防止内存泄漏
   */
  destroy(): void {
    // 销毁当前策略
    if (this.mStrategy) {
      this.destroyStrategy(this.mStrategy);
      this.mStrategy = null;
    }
    this.mCallback = null;
    // 注意：不能将 mGLHandler 设为 null，因为 ArkTS 中它是非空类型
    // 但我们清理了所有使用它的引用，GLHandler 会被正常回收
  }
}

