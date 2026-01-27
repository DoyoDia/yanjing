/**
 * Created by hzqiujiadi on 16/6/10.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MotionStrategy } from './MotionStrategy';
import { InteractiveModeManagerParams } from './AbsInteractiveStrategy';
import { MD360Director } from '../../MD360Director';

/**
 * 运动+触摸交互策略类
 */
export class MotionWithTouchStrategy extends MotionStrategy {
  private static readonly sDamping: number = 0.2;

  // 在鸿蒙中，需要获取屏幕密度
  private static getDensity(): number {
    // 占位实现，实际应该从系统获取
    return 1.0;
  }

  constructor(params: InteractiveModeManagerParams) {
    super(params);
  }

  override handleDrag(distanceX: number, distanceY: number): boolean {
    const density = MotionWithTouchStrategy.getDensity();
    const scaledX = -distanceX / density * MotionWithTouchStrategy.sDamping;
    const scaledY = -distanceY / density * MotionWithTouchStrategy.sDamping;
    
    // 更新 TypeScript 层（普通模式使用）
    for (const director of this.getDirectorList()) {
      director.setDeltaX(director.getDeltaX() + scaledX);
      director.setDeltaY(director.getDeltaY() + scaledY);
    }
    
    // 同时传递到 C++ 层（VR 模式使用）
    const params = this.getParams();
    if (params?.napi && typeof params.napi.updateTouchDelta === 'function') {
      params.napi.updateTouchDelta(scaledX, scaledY);
    }
    
    return false;
  }
}

