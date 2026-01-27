/**
 * Created by hzqiujiadi on 2017/5/13.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDAbsPlugin } from './MDAbsPlugin';
import { Context } from '../../../google/android/apps/muzei/render/ViewTypes';
import { MD360Director } from '../MD360Director';

/**
 * 插件适配器类
 * 提供默认的空实现
 */
export class MDPluginAdapter extends MDAbsPlugin {
  protected initInGL(context: Context): void {
    // 空实现
  }

  destroyInGL(): void {
    // 空实现
  }

  beforeRenderer(totalWidth: number, totalHeight: number): void {
    // 空实现
  }

  renderer(index: number, itemWidth: number, itemHeight: number, director: MD360Director): void {
    // 空实现
  }

  removable(): boolean {
    return false;
  }
}

