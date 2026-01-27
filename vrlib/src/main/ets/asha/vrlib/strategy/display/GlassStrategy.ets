/**
 * Created by hzqiujiadi on 16/3/19.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { AbsDisplayStrategy } from './AbsDisplayStrategy';
import { Context } from '../../../../google/android/apps/muzei/render/ViewTypes';


/**
 * 眼镜显示策略类
 */
export class GlassStrategy extends AbsDisplayStrategy {
  constructor() {
    super();
  }

  turnOnInGL(context: Context): void {
    // 空实现
  }

  turnOffInGL(context: Context): void {
    // 空实现
  }

  isSupport(context: Context): boolean {
    return true;
  }

  getVisibleSize(): number {
    return 2;
  }
}

