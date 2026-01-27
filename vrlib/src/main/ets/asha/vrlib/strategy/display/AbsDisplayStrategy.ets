/**
 * Created by hzqiujiadi on 16/3/19.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { IModeStrategy } from '../IModeStrategy';
import { IDisplayMode } from './IDisplayMode';
import { Context } from '../../../../google/android/apps/muzei/render/ViewTypes';

/**
 * 抽象显示策略类
 */
export abstract class AbsDisplayStrategy implements IModeStrategy, IDisplayMode {
  onResume(context: Context): void {
    // 空实现，子类可重写
  }

  onPause(context: Context): void {
    // 空实现，子类可重写
  }

  abstract turnOnInGL(context: Context): void;
  abstract turnOffInGL(context: Context): void;
  abstract isSupport(context: Context): boolean;
  abstract getVisibleSize(): number;
}

