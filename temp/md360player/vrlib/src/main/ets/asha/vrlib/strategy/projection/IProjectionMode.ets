/**
 * Created by hzqiujiadi on 16/6/25.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDPosition } from '../../model/MDPosition';
import { MDAbsObject3D } from '../../objects/MDAbsObject3D';

/**
 * 投影模式接口
 */
export interface IProjectionMode {
  /**
   * 获取3D对象
   */
  getObject3D(): MDAbsObject3D | null;

  /**
   * 获取模型位置
   */
  getModelPosition(): MDPosition;
}

