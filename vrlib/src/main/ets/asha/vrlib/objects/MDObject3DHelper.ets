/**
 * Created by hzqiujiadi on 16/4/24.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDAbsObject3D } from './MDAbsObject3D';
import { Context } from '../../../google/android/apps/muzei/render/ViewTypes';

/**
 * 3D对象加载完成回调接口
 */
export interface LoadComplete {
  onComplete(object3D: MDAbsObject3D): void;
}

/**
 * 3D对象加载辅助类
 */
export class MDObject3DHelper {
  /**
   * 加载OBJ文件
   * @param context 上下文
   * @param object3D 3D对象
   * @param loadComplete 加载完成回调
   */
  static loadObj(context: Context, object3D: MDAbsObject3D, loadComplete: LoadComplete | null = null): void {
    // 在鸿蒙中，可以使用 TaskPool 或 Promise 来实现异步加载
    // 这里使用 Promise 模拟异步加载
    Promise.resolve().then(() => {
      object3D.executeLoad(context);
      if (loadComplete != null) {
        loadComplete.onComplete(object3D);
      }
    });
  }
}

