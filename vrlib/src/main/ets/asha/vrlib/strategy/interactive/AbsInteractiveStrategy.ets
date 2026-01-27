/**
 * Created by hzqiujiadi on 16/3/19.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { IModeStrategy } from '../IModeStrategy';
import { IInteractiveMode } from './IInteractiveMode';
import { MDMainHandler, IMainHandler } from '../../common/MDMainHandler';
import { MD360Director } from '../../MD360Director';
import { Context } from '../../../../google/android/apps/muzei/render/ViewTypes';
import { MDGLHandler } from '../../common/MDGLHandler';
import { ProjectionModeManager } from '../projection/ProjectionModeManager';
import { SensorEventListener } from '../../AndroidTypes';

/**
 * 交互模式管理器参数
 */
export class InteractiveModeManagerParams {
  public mMotionDelay: number = 0;
  public mSensorListener: SensorEventListener | null = null;
  public projectionModeManager: ProjectionModeManager | null = null;
  public glHandler: MDGLHandler | null = null;
  public napi: ESObject | null = null;  // MD360Player NAPI 实例，用于将触摸数据传递到 C++ 层
}

/**
 * 抽象交互策略类
 * Implements IModeStrategy and IInteractiveMode
 * Updated for structural typing fix
 */
export abstract class AbsInteractiveStrategy implements IModeStrategy, IInteractiveMode {
  private params: InteractiveModeManagerParams | null = null;
  private mMainHandler: IMainHandler | null = null;

  protected getMainHandler(): IMainHandler {
    if (this.mMainHandler == null) {
      // 在鸿蒙中，可以使用对应的主线程处理器
      // 这里使用MDMainHandler作为占位
      this.mMainHandler = MDMainHandler.sharedHandler();
    }
    return this.mMainHandler;
  }

  protected runOnUiThread(runnable: () => void): void {
    this.getMainHandler().post(runnable);
  }

  constructor(params: InteractiveModeManagerParams) {
    this.params = params;
  }

  getParams(): InteractiveModeManagerParams | null {
    return this.params;
  }

  protected getDirectorList(): MD360Director[] {
    return this.params?.projectionModeManager?.getDirectors() || [];
  }

  onResume(context: Context): void {}
  onPause(context: Context): void {}
  abstract turnOnInGL(context: Context): void;
  abstract turnOffInGL(context: Context): void;
  abstract isSupport(context: Context): boolean;
  abstract handleDrag(distanceX: number, distanceY: number): boolean;
  abstract onOrientationChanged(context: Context): void;

  /**
   * 销毁方法，清理所有引用防止内存泄漏
   * 子类应该覆盖此方法并调用 super.destroy()
   */
  destroy(): void {
    // 注意：params 是共享对象，不能清理其内部引用！
    // 只解除本对象对 params 的引用
    this.params = null;
    this.mMainHandler = null;
  }
}

