/**
 * Created by hzqiujiadi on 16/8/3.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { GLUtil } from '../common/GLUtil';

/**
 * 位置抽象类
 */
export abstract class MDPosition {
  // 延迟创建 MDOriginalPosition，避免“在声明前使用”问题
  private static sOriginalPosition: MDPosition | null = null;

  static getOriginalPosition(): MDPosition {
    if (MDPosition.sOriginalPosition == null) {
      MDPosition.sOriginalPosition = new MDOriginalPosition();
    }
    return MDPosition.sOriginalPosition;
  }

  /**
   * 获取变换矩阵
   */
  abstract getMatrix(): number[];

  /**
   * 设置旋转矩阵
   * @param rotation 旋转矩阵
   */
  abstract setRotationMatrix(rotation: number[]): void;
}

/**
 * 原始位置实现（不可修改）
 */
class MDOriginalPosition extends MDPosition {
  override getMatrix(): number[] {
    return GLUtil.identityMatrix();
  }

  override setRotationMatrix(rotation: number[]): void {
    console.error("call setRotationMatrix to MDOriginalPosition");
  }
}

