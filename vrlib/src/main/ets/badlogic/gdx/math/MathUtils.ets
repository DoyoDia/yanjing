/**
 * MathUtils 工具类
 * 提供数学计算相关的工具方法
 */

export class MathUtils {
  static readonly PI: number = Math.PI;
  static readonly PI2: number = Math.PI * 2;
  static readonly E: number = Math.E;
  static readonly radiansToDegrees: number = 180 / Math.PI;
  static readonly degreesToRadians: number = Math.PI / 180;

  /**
   * atan2 实现
   */
  static atan2(y: number, x: number): number {
    return Math.atan2(y, x);
  }

  /**
   * 限制值在指定范围内
   */
  static clamp(value: number, min: number, max: number): number {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  /**
   * 判断两个浮点数是否相等（考虑浮点误差）
   */
  static isEqual(a: number, b: number): boolean {
    return Math.abs(a - b) < 0.000001;
  }
}

