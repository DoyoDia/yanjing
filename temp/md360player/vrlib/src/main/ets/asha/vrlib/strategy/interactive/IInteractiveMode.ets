/**
 * Created by hzqiujiadi on 16/3/19.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { Context } from '../../../../google/android/apps/muzei/render/ViewTypes';

/**
 * 交互模式接口
 */
export interface IInteractiveMode {
  /**
   * 恢复
   * @param context 上下文
   */
  onResume(context: Context): void;

  /**
   * 暂停
   * @param context 上下文
   */
  onPause(context: Context): void;

  /**
   * 处理拖拽
   * @param distanceX X方向距离
   * @param distanceY Y方向距离
   * @returns 是否已处理
   */
  handleDrag(distanceX: number, distanceY: number): boolean;

  /**
   * 方向改变
   * @param context 上下文
   */
  onOrientationChanged(context: Context): void;
}

