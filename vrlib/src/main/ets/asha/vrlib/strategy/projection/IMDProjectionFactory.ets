/**
 * Created by hzqiujiadi on 16/8/20.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { AbsProjectionStrategy } from './AbsProjectionStrategy';

/**
 * 投影工厂接口
 */
export interface IMDProjectionFactory {
  /**
   * 创建投影策略
   * @param mode 模式
   */
  createStrategy(mode: number): AbsProjectionStrategy | null;
}

