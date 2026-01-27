/**
 * Created by hzqiujiadi on 16/3/19.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { Context } from '../../../google/android/apps/muzei/render/ViewTypes';

/**
 * 模式策略接口
 */
export interface IModeStrategy {
  /**
   * 在GL线程中开启
   * @param context 上下文
   */
  turnOnInGL(context: Context): void;

  /**
   * 在GL线程中关闭
   * @param context 上下文
   */
  turnOffInGL(context: Context): void;

  /**
   * 是否支持
   * @param context 上下文
   */
  isSupport(context: Context): boolean;

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
}

