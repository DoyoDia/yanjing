/**
 * Created by hzqiujiadi on 16/10/13.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { CardboardMotionStrategy } from './CardboardMotionStrategy';
import { InteractiveModeManagerParams } from './AbsInteractiveStrategy';
import { MD360Director } from '../../MD360Director';

/**
 * Cardboard运动+触摸交互策略类
 */
export class CardboardMTStrategy extends CardboardMotionStrategy {
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
    const density = CardboardMTStrategy.getDensity();
    const scaledX = -distanceX / density * CardboardMTStrategy.sDamping;
    const scaledY = -distanceY / density * CardboardMTStrategy.sDamping;
    
    // 更新 TypeScript 层（普通模式使用）
    const directors = this.getDirectorList();
    for (const director of directors) {
      const oldDeltaX = director.getDeltaX();
      const oldDeltaY = director.getDeltaY();
      director.setDeltaX(oldDeltaX + scaledX);
      director.setDeltaY(oldDeltaY + scaledY);
    }
    
    // 同时传递到 C++ 层（VR 模式使用）
    const params = this.getParams();
    if (params?.napi && typeof params.napi.updateTouchDelta === 'function') {
      params.napi.updateTouchDelta(scaledX, scaledY);
    }
    
    return false;
  }
}

