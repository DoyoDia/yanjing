/**
 * Created by hzqiujiadi on 16/3/19.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { AbsInteractiveStrategy, InteractiveModeManagerParams } from './AbsInteractiveStrategy';
import { MD360Director } from '../../MD360Director';
import { Context } from '../../../../google/android/apps/muzei/render/ViewTypes';

// type Context = any;

/**
 * 触摸交互策略类
 */
export class TouchStrategy extends AbsInteractiveStrategy {
  private static readonly sDamping: number = 0.2;
  private static readonly TAG: string = "TouchStrategy";

  // 在鸿蒙中，需要获取屏幕密度
  private static getDensity(): number {
    // 占位实现，实际应该从系统获取
    return 1.0;
  }

  constructor(params: InteractiveModeManagerParams) {
    super(params);
  }

  onResume(context: Context): void {
    // 空实现
  }

  onPause(context: Context): void {
    // 空实现
  }

  handleDrag(distanceX: number, distanceY: number): boolean {
    const density = TouchStrategy.getDensity();
    const scaledX = distanceX / density * TouchStrategy.sDamping;
    const scaledY = distanceY / density * TouchStrategy.sDamping;
    
    // 更新 TypeScript 层（普通模式使用）
    const directors = this.getDirectorList();
    for (const director of directors) {
      const oldDeltaX = director.getDeltaX();
      const oldDeltaY = director.getDeltaY();
      const newDeltaX = oldDeltaX - scaledX;
      const newDeltaY = oldDeltaY - scaledY;
      director.setDeltaX(newDeltaX);
      director.setDeltaY(newDeltaY);
    }
    
    // 同时传递到 C++ 层（VR 模式使用）
    const params = this.getParams();
    if (params?.napi && typeof params.napi.updateTouchDelta === 'function') {
      params.napi.updateTouchDelta(-scaledX, -scaledY);
    }
    
    return false;
  }

  onOrientationChanged(context: Context): void {
    // 空实现
  }

  turnOnInGL(context: Context): void {
    for (const director of this.getDirectorList()) {
      director.reset();
    }
  }

  turnOffInGL(context: Context): void {
    // 空实现
  }

  isSupport(context: Context): boolean {
    return true;
  }
}

