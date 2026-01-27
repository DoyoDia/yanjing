
import { MDFlingConfig } from './model/MDFlingConfig';
import { MDPinchConfig } from './model/MDPinchConfig';
import { Context } from '../../google/android/apps/muzei/render/ViewTypes';
import { MotionEvent } from './AndroidTypes';
import { IGestureListener } from './model/MDTypes';

// ArkTS destroy 可选接口声明
interface Destroyable {
  destroy?: () => void;
}

interface OnGestureListener {
  onSingleTapConfirmed(e: MotionEvent): boolean;
  onScroll(e1: MotionEvent, e2: MotionEvent, distanceX: number, distanceY: number): boolean;
  onFling(e1: MotionEvent, e2: MotionEvent, velocityX: number, velocityY: number): boolean;
}

class GestureDetector {
  constructor(context: Context, listener: OnGestureListener) {}
  onTouchEvent(event: MotionEvent): boolean { return false; }
}

export interface IAdvanceGestureListener {
  onDrag(distanceX: number, distanceY: number): void;
  onPinch(scale: number): void;
}

interface AnimatorUpdateListener {
  onAnimationUpdate(animation: ValueAnimator): void;
}

class ValueAnimator {
  static ofPropertyValuesHolder(hvx: PropertyValuesHolder, hvy: PropertyValuesHolder): ValueAnimator { return new ValueAnimator(); }
  setDuration(duration: number): ValueAnimator { return this; }
  setInterpolator(interpolator: TimeInterpolator): void {}
  addUpdateListener(listener: AnimatorUpdateListener): void {}
  start(): void {}
  cancel(): void {}
  getCurrentPlayTime(): number { return 0; }
  getAnimatedValue(propertyName: string): number { return 0; }
}

class PropertyValuesHolder {
  static ofFloat(propertyName: string, ...values: number[]): PropertyValuesHolder { return new PropertyValuesHolder(); }
}

class TimeInterpolator {}

/**
 * 触摸辅助类
 */
export class MDTouchHelper {
  private mAdvanceGestureListener: IAdvanceGestureListener | null = null;
  private mClickListeners: IGestureListener[] = [];
  private mGestureDetector: GestureDetector | null = null;
  private mCurrentMode: number = 0;
  private mPinchInfo: PinchInfo = new PinchInfo();
  private mPinchEnabled: boolean = false;
  private minScale: number = 0;
  private maxScale: number = 0;
  private mSensitivity: number = 0;
  private defaultScale: number = 0;
  private mGlobalScale: number = 1.0;
  private valueAnimator: ValueAnimator | null = null;

  private mFlingEnabled: boolean = false;
  private mFlingConfig: MDFlingConfig | null = null;

  private static readonly MODE_INIT: number = 0;
  private static readonly MODE_PINCH: number = 1;
  private mTouchSensitivity: number = 1.0;

  constructor(context: Context) {
    // mGestureDetector = new GestureDetector(context, new GestureDetector.SimpleOnGestureListener() {
    //   public boolean onSingleTapConfirmed(MotionEvent e) {
    //     if (mCurrentMode == MODE_PINCH) return false;
    //     for (IGestureListener listener : mClickListeners) {
    //       listener.onClick(e);
    //     }
    //     return true;
    //   }
    //   @Override
    //   public boolean onScroll(MotionEvent e1, MotionEvent e2, float distanceX, float distanceY) {
    //     if (mCurrentMode == MODE_PINCH) return false;
    //     if (mAdvanceGestureListener != null) {
    //       mAdvanceGestureListener.onDrag(scaled(distanceX), scaled(distanceY));
    //     }
    //     return true;
    //   }
    //   @Override
    //   public boolean onFling(MotionEvent e1, MotionEvent e2, float velocityX, float velocityY) {
    //     if (mCurrentMode == MODE_PINCH) return false;
    //     if (!mFlingEnabled) return false;
    //     animStart(velocityX, velocityY);
    //     return true;
    //   }
    // });
    // 在鸿蒙中，需要使用对应的手势识别API
    this.mGestureDetector = null; // 占位
  }

  private scaled(input: number): number {
    return input / this.mGlobalScale * this.mTouchSensitivity;
  }

  private animCancel(): void {
    if (this.valueAnimator != null) {
      // valueAnimator.cancel();
      // 在鸿蒙中，需要使用对应的动画API
      this.valueAnimator = null;
    }
  }

  private animStart(velocityX: number, velocityY: number): void {
    this.animCancel();

    // PropertyValuesHolder hvx = PropertyValuesHolder.ofFloat("vx", velocityX, 0);
    // PropertyValuesHolder hvy = PropertyValuesHolder.ofFloat("vy", velocityY, 0);
    // valueAnimator = ValueAnimator.ofPropertyValuesHolder(hvx, hvy).setDuration(mFlingConfig.getDuring());
    // valueAnimator.setInterpolator(mFlingConfig.getInterpolator());
    // valueAnimator.addUpdateListener(new ValueAnimator.AnimatorUpdateListener() {
    //   private long lastTime = 0;
    //   @Override
    //   public void onAnimationUpdate(ValueAnimator animation) {
    //     long now = animation.getCurrentPlayTime();
    //     long dur = (now - lastTime);
    //     float sx = (float) animation.getAnimatedValue("vx") * dur / -1000 * mFlingConfig.getSensitivity();
    //     float sy = (float) animation.getAnimatedValue("vy") * dur / -1000 * mFlingConfig.getSensitivity();
    //     lastTime = now;
    //     if (mAdvanceGestureListener != null) {
    //       mAdvanceGestureListener.onDrag(scaled(sx), scaled(sy));
    //     }
    //   }
    // });
    // valueAnimator.start();
    // 在鸿蒙中，需要使用对应的动画API
  }

  handleTouchEvent(event: MotionEvent): boolean {
    // const action = event.getAction() & MotionEvent.ACTION_MASK;
    // 在鸿蒙中，需要使用对应的事件API
    const action = 0; // 占位

    // if (action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_CANCEL) {
    //   if (this.mCurrentMode == MDTouchHelper.MODE_PINCH) {
    //     // end anim
    //   }
    //   this.mCurrentMode = MDTouchHelper.MODE_INIT;
    // } else if (action == MotionEvent.ACTION_POINTER_UP) {
    //   // one point up
    //   if (this.mCurrentMode == MDTouchHelper.MODE_PINCH) {
    //     // more than 2 pointer
    //     if (event.getPointerCount() > 2) {
    //       if ((event.getAction() >> 8) == 0) {
    //         // 0 up
    //         this.markPinchInfo(event.getX(1), event.getY(1), event.getX(2), event.getY(2));
    //       } else if ((event.getAction() >> 8) == 1) {
    //         // 1 up
    //         this.markPinchInfo(event.getX(0), event.getY(0), event.getX(2), event.getY(2));
    //       }
    //     }
    //   }
    // } else if (action == MotionEvent.ACTION_POINTER_DOWN) {
    //   // >= 2 pointer
    //   this.mCurrentMode = MDTouchHelper.MODE_PINCH;
    //   this.markPinchInfo(event.getX(0), event.getY(0), event.getX(1), event.getY(1));
    // } else if (action == MotionEvent.ACTION_MOVE) {
    //   // >= 2 pointer
    //   if (this.mCurrentMode == MDTouchHelper.MODE_PINCH && event.getPointerCount() > 1) {
    //     const distance = this.calDistance(event.getX(0), event.getY(0), event.getX(1), event.getY(1));
    //     this.handlePinch(distance);
    //   }
    // } else if (action == MotionEvent.ACTION_DOWN) {
    //   this.animCancel();
    // }
    // 在鸿蒙中，需要使用对应的事件处理API

    // mGestureDetector.onTouchEvent(event);
    return true;
  }

  scaleTo(scale: number): void {
    this.setScaleInner(this.mPinchInfo.setScale(scale));
  }

  reset(): void {
    this.setScaleInner(this.mPinchInfo.reset());
  }

  private handlePinch(distance: number): void {
    if (this.mPinchEnabled) {
      this.setScaleInner(this.mPinchInfo.pinch(distance));
    }
  }

  private setScaleInner(scale: number): void {
    if (this.mAdvanceGestureListener != null) {
      this.mAdvanceGestureListener.onPinch(scale);
    }
    this.mGlobalScale = scale;
  }

  private markPinchInfo(x1: number, y1: number, x2: number, y2: number): void {
    this.mPinchInfo.mark(x1, y1, x2, y2);
  }

  public static calDistance(x1: number, y1: number, x2: number, y2: number): number {
    return Math.sqrt(Math.pow(x1 - x2, 2) + Math.pow(y1 - y2, 2));
  }

  addClickListener(gestureListener: IGestureListener): void {
    if (gestureListener != null) {
      this.mClickListeners.push(gestureListener);
    }
  }

  setAdvanceGestureListener(listener: IAdvanceGestureListener | null): void {
    this.mAdvanceGestureListener = listener;
  }

  isPinchEnabled(): boolean {
    return this.mPinchEnabled;
  }

  setPinchEnabled(mPinchEnabled: boolean): void {
    this.mPinchEnabled = mPinchEnabled;
  }

  setPinchConfig(pinchConfig: MDPinchConfig): void {
    this.minScale = pinchConfig.getMin();
    this.maxScale = pinchConfig.getMax();
    this.mSensitivity = pinchConfig.getSensitivity();
    this.defaultScale = pinchConfig.getDefaultValue();
    this.defaultScale = Math.max(this.minScale, this.defaultScale);
    this.defaultScale = Math.min(this.maxScale, this.defaultScale);
    this.setScaleInner(this.defaultScale);
  }

  isFlingEnabled(): boolean {
    return this.mFlingEnabled;
  }

  setFlingEnabled(flingEnabled: boolean): void {
    this.mFlingEnabled = flingEnabled;
  }

  setFlingConfig(flingConfig: MDFlingConfig): void {
    this.mFlingConfig = flingConfig;
  }

  setTouchSensitivity(touchSensitivity: number): void {
    this.mTouchSensitivity = touchSensitivity;
  }

  /**
   * 销毁方法，清理所有引用防止内存泄漏
   */
  destroy(): void {
    this.animCancel();
    // 清理listener引用
    if (this.mAdvanceGestureListener != null) {
      // ArkTS: 使用 Destroyable 接口类型断言
      (this.mAdvanceGestureListener as Destroyable)?.destroy?.();
      this.mAdvanceGestureListener = null;
    }
    // 清理click listeners
    this.mClickListeners = [];
    this.mGestureDetector = null;
    this.mFlingConfig = null;
  }
}

/**
 * 捏合信息类
 */
class PinchInfo {
  private x1: number = 0;
  private y1: number = 0;
  private x2: number = 0;
  private y2: number = 0;
  private oDistance: number = 0;
  private prevScale: number = 0;
  private currentScale: number = 0;
  private minScale: number = 0;
  private maxScale: number = 0;
  private mSensitivity: number = 0;
  private defaultScale: number = 0;

  mark(x1: number, y1: number, x2: number, y2: number): void {
    this.x1 = x1;
    this.y1 = y1;
    this.x2 = x2;
    this.y2 = y2;
    this.oDistance = MDTouchHelper.calDistance(x1, y1, x2, y2);
    this.prevScale = this.currentScale;
  }

  pinch(distance: number): number {
    if (this.oDistance === 0) {
      this.oDistance = distance;
    }
    let scale = distance / this.oDistance - 1;
    scale *= this.mSensitivity * 3;
    this.currentScale = this.prevScale + scale;
    // range
    this.currentScale = Math.max(this.currentScale, this.minScale);
    this.currentScale = Math.min(this.currentScale, this.maxScale);
    return this.currentScale;
  }

  setScale(scale: number): number {
    this.prevScale = scale;
    this.currentScale = scale;
    return this.currentScale;
  }

  reset(): number {
    return this.setScale(this.defaultScale);
  }

  setMinScale(minScale: number): void {
    this.minScale = minScale;
  }

  setMaxScale(maxScale: number): void {
    this.maxScale = maxScale;
  }

  setSensitivity(sensitivity: number): void {
    this.mSensitivity = sensitivity;
  }

  setDefaultScale(defaultScale: number): void {
    this.defaultScale = defaultScale;
  }
}

