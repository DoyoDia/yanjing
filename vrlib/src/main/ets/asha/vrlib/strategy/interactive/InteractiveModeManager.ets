/**
 * Created by hzqiujiadi on 16/3/19.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { ModeManager } from '../ModeManager';
import { AbsInteractiveStrategy, InteractiveModeManagerParams } from './AbsInteractiveStrategy';
import { IInteractiveMode } from './IInteractiveMode';
import { MDGLHandler } from '../../common/MDGLHandler';
import { MotionStrategy } from './MotionStrategy';
import { TouchStrategy } from './TouchStrategy';
import { MotionWithTouchStrategy } from './MotionWithTouchStrategy';
import { CardboardMotionStrategy } from './CardboardMotionStrategy';
import { CardboardMTStrategy } from './CardboardMTStrategy';
import { ProjectionModeManager } from '../projection/ProjectionModeManager';
import { Context } from '../../../../google/android/apps/muzei/render/ViewTypes';

// TODO: 当相关类型迁移后，取消注释并删除类型占位符
// import { MDVRLibrary } from '../../MDVRLibrary';
// import { ProjectionModeManager } from '../projection/ProjectionModeManager';

/**
 * 交互模式管理器
 */
export class InteractiveModeManager extends ModeManager<AbsInteractiveStrategy> implements IInteractiveMode {
  private mIsResumed: boolean = false;

  // private static sModes: number[] = [
  //   MDVRLibrary.INTERACTIVE_MODE_MOTION,
  //   MDVRLibrary.INTERACTIVE_MODE_TOUCH,
  //   MDVRLibrary.INTERACTIVE_MODE_MOTION_WITH_TOUCH,
  //   MDVRLibrary.INTERACTIVE_MODE_CARDBORAD_MOTION,
  // ];
  private static sModes: number[] = [1, 2, 3, 4, 5]; // 占位符

  private mParams: InteractiveModeManagerParams;
  private updateDragRunnable: UpdateDragRunnable;
  // 预创建的任务引用，避免每次 handleDrag 创建新闭包导致无法去重
  private dragTaskRef: (() => void) | null;

  constructor(mode: number, handler: MDGLHandler, params: InteractiveModeManagerParams) {
    super(mode, handler);
    this.mParams = params;
    this.mParams.glHandler = this.getGLHandler();
    this.updateDragRunnable = new UpdateDragRunnable(this);
    this.dragTaskRef = () => this.updateDragRunnable.run();
  }

  protected getModes(): number[] {
    return InteractiveModeManager.sModes;
  }

  protected createStrategy(mode: number): AbsInteractiveStrategy {
    // switch (mode) {
    //   case MDVRLibrary.INTERACTIVE_MODE_MOTION:
    //     return new MotionStrategy(this.mParams);
    //   case MDVRLibrary.INTERACTIVE_MODE_MOTION_WITH_TOUCH:
    //     return new MotionWithTouchStrategy(this.mParams);
    //   case MDVRLibrary.INTERACTIVE_MODE_CARDBORAD_MOTION:
    //     return new CardboardMotionStrategy(this.mParams);
    //   case MDVRLibrary.INTERACTIVE_MODE_CARDBORAD_MOTION_WITH_TOUCH:
    //     return new CardboardMTStrategy(this.mParams);
    //   case MDVRLibrary.INTERACTIVE_MODE_TOUCH:
    //   default:
    //     return new TouchStrategy(this.mParams);
    // }
    // 占位实现
    if (mode === 1) {
      return new MotionStrategy(this.mParams);
    } else if (mode === 2) {
      return new TouchStrategy(this.mParams);
    } else if (mode === 3) {
      return new MotionWithTouchStrategy(this.mParams);
    } else if (mode === 4) {
      return new CardboardMotionStrategy(this.mParams);
    } else if (mode === 5) {
      return new CardboardMTStrategy(this.mParams);
    } else {
      return new TouchStrategy(this.mParams);
    }
  }

  onOrientationChanged(context: Context): void {
    this.getGLHandler().post(() => {
      this.getStrategy()?.onOrientationChanged(context);
    });
  }

  onResume(context: Context): void {
    this.mIsResumed = true;
    if (this.getStrategy()?.isSupport(context)) {
      this.getStrategy()?.onResume(context);
    }
  }

  override on(context: Context): void {
    super.on(context);

    if (this.mIsResumed) {
      this.onResume(context);
    }
  }

  override off(context: Context): void {
    super.off(context);
    // 关闭时只重置状态，不创建新对象
    // UpdateDragRunnable 使用 WeakRef，会自动处理 manager 被回收的情况
    this.updateDragRunnable.handleDrag(0, 0);  // 重置拖拽数据
  }

  onPause(context: Context): void {
    this.mIsResumed = false;
    if (this.getStrategy()?.isSupport(context)) {
      this.getStrategy()?.onPause(context);
    }
  }

  handleDrag(distanceX: number, distanceY: number): boolean {
    this.updateDragRunnable.handleDrag(distanceX, distanceY);
    // 使用预创建的引用，GLHandler 可以去重
    if (this.dragTaskRef) {
      this.getGLHandler().post(this.dragTaskRef);
    }
    return false;
  }

  // 供内部 UpdateDragRunnable 使用的公开访问器，避免直接访问受保护的 getStrategy
  public getCurrentStrategy(): AbsInteractiveStrategy | null {
    return this.getStrategy();
  }

  /**
   * 销毁方法，清理所有引用防止内存泄漏
   */
  override destroy(): void {
    super.destroy();
    this.updateDragRunnable.destroy();
    this.dragTaskRef = null;  // 清理闭包引用
  }
}

/**
 * 更新拖拽任务类
 * 使用WeakRef避免循环引用导致的内存泄漏
 */
class UpdateDragRunnable {
  private distanceX: number = 0;
  private distanceY: number = 0;
  private managerRef: WeakRef<InteractiveModeManager> | null;

  constructor(manager: InteractiveModeManager) {
    // 使用WeakRef弱引用，避免循环引用
    this.managerRef = new WeakRef(manager);
  }

  handleDrag(distanceX: number, distanceY: number): void {
    this.distanceX = distanceX;
    this.distanceY = distanceY;
  }

  run(): void {
    const manager = this.managerRef?.deref();
    if (!manager) {
      return; // manager已被回收，直接返回
    }
    const strategy = manager.getCurrentStrategy();
    strategy?.handleDrag(this.distanceX, this.distanceY);
  }

  destroy(): void {
    this.managerRef = null;
  }
}

// 为了兼容性，导出Params作为类型别名
export type Params = InteractiveModeManagerParams;

