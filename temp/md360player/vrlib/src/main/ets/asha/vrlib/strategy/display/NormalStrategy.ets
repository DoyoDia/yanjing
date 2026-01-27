/**
 * Created by hzqiujiadi on 16/3/19.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { AbsDisplayStrategy } from './AbsDisplayStrategy';
import { Context } from '../../../../google/android/apps/muzei/render/ViewTypes';

/**
 * 普通显示策略类
 */
export class NormalStrategy extends AbsDisplayStrategy {
  turnOnInGL(context: Context): void {
    // 空实现
  }

  turnOffInGL(context: Context): void {
    // 空实现
  }

  isSupport(context: Context): boolean {
    return true;
  }

  onResume(context: Context): void {
    // 空实现
  }

  onPause(context: Context): void {
    // 空实现
  }

  getVisibleSize(): number {
    return 1;
  }
}

